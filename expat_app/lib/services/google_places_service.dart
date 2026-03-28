import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lightweight Places wrapper (Autocomplete + Place Details) for map search.
class GooglePlacesService {
  GooglePlacesService({required this.apiKey});

  final String apiKey;

  static const _base = 'https://maps.googleapis.com/maps/api';

  Future<List<PlacePrediction>> autocomplete({
    required String input,
    String? sessionToken,
  }) async {
    if (apiKey.isEmpty || input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input.trim(),
      'key': apiKey,
      // Bias toward Rwanda / Kigali use-case (still returns global matches).
      'components': 'country:rw',
    };
    if (sessionToken != null && sessionToken.isNotEmpty) {
      params['sessiontoken'] = sessionToken;
    }

    final uri = Uri.parse('$_base/place/autocomplete/json').replace(
      queryParameters: params,
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];

    final map = jsonDecode(res.body) as Map<String, dynamic>?;
    if (map == null) return [];
    final status = map['status'] as String? ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') return [];

    final preds = map['predictions'] as List<dynamic>? ?? [];
    return preds
        .map((e) => e as Map<String, dynamic>)
        .map(
          (e) => PlacePrediction(
            placeId: e['place_id'] as String? ?? '',
            description: e['description'] as String? ?? '',
            mainText:
                (e['structured_formatting'] as Map<String, dynamic>?)?['main_text']
                    as String?,
            secondaryText:
                (e['structured_formatting'] as Map<String, dynamic>?)?['secondary_text']
                    as String?,
          ),
        )
        .where((p) => p.placeId.isNotEmpty)
        .toList();
  }

  /// Google Place Photo; use as [Image.network] URL (API key is in query).
  String placePhotoUrl(
    String photoReference, {
    int maxWidth = 800,
  }) {
    if (apiKey.isEmpty || photoReference.isEmpty) return '';
    return Uri.parse('$_base/place/photo').replace(
      queryParameters: {
        'maxwidth': '$maxWidth',
        'photo_reference': photoReference,
        'key': apiKey,
      },
    ).toString();
  }

