import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Driving directions via Google Directions API (overview polyline).
class GoogleDirectionsService {
  GoogleDirectionsService({required this.apiKey});

  final String apiKey;

  static const _base = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Driving route result; [errorDetail] explains API failures (e.g. REQUEST_DENIED).
  Future<DrivingRouteResult> getDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (apiKey.isEmpty) {
      return const DrivingRouteResult(
        route: null,
        errorDetail: 'API key is empty',
      );
    }

    final uri = Uri.parse(_base).replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': apiKey,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return DrivingRouteResult(
        route: null,
        errorDetail: 'HTTP ${res.statusCode}',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>?;
    if (map == null) {
      return const DrivingRouteResult(route: null, errorDetail: 'Invalid JSON');
    }
    final status = map['status'] as String? ?? '';
    if (status != 'OK') {
      final msg = map['error_message'] as String?;
      final detail =
          msg != null && msg.isNotEmpty ? '$status: $msg' : status;
      return DrivingRouteResult(route: null, errorDetail: detail);
    }

    final routes = map['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      return const DrivingRouteResult(route: null, errorDetail: 'No routes');
    }

    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String?;
    if (encoded == null || encoded.isEmpty) {
      return const DrivingRouteResult(route: null, errorDetail: 'No polyline');
    }

    final points = decodeEncodedPolyline(encoded);
    if (points.isEmpty) {
      return const DrivingRouteResult(route: null, errorDetail: 'Empty polyline');
    }

    final legs = route['legs'] as List<dynamic>?;
    String? durationText;
    String? distanceText;
    int totalDurationSec = 0;
    int totalDistanceM = 0;
    if (legs != null && legs.isNotEmpty) {
      for (final l in legs) {
        final leg = l as Map<String, dynamic>;
        final dur = leg['duration'] as Map<String, dynamic>?;
        final dist = leg['distance'] as Map<String, dynamic>?;
        totalDurationSec += (dur?['value'] as num?)?.round() ?? 0;
        totalDistanceM += (dist?['value'] as num?)?.round() ?? 0;
      }
      final first = legs.first as Map<String, dynamic>;
      durationText =
          (first['duration'] as Map<String, dynamic>?)?['text'] as String?;
      distanceText =
          (first['distance'] as Map<String, dynamic>?)?['text'] as String?;
    }

    return DrivingRouteResult(
      route: DirectionsRoute(
        points: points,
        durationText: durationText,
        distanceText: distanceText,
        durationSeconds: totalDurationSec > 0 ? totalDurationSec : null,
        distanceMeters: totalDistanceM > 0 ? totalDistanceM : null,
      ),
      errorDetail: null,
    );
  }
}

/// Result of a Directions API request.
class DrivingRouteResult {
  const DrivingRouteResult({required this.route, required this.errorDetail});

  final DirectionsRoute? route;
  final String? errorDetail;
}

class DirectionsRoute {
  const DirectionsRoute({
    required this.points,
    this.durationText,
    this.distanceText,
    this.durationSeconds,
    this.distanceMeters,
  });

  final List<LatLng> points;
  final String? durationText;
  final String? distanceText;

  /// Sum of leg durations from Directions API (`duration.value`), seconds.
  final int? durationSeconds;

  /// Sum of leg distances from Directions API (`distance.value`), meters.
  final int? distanceMeters;
}

/// Decodes Google's encoded polyline string into [LatLng] points.
List<LatLng> decodeEncodedPolyline(String encoded) {
  final poly = <LatLng>[];
  var index = 0;
  final len = encoded.length;
  var lat = 0;
  var lng = 0;

  while (index < len) {
    var b = 0;
    var shift = 0;
    var result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    poly.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return poly;
}
