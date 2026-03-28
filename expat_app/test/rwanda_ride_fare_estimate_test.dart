import 'package:flutter_test/flutter_test.dart';

import 'package:expat_app/utils/rwanda_ride_fare_estimate.dart';

void main() {
  group('estimateRwandaRideFareRwf', () {
    test('zero or negative distance yields 0', () {
      expect(estimateRwandaRideFareRwf(distanceMeters: 0), 0);
      expect(estimateRwandaRideFareRwf(distanceMeters: -100), 0);
    });

    test('1 km at default rate', () {
      expect(estimateRwandaRideFareRwf(distanceMeters: 1000), 1000);
    });

    test('9.2 km rounds to expected RWF', () {
      expect(estimateRwandaRideFareRwf(distanceMeters: 9200), 9200);
    });
  });

  group('formatRideDurationHms', () {
    test('formats seconds only', () {
      expect(formatRideDurationHms(45), '45s');
    });

    test('formats minutes and seconds', () {
      expect(formatRideDurationHms(125), '2m 5s');
    });

    test('formats hours', () {
      expect(formatRideDurationHms(3725), '1h 2m 5s');
    });

    test('negative treated as zero', () {
      expect(formatRideDurationHms(-10), '0s');
    });
  });

  group('formatRideDistanceKm', () {
    test('zero', () {
      expect(formatRideDistanceKm(0), '0.0');
    });

    test('one decimal', () {
      expect(formatRideDistanceKm(1234), '1.2');
    });
  });

  group('formatRwfAmount', () {
    test('small values without comma', () {
      expect(formatRwfAmount(500), '500');
      expect(formatRwfAmount(999), '999');
    });

    test('thousands separator', () {
      expect(formatRwfAmount(2500), '2,500');
      expect(formatRwfAmount(9199), '9,199');
      expect(formatRwfAmount(1234567), '1,234,567');
    });
  });
}
