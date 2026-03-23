import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Geocoding (forward + reverse) using the same API key as Maps/Places.
class GoogleGeocodingService {
  GoogleGeocodingService({required this.apiKey});

  final String apiKey;

  /// Short place description for [position], or null.
  Future<String?> reverseGeocode(LatLng position) async {
    if (apiKey.isEmpty) return null;

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json',
    ).replace(
      queryParameters: {
        'latlng': '${position.latitude},${position.longitude}',
        'key': apiKey,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final map = jsonDecode(res.body) as Map<String, dynamic>?;
    if (map == null || map['status'] != 'OK') return null;

    final results = map['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    return first['formatted_address'] as String?;
  }

  /// Resolve a typed address / place name to coordinates (e.g. Enter key, From field).
  Future<GeocodeHit?> forwardGeocode(String query) async {
    final q = query.trim();
    if (apiKey.isEmpty || q.isEmpty) return null;

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json',
    ).replace(
      queryParameters: {
        'address': q,
        'key': apiKey,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final map = jsonDecode(res.body) as Map<String, dynamic>?;
    if (map == null) return null;
    final status = map['status'] as String? ?? '';
    if (status != 'OK' || map['results'] == null) return null;

    final results = map['results'] as List<dynamic>;
    if (results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    final formatted = first['formatted_address'] as String? ?? q;
    final geom = first['geometry'] as Map<String, dynamic>?;
    final loc = geom?['location'] as Map<String, dynamic>?;
    if (loc == null) return null;
    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return GeocodeHit(
      latLng: LatLng(lat, lng),
      formattedAddress: formatted,
    );
  }
}

class GeocodeHit {
  const GeocodeHit({
    required this.latLng,
    required this.formattedAddress,
  });

  final LatLng latLng;
  final String formattedAddress;
}
