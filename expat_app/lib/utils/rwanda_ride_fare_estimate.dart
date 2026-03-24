// Rough ride fare estimate in Rwandan Francs (RWF), for UI only.
// Uses a Move-style per-kilometre rate (~610 RWF/km) as a simple proxy for
// cab/car-hailing in Kigali. Not an official Move quote.

/// Move-style rate for distance-based UI estimates (RWF per km).
const int kRwandaRideEstimateRwfPerKm = 1000;

int estimateRwandaRideFareRwf({required int distanceMeters}) {
  if (distanceMeters <= 0) return 0;
  final dKm = distanceMeters / 1000.0;
  return (dKm * kRwandaRideEstimateRwfPerKm).round();
}

/// Formats [value] with thousands separators (e.g. 2500 → "2,500").
String formatRwfAmount(int value) {
  final s = value.toString();
  if (s.length <= 3) return s;
  final buf = StringBuffer();
  final lead = s.length % 3;
  if (lead > 0) {
    buf.write(s.substring(0, lead));
    if (lead < s.length) buf.write(',');
  }
  for (var i = lead; i < s.length; i += 3) {
    buf.write(s.substring(i, i + 3));
    if (i + 3 < s.length) buf.write(',');
  }
  return buf.toString();
}
