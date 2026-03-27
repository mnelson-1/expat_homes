import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:expat_app/services/google_directions_service.dart';
import 'package:expat_app/services/google_geocoding_service.dart';
import 'package:expat_app/services/google_places_service.dart';
import 'package:expat_app/services/maps_api_key_channel.dart';
import 'package:expat_app/utils/rwanda_ride_fare_estimate.dart';

/// Rides: From/To panel + auto driving directions. Explore: map + place search only.
enum ExpatMapTabMode { rides, explore }

/// Parent must use a distinct [Key] per [mode] (e.g. `ValueKey('expat_map_rides')` vs
/// `ValueKey('expat_map_explore')`) so Flutter does not reuse one [State] when switching
/// tabs — otherwise Rides listeners/GPS init are skipped if Explore opened first.
class ExpatMapExploreScreen extends StatefulWidget {
  const ExpatMapExploreScreen({
    super.key,
    required this.mode,
    this.ridesDestinationSeed,
    this.onRidesDestinationSeedConsumed,
  });

  final ExpatMapTabMode mode;

  /// Listing / estate address to pre-fill **To** and route (Estates "Get a Ride").
  final String? ridesDestinationSeed;

  /// Called after the seed is read so the parent can clear it (avoids re-applying on rebuild).
  final VoidCallback? onRidesDestinationSeedConsumed;

  @override
  State<ExpatMapExploreScreen> createState() => _ExpatMapExploreScreenState();
}

class _ExpatMapColors {
  static const primaryDark = Color(0xFF1A2E35);
  static const accentGreen = Color(0xFF8ED966);
  static const hint = Color(0xFF9CA5A8);
  static const fieldBorder = Color(0xFF9CA5A8);
  /// Explore top band (off-white), per design — pills stay white inside.
  static const explorePanelBackground = Color(0xFFF2F3F5);
}

class _ExpatMapExploreScreenState extends State<ExpatMapExploreScreen> {
  GoogleMapController? _mapController;

  final TextEditingController _exploreSearchController = TextEditingController();
  final FocusNode _exploreSearchFocus = FocusNode();

  final TextEditingController _ridesFromController = TextEditingController();
  final FocusNode _ridesFromFocus = FocusNode();
  final TextEditingController _ridesToController = TextEditingController();
  final FocusNode _ridesToFocus = FocusNode();

  GooglePlacesService? _places;
  GoogleDirectionsService? _directions;
  GoogleGeocodingService? _geocoding;

  List<PlacePrediction> _predictions = [];
  /// When true, [_predictions] below the From field apply to From; else to To.
  bool _ridesPredictionsForFrom = false;
  Timer? _debounce;

  String _apiKey = '';
  bool _loadingKey = true;
  String? _keyError;

  LatLng _cameraTarget = const LatLng(-1.9441, 30.0619);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  /// Rides only: cached GPS when available.
  LatLng? _ridesOrigin;

  /// While true, From field shows loading hint and is read-only.
  bool _ridesFromInitializing = false;

  LatLng? _ridesDestination;
  bool _ridesRouteLoading = false;

  /// True while forward-geocoding [ridesDestinationSeed] so we don't stack duplicate work.
  bool _consumingDestinationSeed = false;

  /// Rides: inline fare panel after a successful route (replaces SnackBar).
  String? _ridesFareDistanceLine;
  String? _ridesFarePriceLine;

  /// Rides: inline error (no driving route, etc.).
  String? _ridesRouteError;

  bool get _isRides => widget.mode == ExpatMapTabMode.rides;

  @override
  void initState() {
    super.initState();
    _loadKey();
    if (_isRides) {
      _ridesFromController.addListener(_onRidesFromOrToChanged);
      _ridesToController.addListener(_onRidesFromOrToChanged);
    } else {
      _exploreSearchController.addListener(_onExploreSearchChanged);
      _exploreSearchFocus.addListener(() {
        if (!_exploreSearchFocus.hasFocus) {
          setState(() => _predictions = []);
        }
      });
    }
  }