  /// Nearby Search (one [type] per request). See [NearbyPlaceSummary].
  Future<List<NearbyPlaceSummary>> nearbySearch({
    required double lat,
    required double lng,
    int radiusMeters = 2000,
    required String type,
  }) async {
    if (apiKey.isEmpty) return [];

    final uri = Uri.parse('$_base/place/nearbysearch/json').replace(
      queryParameters: {
        'location': '$lat,$lng',
        'radius': '$radiusMeters',
        'type': type,
        'key': apiKey,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return [];

    final map = jsonDecode(res.body) as Map<String, dynamic>?;
    if (map == null) return [];
    final status = map['status'] as String? ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') return [];

    final results = map['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => e as Map<String, dynamic>)
        .map(_parseNearbyResult)
        .where((p) => p.placeId.isNotEmpty)
        .toList();
  }

  NearbyPlaceSummary _parseNearbyResult(Map<String, dynamic> result) {
    final placeId = result['place_id'] as String? ?? '';
    final name = result['name'] as String? ?? '';
    final vicinity = result['vicinity'] as String? ?? '';
    final geom = result['geometry'] as Map<String, dynamic>?;
    final loc = geom?['location'] as Map<String, dynamic>?;
    final lat = (loc?['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (loc?['lng'] as num?)?.toDouble() ?? 0.0;
    final rating = (result['rating'] as num?)?.toDouble();
    final types =
        (result['types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];

    bool? openNow;
    final oh = result['opening_hours'] as Map<String, dynamic>?;
    if (oh != null && oh.containsKey('open_now')) {
      openNow = oh['open_now'] as bool?;
    }

    String? photoRef;
    final photos = result['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      final first = photos.first as Map<String, dynamic>?;
      photoRef = first?['photo_reference'] as String?;
    }

    return NearbyPlaceSummary(
      placeId: placeId,
      name: name,
      vicinity: vicinity,
      lat: lat,
      lng: lng,
      rating: rating,
      types: types,
      openNow: openNow,
      photoReference: photoRef,
    );
  }

  /// Rich details for Explore cards (hours, multiple photos, formatted address).
  Future<ExplorePlaceDetails?> explorePlaceDetails(String placeId) async {
    if (apiKey.isEmpty || placeId.isEmpty) return null;

    final uri = Uri.parse('$_base/place/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'fields':
            'place_id,name,geometry,formatted_address,rating,user_ratings_total,opening_hours,photos,types,url',
        'key': apiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final map = jsonDecode(res.body) as Map<String, dynamic>?;
    if (map == null || (map['status'] as String?) != 'OK') return null;

    final result = map['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final geom = result['geometry'] as Map<String, dynamic>?;
    final loc = geom?['location'] as Map<String, dynamic>?;
    final lat = (loc?['lat'] as num?)?.toDouble();
    final lng = (loc?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final types =
        (result['types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];

    bool? openNow;
    List<String> weekdayText = const [];
    final oh = result['opening_hours'] as Map<String, dynamic>?;
    if (oh != null) {
      openNow = oh['open_now'] as bool?;
      final wt = oh['weekday_text'] as List<dynamic>?;
      if (wt != null) {
        weekdayText = wt.map((e) => e as String).toList();
      }
    }

    final photoRefs = <String>[];
    final photos = result['photos'] as List<dynamic>?;
    if (photos != null) {
      for (final p in photos.take(6)) {
        final m = p as Map<String, dynamic>?;
        final ref = m?['photo_reference'] as String?;
        if (ref != null && ref.isNotEmpty) photoRefs.add(ref);
      }
    }

    return ExplorePlaceDetails(
      placeId: result['place_id'] as String? ?? placeId,
      name: result['name'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: lat,
      lng: lng,
      rating: (result['rating'] as num?)?.toDouble(),
      userRatingsTotal: (result['user_ratings_total'] as num?)?.toInt(),
      types: types,
      openNow: openNow,
      weekdayText: weekdayText,
      photoReferences: photoRefs,
      googleMapsUri: result['url'] as String?,
    );
  }

  Future<PlaceDetails?> placeDetails(String placeId) async {
    if (apiKey.isEmpty || placeId.isEmpty) return null;

    final uri = Uri.parse('$_base/place/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,name,formatted_address',
        'key': apiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final map = jsonDecode(res.body) as Map<String, dynamic>?;
    if (map == null) return null;
    if ((map['status'] as String?) != 'OK') return null;

    final result = map['result'] as Map<String, dynamic>?;
    if (result == null) return null;
    final geom = result['geometry'] as Map<String, dynamic>?;
    final loc = geom?['location'] as Map<String, dynamic>?;
    if (loc == null) return null;

    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return PlaceDetails(
      placeId: placeId,
      name: result['name'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: lat,
      lng: lng,
    );
  }
}

class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
}

class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });

  final String placeId;
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;
}

/// One row from Nearby Search (before optional Details enrichment).
class NearbyPlaceSummary {
  const NearbyPlaceSummary({
    required this.placeId,
    required this.name,
    required this.vicinity,
    required this.lat,
    required this.lng,
    this.rating,
    this.types = const [],
    this.openNow,
    this.photoReference,
  });

  final String placeId;
  final String name;
  final String vicinity;
  final double lat;
  final double lng;
  final double? rating;
  final List<String> types;
  final bool? openNow;
  final String? photoReference;
}

/// Place Details payload for Explore UI.
class ExplorePlaceDetails {
  const ExplorePlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.openNow,
    this.weekdayText = const [],
    this.photoReferences = const [],
    this.googleMapsUri,
  });

  final String placeId;
  final String name;
  final String formattedAddress;
  final double lat;
  final double lng;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final bool? openNow;
  final List<String> weekdayText;
  final List<String> photoReferences;
  /// When present, opens the official Google Maps place page in a browser.
  final String? googleMapsUri;
}
