// Shared date grouping for chat and payments Track (local calendar).

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dateOnlyLocal(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Today / Yesterday / dd/MM/yyyy — same wording as conversation thread dividers.
String threadDayDividerLabel(DateTime day, DateTime now) {
  final today = dateOnlyLocal(now);
  final yesterday = today.subtract(const Duration(days: 1));
  if (isSameCalendarDay(day, today)) return 'Today';
  if (isSameCalendarDay(day, yesterday)) return 'Yesterday';
  final d = day.day.toString().padLeft(2, '0');
  final mo = day.month.toString().padLeft(2, '0');
  final y = day.year.toString();
  return '$d/$mo/$y';
}
