import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:expat_app/services/google_places_service.dart';

const _prefsKey = 'expat_explore_session_v1';

/// How long restored Explore results stay valid after the user leaves the app.
const Duration kExploreSessionTtl = Duration(hours: 24);

class ExploreSessionStorage {
  ExploreSessionStorage._();
  static final ExploreSessionStorage instance = ExploreSessionStorage._();

  Future<void> save(ExploreSessionSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(snapshot.toJson()));
  }

  Future<ExploreSessionSnapshot?> loadIfValid() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final snap = ExploreSessionSnapshot.fromJson(map);
      if (DateTime.now().difference(snap.savedAt) > kExploreSessionTtl) {
        await clear();
        return null;
      }
      return snap;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

class ExploreSessionSnapshot {
  ExploreSessionSnapshot({
    required this.savedAt,
    required this.anchorLat,
    required this.anchorLng,
    required this.anchorLabel,
    required this.searchFieldText,
    required this.categoryIndex,
    required this.placesByCategoryIndex,
  });

  final DateTime savedAt;
  final double anchorLat;
  final double anchorLng;
  final String anchorLabel;
  final String searchFieldText;
  final int categoryIndex;
  final Map<int, List<ExplorePlaceDetails>> placesByCategoryIndex;

  Map<String, dynamic> toJson() {
    return {
      'savedAt': savedAt.toIso8601String(),
      'anchorLat': anchorLat,
      'anchorLng': anchorLng,
      'anchorLabel': anchorLabel,
      'searchFieldText': searchFieldText,
      'categoryIndex': categoryIndex,
      'places': placesByCategoryIndex.map(
        (k, v) => MapEntry(
          '$k',
          v.map(_placeToJson).toList(),
        ),
      ),
    };
  }

  static ExploreSessionSnapshot fromJson(Map<String, dynamic> json) {
    final placesRaw = json['places'] as Map<String, dynamic>? ?? {};
    final places = <int, List<ExplorePlaceDetails>>{};
    for (final e in placesRaw.entries) {
      final idx = int.tryParse(e.key);
      if (idx == null) continue;
      final list = e.value as List<dynamic>? ?? [];
      places[idx] =
          list
              .map((x) => _placeFromJson(x as Map<String, dynamic>))
              .toList();
    }
    return ExploreSessionSnapshot(
      savedAt: DateTime.parse(json['savedAt'] as String),
      anchorLat: (json['anchorLat'] as num).toDouble(),
      anchorLng: (json['anchorLng'] as num).toDouble(),
      anchorLabel: json['anchorLabel'] as String? ?? '',
      searchFieldText: json['searchFieldText'] as String? ?? '',
      categoryIndex: (json['categoryIndex'] as num?)?.toInt() ?? 0,
      placesByCategoryIndex: places,
    );
  }
}

Map<String, dynamic> _placeToJson(ExplorePlaceDetails p) {
  return {
    'placeId': p.placeId,
    'name': p.name,
    'formattedAddress': p.formattedAddress,
    'lat': p.lat,
    'lng': p.lng,
    'rating': p.rating,
    'userRatingsTotal': p.userRatingsTotal,
    'types': p.types,
    'openNow': p.openNow,
    'weekdayText': p.weekdayText,
    'photoReferences': p.photoReferences,
    'googleMapsUri': p.googleMapsUri,
  };
}

ExplorePlaceDetails _placeFromJson(Map<String, dynamic> m) {
  return ExplorePlaceDetails(
    placeId: m['placeId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    formattedAddress: m['formattedAddress'] as String? ?? '',
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    rating: (m['rating'] as num?)?.toDouble(),
    userRatingsTotal: (m['userRatingsTotal'] as num?)?.toInt(),
    types:
        (m['types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    openNow: m['openNow'] as bool?,
    weekdayText:
        (m['weekdayText'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    photoReferences:
        (m['photoReferences'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    googleMapsUri: m['googleMapsUri'] as String?,
  );
}
