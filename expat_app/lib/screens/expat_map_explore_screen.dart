import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:expat_app/services/explore_session_storage.dart';
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
    this.exploreLocationSeed,
    this.onExploreLocationSeedConsumed,
    this.onExploreFullscreenModeChanged,
  });

  final ExpatMapTabMode mode;

  /// Listing / estate address to pre-fill **To** and route (Estates "Get a Ride").
  final String? ridesDestinationSeed;

  /// Called after the seed is read so the parent can clear it (avoids re-applying on rebuild).
  final VoidCallback? onRidesDestinationSeedConsumed;

  /// Listing / estate address to pre-fill Explore search and load nearby places.
  final String? exploreLocationSeed;

  /// Called after [exploreLocationSeed] is applied (parent should clear it).
  final VoidCallback? onExploreLocationSeedConsumed;

  /// When [true], Explore is showing the full-screen place list (parent may hide app chrome).
  final ValueChanged<bool>? onExploreFullscreenModeChanged;

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
  /// Place-type pill on Explore cards (matches estate “Explore Area” accent).
  static const categoryBadgeYellow = Color(0xFFFFD54F);
}

/// Tab label + Nearby Search [type] values (one type per request, merged per tab).
const List<(String, List<String>)> _kExploreCategoryConfig = [
  ('Food', ['restaurant', 'cafe', 'meal_takeaway']),
  ('Health', ['hospital', 'pharmacy', 'doctor']),
  ('Fitness', ['gym']),
  ('Shopping', ['supermarket', 'shopping_mall']),
];

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

  // --- Explore: nearby places list + session ---
  GoogleGeocodingService? _exploreGeocoding;
  bool _consumingExploreSeed = false;
  bool _exploreResultsMode = false;
  String _exploreAnchorLabel = '';
  LatLng? _exploreAnchor;
  int _exploreCategoryIndex = 0;
  final Map<int, List<ExplorePlaceDetails>> _explorePlacesByCategory = {};
  bool _explorePlacesLoading = false;
  String? _exploreFetchError;

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
            'Add GOOGLE_MAPS_API_KEY to env/google_maps.properties (copy env/google_maps.example.properties).';
      } else {
        _places = GooglePlacesService(apiKey: key);
        if (_isRides) {
          _directions = GoogleDirectionsService(apiKey: key);
          _geocoding = GoogleGeocodingService(apiKey: key);
        } else {
          _exploreGeocoding = GoogleGeocodingService(apiKey: key);
        }
        _keyError = null;
      }
    });
    if (_isRides && key.isNotEmpty) {
      await _initRidesFromLocation();
      await _maybeConsumeDestinationSeed();
    } else if (!_isRides && key.isNotEmpty) {
      await _bootstrapExploreFromDiskOrSeed();
    }
  }

  @override
  void didUpdateWidget(covariant ExpatMapExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isRides) {
      final n = widget.ridesDestinationSeed?.trim();
      final o = oldWidget.ridesDestinationSeed?.trim();
      if (n != null &&
          n.isNotEmpty &&
          n != o &&
          _apiKey.isNotEmpty &&
          !_loadingKey) {
        _maybeConsumeDestinationSeed();
      }
    } else {
      final ex = widget.exploreLocationSeed?.trim();
      final exOld = oldWidget.exploreLocationSeed?.trim();
      if (ex != null &&
          ex.isNotEmpty &&
          ex != exOld &&
          _apiKey.isNotEmpty &&
          !_loadingKey) {
        unawaited(_maybeConsumeExploreLocationSeed());
      }
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

  Future<void> _bootstrapExploreFromDiskOrSeed() async {
    final seed = widget.exploreLocationSeed?.trim();
    if (seed != null && seed.isNotEmpty) {
      await _maybeConsumeExploreLocationSeed();
      return;
    }
    final fromDisk = await ExploreSessionStorage.instance.loadIfValid();
    if (!mounted || fromDisk == null) return;

    setState(() {
      _exploreSearchController.text = fromDisk.searchFieldText;
      _exploreAnchor = LatLng(fromDisk.anchorLat, fromDisk.anchorLng);
      _exploreAnchorLabel = fromDisk.anchorLabel;
      _exploreCategoryIndex = fromDisk.categoryIndex.clamp(
        0,
        _kExploreCategoryConfig.length - 1,
      );
      _explorePlacesByCategory.clear();
      for (final e in fromDisk.placesByCategoryIndex.entries) {
        _explorePlacesByCategory[e.key] = List<ExplorePlaceDetails>.from(
          e.value,
        );
      }
      _cameraTarget = _exploreAnchor!;
      _exploreResultsMode = true;
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('selected'),
            position: _exploreAnchor!,
            infoWindow: InfoWindow(
              title: 'Search area',
              snippet: fromDisk.searchFieldText,
            ),
          ),
        );
    });
    widget.onExploreFullscreenModeChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _exploreAnchor == null) return;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_exploreAnchor!, 14),
      );
    });
  }

  Future<void> _maybeConsumeExploreLocationSeed() async {
    final seed = widget.exploreLocationSeed?.trim();
    if (_isRides ||
        seed == null ||
        seed.isEmpty ||
        _consumingExploreSeed ||
        _exploreGeocoding == null) {
      return;
    }
    _consumingExploreSeed = true;
    widget.onExploreLocationSeedConsumed?.call();
    try {
      final hit = await _exploreGeocoding!.forwardGeocode(seed);
      if (!mounted) return;
      if (hit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not find that location for Explore. Try typing it in the search field.',
            ),
          ),
        );
        return;
      }
      _exploreSearchController.text =
          hit.formattedAddress.isNotEmpty ? hit.formattedAddress : seed;
      final label = _shortAnchorLabel(hit.formattedAddress);
      await _applyExploreAnchor(hit.latLng, label: label, openResults: true);
    } finally {
      if (mounted) {
        setState(() => _consumingExploreSeed = false);
      } else {
        _consumingExploreSeed = false;
      }
    }
  }

  String _shortAnchorLabel(String formatted) {
    const nearPrefix = 'Near ';
    final parts =
        formatted
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    if (parts.length >= 2) {
      return '$nearPrefix${parts.take(3).join(', ')}';
    }
    if (parts.isNotEmpty) return '$nearPrefix${parts.first}';
    return '${nearPrefix}searched area';
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthM = 6371000.0;
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthM * c;
  }

  Future<void> _applyExploreAnchor(
    LatLng ll, {
    required String label,
    required bool openResults,
  }) async {
    if (!mounted) return;
    setState(() {
      _exploreAnchor = ll;
      _exploreAnchorLabel = label;
      _cameraTarget = ll;
      _exploreFetchError = null;
      if (openResults) {
        _exploreResultsMode = true;
        _exploreCategoryIndex = 0;
        _explorePlacesByCategory.clear();
      }
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('selected'),
            position: ll,
            infoWindow: InfoWindow(
              title: 'Search area',
              snippet: _exploreSearchController.text,
            ),
          ),
        );
    });
    if (openResults) {
      widget.onExploreFullscreenModeChanged?.call(true);
    }
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(ll, 14));
    if (openResults && _places != null) {
      await _loadExploreCategory(0);
    }
  }

  Future<List<ExplorePlaceDetails>> _fetchExploreDetailsInChunks(
    GooglePlacesService places,
    List<String> placeIds,
  ) async {
    const chunk = 5;
    final out = <ExplorePlaceDetails>[];
    for (var i = 0; i < placeIds.length; i += chunk) {
      final end = math.min(i + chunk, placeIds.length);
      final slice = placeIds.sublist(i, end);
      final partial = await Future.wait(
        slice.map(places.explorePlaceDetails),
      );
      for (final d in partial) {
        if (d != null) out.add(d);
      }
    }
    return out;
  }

  Future<void> _loadExploreCategory(int index) async {
    final places = _places;
    final anchor = _exploreAnchor;
    if (places == null || anchor == null || !_exploreResultsMode) return;

    final safeIndex = index.clamp(0, _kExploreCategoryConfig.length - 1);
    final cached = _explorePlacesByCategory[safeIndex];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _exploreCategoryIndex = safeIndex;
        _exploreFetchError = null;
      });
      await _persistExploreSession();
      return;
    }

    setState(() {
      _exploreCategoryIndex = safeIndex;
      _explorePlacesLoading = true;
      _exploreFetchError = null;
    });

    try {
      final typeList = _kExploreCategoryConfig[safeIndex].$2;
      final merged = <String, NearbyPlaceSummary>{};
      for (final t in typeList) {
        final batch = await places.nearbySearch(
          lat: anchor.latitude,
          lng: anchor.longitude,
          radiusMeters: 2500,
          type: t,
        );
        for (final p in batch) {
          merged[p.placeId] = p;
        }
      }
      final sorted =
          merged.values.toList()
            ..sort((a, b) {
              final da = _distanceMeters(
                anchor.latitude,
                anchor.longitude,
                a.lat,
                a.lng,
              );
              final db = _distanceMeters(
                anchor.latitude,
                anchor.longitude,
                b.lat,
                b.lng,
              );
              return da.compareTo(db);
            });
      final top = sorted.take(15).toList();
      final details = await _fetchExploreDetailsInChunks(
        places,
        top.map((e) => e.placeId).toList(),
      );
      if (!mounted) return;
      setState(() {
        _explorePlacesByCategory[safeIndex] = details;
        _explorePlacesLoading = false;
      });
      await _persistExploreSession();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _explorePlacesLoading = false;
        _exploreFetchError =
            'Could not load places. Check connection and Places API settings.';
      });
    }
  }

  Future<void> _persistExploreSession() async {
    final anchor = _exploreAnchor;
    if (!_exploreResultsMode || anchor == null) return;
    await ExploreSessionStorage.instance.save(
      ExploreSessionSnapshot(
        savedAt: DateTime.now(),
        anchorLat: anchor.latitude,
        anchorLng: anchor.longitude,
        anchorLabel: _exploreAnchorLabel,
        searchFieldText: _exploreSearchController.text,
        categoryIndex: _exploreCategoryIndex,
        placesByCategoryIndex: Map<int, List<ExplorePlaceDetails>>.from(
          _explorePlacesByCategory,
        ),
      ),
    );
  }

  Future<void> _openPlaceInGoogle(ExplorePlaceDetails p) async {
    final raw = p.googleMapsUri?.trim();
    final uri =
        raw != null && raw.isNotEmpty
            ? Uri.parse(raw)
            : Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(p.name)}&query_place_id=${Uri.encodeComponent(p.placeId)}',
            );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  /// Back from place list → map/search; keeps search text, anchor, marker, session.
  void _popExploreResultsToMapView() {
    if (!_exploreResultsMode) return;
    setState(() {
      _exploreResultsMode = false;
    });
    widget.onExploreFullscreenModeChanged?.call(false);
    final anchor = _exploreAnchor;
    if (anchor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(anchor, 14),
        );
      });
    }
  }

  String _exploreTypeBadgeLabel(List<String> types) {
    if (types.isEmpty) return 'Place';
    const map = <String, String>{
      'restaurant': 'Restaurant',
      'cafe': 'Cafe',
      'meal_takeaway': 'Takeaway',
      'hospital': 'Hospital',
      'pharmacy': 'Pharmacy',
      'doctor': 'Clinic',
      'gym': 'Gym',
      'supermarket': 'Supermarket',
      'shopping_mall': 'Mall',
      'store': 'Store',
      'bakery': 'Bakery',
      'bar': 'Bar',
    };
    for (final t in types) {
      final m = map[t];
      if (m != null) return m;
    }
    return types.first.replaceAll('_', ' ');
  }

  String _exploreHoursLine(ExplorePlaceDetails p) {
    if (p.weekdayText.isNotEmpty) {
      return p.weekdayText.first;
    }
    if (p.openNow == true) return 'Open now';
    if (p.openNow == false) return 'Closed now';
    return 'Hours not listed';
  }

  String _exploreRatingLine(ExplorePlaceDetails p) {
    final r = p.rating;
    if (r == null) return 'No ratings yet';
    return '${r.toStringAsFixed(1)} Star rated';
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
    if (!_isRides && _exploreResultsMode) {
      widget.onExploreFullscreenModeChanged?.call(false);
    }
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

    final label = _shortAnchorLabel(
      details.formattedAddress.isNotEmpty
          ? details.formattedAddress
          : details.name,
    );
    await _applyExploreAnchor(latLng, label: label, openResults: true);
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
        'Confirm Directions + Geocoding + Places on the key, billing, and rebuild after changing env/google_maps.properties.';
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

  /// Rides fare panel: green card, dark blue copy (distance, time, price).
  Widget _buildRidesFareResultCard(TextTheme textTheme) {
    const ink = _ExpatMapColors.primaryDark;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: _ExpatMapColors.accentGreen,
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
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ridesFareDistanceLine!,
                    style: textTheme.bodySmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Price (RWF)',
                    style: textTheme.labelSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ridesFarePriceLine!,
                    style: textTheme.titleLarge?.copyWith(
                      color: ink,
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
                color: ink,
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
    if (_exploreResultsMode) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _popExploreResultsToMapView();
        },
        child: _buildExploreResultsLayout(context, textTheme),
      );
    }
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
                                      unawaited(
                                        ExploreSessionStorage.instance.clear(),
                                      );
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

  Widget _buildExploreResultsLayout(BuildContext context, TextTheme textTheme) {
    final places =
        _explorePlacesByCategory[_exploreCategoryIndex] ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _ExpatMapColors.primaryDark,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 16, bottom: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _popExploreResultsToMapView,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _exploreAnchorLabel.isNotEmpty
                          ? _exploreAnchorLabel
                          : 'Nearby places',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Row(
            children: List.generate(_kExploreCategoryConfig.length, (i) {
              final label = _kExploreCategoryConfig[i].$1;
              final sel = i == _exploreCategoryIndex;
              return Expanded(
                child: InkWell(
                  onTap:
                      _explorePlacesLoading
                          ? null
                          : () => unawaited(_loadExploreCategory(i)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color:
                                sel
                                    ? _ExpatMapColors.primaryDark
                                    : _ExpatMapColors.hint,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        height: 3,
                        color:
                            sel
                                ? _ExpatMapColors.primaryDark
                                : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        Expanded(
          child:
              _explorePlacesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _exploreFetchError != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _exploreFetchError!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _ExpatMapColors.hint,
                        ),
                      ),
                    ),
                  )
                  : places.isEmpty
                  ? Center(
                    child: Text(
                      'No places found in this category nearby.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: _ExpatMapColors.hint,
                      ),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: places.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                          height: 24,
                          thickness: 1,
                          color: Color(0xFFE0E0E0),
                        ),
                    itemBuilder: (context, index) {
                      return _buildExplorePlaceCard(
                        context,
                        textTheme,
                        places[index],
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildExplorePlaceCard(
    BuildContext context,
    TextTheme textTheme,
    ExplorePlaceDetails place,
  ) {
    final placesSvc = _places;
    final photoUrls =
        placesSvc == null
            ? const <String>[]
            : place.photoReferences
                .map((r) => placesSvc.placePhotoUrl(r, maxWidth: 640))
                .where((u) => u.isNotEmpty)
                .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photoUrls.isNotEmpty)
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrls[i],
                    width: 140,
                    height: 108,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          width: 140,
                          height: 108,
                          color: const Color(0xFFE8E8E8),
                          child: const Icon(Icons.image_not_supported),
                        ),
                  ),
                );
              },
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 100,
              color: const Color(0xFFE8E8E8),
              alignment: Alignment.center,
              child: Icon(
                Icons.store_mall_directory_outlined,
                size: 40,
                color: _ExpatMapColors.hint,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                place.name,
                style: textTheme.titleMedium?.copyWith(
                  color: _ExpatMapColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _ExpatMapColors.categoryBadgeYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _exploreTypeBadgeLabel(place.types),
                style: textTheme.labelSmall?.copyWith(
                  color: _ExpatMapColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          place.formattedAddress.isNotEmpty
              ? place.formattedAddress
              : '${place.lat}, ${place.lng}',
          style: textTheme.bodySmall?.copyWith(
            color: _ExpatMapColors.primaryDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _exploreRatingLine(place),
          style: textTheme.bodySmall?.copyWith(
            color: _ExpatMapColors.primaryDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _exploreHoursLine(place),
          style: textTheme.bodySmall?.copyWith(
            color: _ExpatMapColors.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => unawaited(_openPlaceInGoogle(place)),
            style: FilledButton.styleFrom(
              backgroundColor: _ExpatMapColors.accentGreen,
              foregroundColor: _ExpatMapColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Continue in Google',
              style: textTheme.titleMedium?.copyWith(
                color: _ExpatMapColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
