// Rough ride fare estimate in Rwandan Francs (RWF), for UI only.
// Distance × [kRwandaRideEstimateRwfPerKm] — tune the constant to match market rates.
// Not an official quote from any operator.

/// Per-kilometre rate for UI estimates (RWF per km). Change here to adjust all snackbars.
const int kRwandaRideEstimateRwfPerKm = 1000;

int estimateRwandaRideFareRwf({required int distanceMeters}) {
  if (distanceMeters <= 0) return 0;
  final dKm = distanceMeters / 1000.0;
  return (dKm * kRwandaRideEstimateRwfPerKm).round();
}

/// Formats total seconds as `Hh Mm Ss` / `Mm Ss` / `Ss` for the rides panel.
String formatRideDurationHms(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '${h}h ${m}m ${s}s';
  }
  if (m > 0) {
    return '${m}m ${s}s';
  }
  return '${s}s';
}

/// Kilometres with one decimal (e.g. 12.4 km).
String formatRideDistanceKm(int distanceMeters) {
  if (distanceMeters <= 0) return '0.0';
  final km = distanceMeters / 1000.0;
  return km.toStringAsFixed(1);
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
