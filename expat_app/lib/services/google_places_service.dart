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