  Future<void> _loadKey() async {
    final key = await MapsApiKeyChannel.resolvePlacesApiKey();
    if (!mounted) return;
    setState(() {
      _apiKey = key;
      _loadingKey = false;
      if (key.isEmpty) {
        _keyError =
            'Add GOOGLE_MAPS_API_KEY to android/local.properties (see docs/GOOGLE_MAPS_SETUP.md).';
      } else {
        _places = GooglePlacesService(apiKey: key);
        if (_isRides) {
          _directions = GoogleDirectionsService(apiKey: key);
          _geocoding = GoogleGeocodingService(apiKey: key);
        }
        _keyError = null;
      }
    });
    if (_isRides && key.isNotEmpty) {
      await _initRidesFromLocation();
      await _maybeConsumeDestinationSeed();
    }
  }

  @override
  void didUpdateWidget(covariant ExpatMapExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isRides) return;
    final n = widget.ridesDestinationSeed?.trim();
    final o = oldWidget.ridesDestinationSeed?.trim();
    if (n != null &&
        n.isNotEmpty &&
        n != o &&
        _apiKey.isNotEmpty &&
        !_loadingKey) {
      _maybeConsumeDestinationSeed();
    }
  }

  Future<void> _maybeConsumeDestinationSeed() async {
    final seed = widget.ridesDestinationSeed?.trim();
    if (!_isRides ||
        seed == null ||
        seed.isEmpty ||
        _consumingDestinationSeed ||
        _geocoding == null) {
      return;
    }
    _consumingDestinationSeed = true;
    widget.onRidesDestinationSeedConsumed?.call();
    try {
      final hit = await _geocoding!.forwardGeocode(seed);
      if (!mounted) return;
      if (hit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not find that property location on the map. Try typing the address in To.',
            ),
          ),
        );
        return;
      }
      final title =
          hit.formattedAddress.split(',').first.trim().isNotEmpty
              ? hit.formattedAddress.split(',').first.trim()
              : seed;
      _ridesToController.text = hit.formattedAddress;
      await _applyRidesDestination(
        hit.latLng,
        title: title,
        snippet: hit.formattedAddress,
      );
    } finally {
      if (mounted) {
        setState(() => _consumingDestinationSeed = false);
      } else {
        _consumingDestinationSeed = false;
      }
    }
  }

  void _dismissRidesResultPanels() {
    if (!_isRides) return;
    setState(() {
      _ridesFareDistanceLine = null;
      _ridesFarePriceLine = null;
      _ridesRouteError = null;
    });
  }

  void _applyRideRouteSuccess(DirectionsRoute route) {
    final meters = route.distanceMeters;
    final sec = route.durationSeconds;
    final km =
        meters != null && meters > 0
            ? formatRideDistanceKm(meters)
            : (route.distanceText ?? '—');
    final timeLine =
        sec != null && sec > 0
            ? formatRideDurationHms(sec)
            : (route.durationText ?? '—');
    final distPart =
        meters != null && meters > 0 ? '$km km' : (route.distanceText ?? '—');
    final est =
        meters != null && meters > 0
            ? estimateRwandaRideFareRwf(distanceMeters: meters)
            : null;
    setState(() {
      _ridesRouteError = null;
      _ridesFareDistanceLine = '$distPart • $timeLine';
      _ridesFarePriceLine =
          est != null ? '${formatRwfAmount(est)} RWF' : '— RWF';
    });
  }

  Future<void> _initRidesFromLocation() async {
    if (!_isRides || _geocoding == null) return;

    if (mounted) {
      setState(() => _ridesFromInitializing = true);
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _ridesFromInitializing = false;
            _ridesOrigin = null;
          });
        }
        return;
      }

      final on = await Geolocator.isLocationServiceEnabled();
      if (!on) {
        if (mounted) {
          setState(() {
            _ridesFromInitializing = false;
            _ridesOrigin = null;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('getCurrentPosition'),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _geocoding!.reverseGeocode(latLng);
      if (!mounted) return;

      final short =
          address != null && address.isNotEmpty
              ? address
              : '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';

      setState(() {
        _ridesOrigin = latLng;
        _ridesFromController.text = short;
        _ridesFromInitializing = false;
      });
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _ridesFromInitializing = false;
          _ridesOrigin = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ridesFromInitializing = false;
          _ridesOrigin = null;
        });
      }
    }
  }

  /// Text usable for forward geocode (empty if still loading placeholder).
  String _ridesToQueryForAutocomplete() {
    var q = _ridesToController.text.trim();
    q = q.replaceFirst(RegExp(r'^To:\s*', caseSensitive: false), '').trim();
    return q;
  }

  Future<LatLng?> _resolveOriginLatLngFromFromField() async {
    final geo = _geocoding;
    if (geo == null) return null;
    final q = _ridesFromController.text.trim();
    if (q.isEmpty) return null;
    final lower = q.toLowerCase();
    if (lower.contains('getting location')) return null;
    final hit = await geo.forwardGeocode(q);
    return hit?.latLng;
  }

  Future<void> _applyRidesDestination(
    LatLng latLng, {
    required String title,
    required String snippet,
  }) async {
    if (!_isRides) return;
    setState(() {
      _cameraTarget = latLng;
      _ridesDestination = latLng;
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('selected'),
            position: latLng,
            infoWindow: InfoWindow(
              title: title.isNotEmpty ? title : 'Destination',
              snippet: snippet,
            ),
          ),
        );
      _polylines.clear();
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 14),
    );

    if (mounted) await _ridesFetchAndDrawRoute(showErrors: true);
  }

  Future<void> _submitRidesToFromKeyboard() async {
    final geo = _geocoding;
    if (geo == null || !_isRides) return;
    final query = _ridesToQueryForAutocomplete();
    if (query.length < 2) return;

    setState(() => _predictions = []);
    FocusScope.of(context).unfocus();

    final hit = await geo.forwardGeocode(query);
    if (!mounted) return;
    if (hit == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No place found for that destination. Try another search.',
            ),
          ),
        );
      }
      return;
    }

    _ridesToController.text = hit.formattedAddress;
    final title =
        hit.formattedAddress.split(',').first.trim().isNotEmpty
            ? hit.formattedAddress.split(',').first.trim()
            : query;
    await _applyRidesDestination(
      hit.latLng,
      title: title,
      snippet: hit.formattedAddress,
    );
  }

  Future<void> _submitRidesFromFromKeyboard() async {
    final geo = _geocoding;
    if (geo == null || !_isRides) return;
    final q = _ridesFromController.text.trim();
    if (q.length < 2) return;
    setState(() => _predictions = []);
    FocusScope.of(context).unfocus();
    final hit = await geo.forwardGeocode(q);
    if (!mounted) return;
    if (hit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No place found for that start point. Try another search.'),
        ),
      );
      return;
    }
    setState(() {
      _ridesFromController.text = hit.formattedAddress;
      _ridesOrigin = hit.latLng;
      _ridesFromInitializing = false;
    });
    if (_ridesDestination != null) {
      await _ridesFetchAndDrawRoute(showErrors: true);
    }
  }

  void _onExploreSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runExploreAutocomplete);
  }

  void _onRidesFromOrToChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      _runRidesFieldAutocomplete,
    );
  }

  Future<void> _runExploreAutocomplete() async {
    final places = _places;
    final q = _exploreSearchController.text;
    if (places == null || q.trim().length < 2) {
      if (mounted) setState(() => _predictions = []);
      return;
    }
    final list = await places.autocomplete(input: q);
    if (!mounted) return;
    setState(() => _predictions = list);
  }

  Future<void> _runRidesFieldAutocomplete() async {
    if (!_isRides) return;
    final places = _places;
    if (places == null) return;

    final fromFocused = _ridesFromFocus.hasFocus;
    final toFocused = _ridesToFocus.hasFocus;

    late final String q;
    late final bool forFrom;
    if (fromFocused) {
      q = _ridesFromController.text.trim();
      forFrom = true;
    } else if (toFocused) {
      q = _ridesToQueryForAutocomplete();
      forFrom = false;
    } else {
      if (mounted) setState(() => _predictions = []);
      return;
    }

    if (q.length < 2) {
      if (mounted) setState(() => _predictions = []);
      return;
    }

    final list = await places.autocomplete(input: q);
    if (!mounted) return;
    setState(() {
      _predictions = list;
      _ridesPredictionsForFrom = forFrom;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.mode == ExpatMapTabMode.rides) {
      _ridesFromController.removeListener(_onRidesFromOrToChanged);
      _ridesToController.removeListener(_onRidesFromOrToChanged);
    } else {
      _exploreSearchController.removeListener(_onExploreSearchChanged);
    }
    _exploreSearchController.dispose();
    _exploreSearchFocus.dispose();
    _ridesFromController.dispose();
    _ridesFromFocus.dispose();
    _ridesToController.dispose();
    _ridesToFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onExploreSelectPrediction(PlacePrediction p) async {
    final places = _places;
    if (places == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _predictions = []);

    final details = await places.placeDetails(p.placeId);
    if (!mounted || details == null) return;

    final latLng = LatLng(details.lat, details.lng);
    _exploreSearchController.text = details.formattedAddress.isNotEmpty
        ? details.formattedAddress
        : details.name;

    setState(() {
      _cameraTarget = latLng;
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('selected'),
            position: latLng,
            infoWindow: InfoWindow(
              title: details.name.isNotEmpty ? details.name : 'Selected place',
              snippet: details.formattedAddress,
            ),
          ),
        );
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15),
    );
  }

  Future<void> _onRidesSelectFromPrediction(PlacePrediction p) async {
    final places = _places;
    if (places == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _predictions = []);

    final details = await places.placeDetails(p.placeId);
    if (!mounted || details == null) return;

    final latLng = LatLng(details.lat, details.lng);
    setState(() {
      _ridesFromController.text = details.formattedAddress.isNotEmpty
          ? details.formattedAddress
          : details.name;
      _ridesOrigin = latLng;
      _ridesFromInitializing = false;
    });

    if (_ridesDestination != null) {
      await _ridesFetchAndDrawRoute(showErrors: true);
    }
  }

  Future<void> _onRidesSelectPrediction(PlacePrediction p) async {
    final places = _places;
    if (places == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _predictions = []);

    final details = await places.placeDetails(p.placeId);
    if (!mounted || details == null) return;

    final latLng = LatLng(details.lat, details.lng);
    _ridesToController.text = details.formattedAddress.isNotEmpty
        ? details.formattedAddress
        : details.name;

    await _applyRidesDestination(
      latLng,
      title: details.name.isNotEmpty ? details.name : 'Destination',
      snippet: details.formattedAddress,
    );
  }

  Future<void> _ridesFetchAndDrawRoute({required bool showErrors}) async {
    final dest = _ridesDestination;
    final directions = _directions;
    final geocoding = _geocoding;
    if (dest == null || directions == null || !_isRides) return;

    if (mounted) {
      setState(() {
        _ridesRouteLoading = true;
        _ridesRouteError = null;
        _ridesFareDistanceLine = null;
        _ridesFarePriceLine = null;
      });
    }

    try {
      LatLng? origin;
      var originMarkerTitle = 'Start';

      final fromField = await _resolveOriginLatLngFromFromField();
      if (fromField != null) {
        origin = fromField;
        originMarkerTitle = 'Start';
      } else if (_ridesOrigin != null) {
        origin = _ridesOrigin;
        originMarkerTitle = 'Your location';
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _ridesRouteLoading = false);
            if (showErrors) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Enter a starting address in From, or allow location for directions from where you are.',
                  ),
                ),
              );
            }
          }
          return;
        }
        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() => _ridesRouteLoading = false);
            if (showErrors) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Enable location in Settings to get directions from your position, or type a start address in From.',
                  ),
                  action: SnackBarAction(
                    label: 'Settings',
                    onPressed: Geolocator.openAppSettings,
                  ),
                ),
              );
            }
          }
          return;
        }

        final serviceOn = await Geolocator.isLocationServiceEnabled();
        if (!serviceOn) {
          if (mounted) {
            setState(() => _ridesRouteLoading = false);
            if (showErrors) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Turn on device location, or type a starting address in From.',
                  ),
                  action: SnackBarAction(
                    label: 'Open',
                    onPressed: Geolocator.openLocationSettings,
                  ),
                ),
              );
            }
          }
          return;
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('getCurrentPosition'),
          );
          origin = LatLng(position.latitude, position.longitude);
          _ridesOrigin = origin;
          originMarkerTitle = 'Your location';
          if (geocoding != null) {
            final addr = await geocoding.reverseGeocode(origin);
            if (mounted && addr != null && addr.isNotEmpty) {
              _ridesFromController.text = addr;
            }
          }
        } on TimeoutException {
          if (mounted) {
            setState(() => _ridesRouteLoading = false);
            if (showErrors) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'GPS is slow or unavailable. Type a starting address in From.',
                  ),
                ),
              );
            }
          }
          return;
        }
      }

      if (origin == null) {
        if (mounted) {
          setState(() => _ridesRouteLoading = false);
          if (showErrors) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not determine a start point. Add an address in From.',
                ),
              ),
            );
          }
        }
        return;
      }

      final outcome = await directions.getDrivingRoute(
        origin: origin,
        destination: dest,
      );
      final route = outcome.route;

      if (!mounted) return;

      if (route == null || route.points.isEmpty) {
        if (mounted) {
          setState(() {
            _ridesRouteLoading = false;
            if (showErrors) {
              final detail = outcome.errorDetail ?? 'Unknown error';
              _ridesRouteError = _directionsFailureUserMessage(
                detail,
                origin: origin,
                destination: dest,
              );
            }
          });
        }
        return;
      }

      setState(() {
        _ridesRouteLoading = false;
        _markers.removeWhere((m) => m.markerId == const MarkerId('origin'));
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: origin!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(title: originMarkerTitle),
          ),
        );
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.points,
              color: _ExpatMapColors.accentGreen,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
      });

      await _fitBounds(route.points, origin, dest);

      if (mounted) {
        _applyRideRouteSuccess(route);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ridesRouteLoading = false;
          if (showErrors) {
            _ridesRouteError = 'Could not get directions: $e';
          }
        });
      }
    }
  }

  Future<void> _fitBounds(
    List<LatLng> routePoints,
    LatLng origin,
    LatLng dest,
  ) {
    double minLat = math.min(origin.latitude, dest.latitude);
    double maxLat = math.max(origin.latitude, dest.latitude);
    double minLng = math.min(origin.longitude, dest.longitude);
    double maxLng = math.max(origin.longitude, dest.longitude);
    for (final p in routePoints) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final sw = LatLng(minLat, minLng);
    final ne = LatLng(maxLat, maxLng);
    if (minLat == maxLat && minLng == maxLng) {
      return _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(origin, 14),
          ) ??
          Future.value();
    }
    return _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(southwest: sw, northeast: ne),
            80,
          ),
        ) ??
        Future.value();
  }

  static const double _kEmulatorDefaultLat = 37.42;
  static const double _kEmulatorDefaultLng = -122.08;

  /// True when start is near the common emulator default (Mountain View) and end is in central Africa / Indian Ocean region.
  bool _looksLikeEmulatorOverseasRoute(LatLng? origin, LatLng? destination) {
    if (origin == null || destination == null) return false;
    final nearEmu =
        (origin.latitude - _kEmulatorDefaultLat).abs() < 0.35 &&
        (origin.longitude - _kEmulatorDefaultLng).abs() < 0.35;
    final destLon = destination.longitude.abs();
    final destAfricanish =
        destination.latitude > -15 &&
        destination.latitude < 15 &&
        destLon < 55;
    return nearEmu && destAfricanish;
  }

  /// Maps Directions API errors to actionable copy (e.g. emulator GPS in US vs destination in Rwanda).
  String _directionsFailureUserMessage(
    String detail, {
    LatLng? origin,
    LatLng? destination,
  }) {
    final u = detail.toUpperCase();
    if (u.contains('ZERO_RESULTS') ||
        u.contains('NOT_FOUND') ||
        u.contains('MAX_ROUTE_LENGTH_EXCEEDED') ||
        u.contains('NO ROUTES')) {
      final farApart = _looksLikeEmulatorOverseasRoute(origin, destination);
      if (farApart) {
        return "No driving route: From looks like the emulator's default GPS in California, "
            'while To is far away (e.g. Rwanda). Use Extended controls → Location to set a '
            'point near your destination, or type a From address in the same city as To '
            '(e.g. Kigali).';
      }
      return 'No driving route between these points. Try From and To in the same region, '
          'or use full street addresses.';
    }
    if (u.contains('REQUEST_DENIED')) {
      return 'Directions were denied ($detail). '
          'Check API key restrictions, enable Directions API, and billing (see docs).';
    }
    return 'Could not load route: $detail. '
        'Confirm Directions API + Geocoding API on the key, billing, and rebuild after changing local.properties (see docs).';
  }

  /// Pill field used on Rides (From/To) and Explore (location search).
  InputDecoration _ridesPillDecoration({
    required String hint,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: _ExpatMapColors.fieldBorder),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _ExpatMapColors.hint,
        fontWeight: FontWeight.w400,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: _ExpatMapColors.primaryDark,
          width: 1.2,
        ),
      ),
      isDense: true,
    );
  }

  Widget _buildRidesFromField(TextTheme textTheme) {
    final loading = _ridesFromInitializing;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _ridesFromController,
      builder: (context, value, _) => TextField(
        controller: _ridesFromController,
        focusNode: _ridesFromFocus,
        readOnly: loading,
        maxLines: 1,
        textInputAction: TextInputAction.search,
        style: textTheme.bodyLarge?.copyWith(
          color: _ExpatMapColors.primaryDark,
        ),
        decoration: _ridesPillDecoration(
          hint:
              loading
                  ? 'From: Getting location…'
                  : 'From: Type your starting point…',
          suffix:
              value.text.isNotEmpty && !loading
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 22),
                    onPressed: () {
                      _ridesFromController.clear();
                      setState(() {
                        _ridesOrigin = null;
                        _markers.removeWhere(
                          (m) => m.markerId == const MarkerId('origin'),
                        );
                        _polylines.clear();
                        _ridesRouteError = null;
                        _ridesFareDistanceLine = null;
                        _ridesFarePriceLine = null;
                      });
                    },
                  )
                  : null,
        ),
        onSubmitted: (_) => _submitRidesFromFromKeyboard(),
      ),
    );
  }

  Widget _buildRidesPredictionsPanel(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _predictions.length,
            separatorBuilder:
                (_, __) => const Divider(height: 1, thickness: 0.5),
            itemBuilder: (context, i) {
              final p = _predictions[i];
              final title =
                  p.mainText?.isNotEmpty == true
                      ? p.mainText!
                      : p.description;
              final sub = p.secondaryText;
              return ListTile(
                dense: true,
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _ExpatMapColors.primaryDark,
                  ),
                ),
                subtitle:
                    sub != null && sub.isNotEmpty
                        ? Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: _ExpatMapColors.hint,
                          ),
                        )
                        : null,
                onTap:
                    () =>
                        _ridesPredictionsForFrom
                            ? _onRidesSelectFromPrediction(p)
                            : _onRidesSelectPrediction(p),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_loadingKey) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_apiKey.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _keyError ?? 'Maps API key is not configured.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: _ExpatMapColors.hint,
            ),
          ),
        ),
      );
    }

    if (_isRides) {
      return _buildRidesLayout(context, textTheme);
    }
    return _buildExploreLayout(context, textTheme);
  }

  Widget _buildRidesLayout(BuildContext context, TextTheme textTheme) {
    final panelMaxH = MediaQuery.sizeOf(context).height * 0.48;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          constraints: BoxConstraints(maxHeight: panelMaxH),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRidesFromField(textTheme),
                if (_predictions.isNotEmpty && _ridesPredictionsForFrom)
                  _buildRidesPredictionsPanel(textTheme),
                const SizedBox(height: 12),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _ridesToController,
                  builder:
                      (context, value, _) => TextField(
                        controller: _ridesToController,
                        focusNode: _ridesToFocus,
                        textInputAction: TextInputAction.search,
                        style: textTheme.bodyLarge?.copyWith(
                          color: _ExpatMapColors.primaryDark,
                        ),
                        decoration: _ridesPillDecoration(
                          hint: 'To: Type your destination...',
                          suffix:
                              value.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 22),
                                    onPressed: () {
                                      _ridesToController.clear();
                                      setState(() {
                                        _predictions = [];
                                        _ridesRouteError = null;
                                        _ridesFareDistanceLine = null;
                                        _ridesFarePriceLine = null;
                                        _ridesDestination = null;
                                        _polylines.clear();
                                        _markers.removeWhere(
                                          (m) =>
                                              m.markerId ==
                                              const MarkerId('selected'),
                                        );
                                        _markers.removeWhere(
                                          (m) =>
                                              m.markerId ==
                                              const MarkerId('origin'),
                                        );
                                      });
                                    },
                                  )
                                  : null,
                        ),
                        onSubmitted: (_) => _submitRidesToFromKeyboard(),
                      ),
                ),
                if (_predictions.isNotEmpty && !_ridesPredictionsForFrom)
                  _buildRidesPredictionsPanel(textTheme),
              ],
            ),
          ),
        ),
        Container(height: 2, color: _ExpatMapColors.accentGreen),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _cameraTarget,
                  zoom: 13,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) => _mapController = c,
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                  setState(() => _predictions = []);
                },
              ),
              if (_ridesRouteLoading)
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading route…'),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_ridesFareDistanceLine != null &&
                  _ridesFarePriceLine != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 40,
                  child: _buildRidesFareResultCard(textTheme),
                )
              else if (_ridesRouteError != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 40,
                  child: _buildRidesRouteErrorCard(textTheme),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Text(
                  'Powered by Google',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: _ExpatMapColors.primaryDark.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Light panel: distance + duration, then large RWF price (Estates / Rides success).
  Widget _buildRidesFareResultCard(TextTheme textTheme) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFFF2F3F5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Distance (km) · Time',
                    style: textTheme.labelSmall?.copyWith(
                      color: _ExpatMapColors.hint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ridesFareDistanceLine!,
                    style: textTheme.bodySmall?.copyWith(
                      color: _ExpatMapColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Price (RWF)',
                    style: textTheme.labelSmall?.copyWith(
                      color: _ExpatMapColors.hint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ridesFarePriceLine!,
                    style: textTheme.titleLarge?.copyWith(
                      color: _ExpatMapColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -10,
              right: -6,
              child: IconButton(
                icon: const Icon(Icons.close, size: 22),
                color: _ExpatMapColors.primaryDark,
                onPressed: _dismissRidesResultPanels,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesRouteErrorCard(TextTheme textTheme) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFFF2F3F5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Text(
                _ridesRouteError!,
                style: textTheme.bodySmall?.copyWith(
                  color: _ExpatMapColors.primaryDark,
                  height: 1.35,
                ),
              ),
            ),
            Positioned(
              top: -10,
              right: -6,
              child: IconButton(
                icon: const Icon(Icons.close, size: 22),
                color: _ExpatMapColors.primaryDark,
                onPressed: _dismissRidesResultPanels,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplorePredictionsPanel(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _predictions.length,
            separatorBuilder:
                (_, __) => const Divider(height: 1, thickness: 0.5),
            itemBuilder: (context, i) {
              final p = _predictions[i];
              final title =
                  p.mainText?.isNotEmpty == true
                      ? p.mainText!
                      : p.description;
              final sub = p.secondaryText;
              return ListTile(
                dense: true,
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _ExpatMapColors.primaryDark,
                  ),
                ),
                subtitle:
                    sub != null && sub.isNotEmpty
                        ? Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: _ExpatMapColors.hint,
                          ),
                        )
                        : null,
                onTap: () => _onExploreSelectPrediction(p),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExploreLayout(BuildContext context, TextTheme textTheme) {
    final panelMaxH = MediaQuery.sizeOf(context).height * 0.48;
    return Column(
      key: const ValueKey(ExpatMapTabMode.explore),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _ExpatMapColors.explorePanelBackground,
          constraints: BoxConstraints(maxHeight: panelMaxH),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _exploreSearchController,
                  builder:
                      (context, value, _) => TextField(
                        controller: _exploreSearchController,
                        focusNode: _exploreSearchFocus,
                        textInputAction: TextInputAction.search,
                        maxLines: 1,
                        style: textTheme.bodyLarge?.copyWith(
                          color: _ExpatMapColors.primaryDark,
                        ),
                        decoration: _ridesPillDecoration(
                          hint: 'Type your location...',
                          suffix:
                              value.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear, size: 22),
                                    onPressed: () {
                                      _exploreSearchController.clear();
                                      setState(() {
                                        _predictions = [];
                                        _markers.clear();
                                      });
                                    },
                                  )
                                  : null,
                        ),
                      ),
                ),
                if (_predictions.isNotEmpty)
                  _buildExplorePredictionsPanel(textTheme),
              ],
            ),
          ),
        ),
        Container(height: 2, color: _ExpatMapColors.accentGreen),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _cameraTarget,
                  zoom: 13,
                ),
                markers: _markers,
                polylines: const <Polyline>{},
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) => _mapController = c,
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                  setState(() => _predictions = []);
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Text(
                  'Powered by Google',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: _ExpatMapColors.primaryDark.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
