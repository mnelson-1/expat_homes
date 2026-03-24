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
  const ExpatMapExploreScreen({super.key, required this.mode});

  final ExpatMapTabMode mode;

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
    }
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

    setState(() => _ridesRouteLoading = true);

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
        setState(() => _ridesRouteLoading = false);
        if (showErrors) {
          final detail = outcome.errorDetail ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_directionsFailureUserMessage(detail)),
              duration: const Duration(seconds: 6),
            ),
          );
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

      if (mounted &&
          (route.durationText != null ||
              route.distanceText != null ||
              (route.distanceMeters != null && route.distanceMeters! > 0))) {
        final parts = <String>[
          if (route.distanceText != null) route.distanceText!,
          if (route.durationText != null) route.durationText!,
        ];
        final meters = route.distanceMeters;
        if (meters != null && meters > 0) {
          final est = estimateRwandaRideFareRwf(distanceMeters: meters);
          parts.add('~${formatRwfAmount(est)} RWF (est.)');
        }
        final summary = parts.join(' · ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ridesRouteLoading = false);
        if (showErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get directions: $e')),
          );
        }
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

  /// Maps Directions API errors to actionable copy (e.g. emulator GPS in US vs destination in Rwanda).
  String _directionsFailureUserMessage(String detail) {
    final u = detail.toUpperCase();
    if (u.contains('ZERO_RESULTS') ||
        u.contains('NOT_FOUND') ||
        u.contains('MAX_ROUTE_LENGTH_EXCEEDED')) {
      return 'No driving route between start and destination. '
          'The Android emulator often reports GPS in California (~37.42, -122.08). '
          'Use Extended controls → Location to set a point near your destination, '
          'or type a start address in From (e.g. Kigali).';
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
    return TextField(
      controller: _ridesFromController,
      focusNode: _ridesFromFocus,
      readOnly: loading,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      style: textTheme.bodyLarge?.copyWith(
        color: _ExpatMapColors.primaryDark,
      ),
      decoration: _ridesPillDecoration(
        hint: loading ? 'From: Getting location…' : 'From: Type your starting point…',
        suffix:
            _ridesFromController.text.isNotEmpty && !loading
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
                    });
                  },
                )
                : null,
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submitRidesFromFromKeyboard(),
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
                TextField(
                  controller: _ridesToController,
                  focusNode: _ridesToFocus,
                  textInputAction: TextInputAction.search,
                  style: textTheme.bodyLarge?.copyWith(
                    color: _ExpatMapColors.primaryDark,
                  ),
                  decoration: _ridesPillDecoration(
                    hint: 'To: Type your destination...',
                    suffix:
                        _ridesToController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, size: 22),
                              onPressed: () {
                                _ridesToController.clear();
                                setState(() {
                                  _predictions = [];
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
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submitRidesToFromKeyboard(),
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
                TextField(
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
                        _exploreSearchController.text.isNotEmpty
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
                  onChanged: (_) => setState(() {}),
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
