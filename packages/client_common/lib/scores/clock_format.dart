/// The hours and minutes of [when], in the viewer's own time on a 24 hour
/// clock: `13:42`. A score shows this beside its date.
String formatClock(DateTime when) {
  final DateTime local = when.toLocal();

  String two(int value) => value.toString().padLeft(2, "0");

  return "${two(local.hour)}:${two(local.minute)}";
}

/// The full date and time of [when] to the second, in the viewer's own time:
/// `2026-11-07 13:42:09`. What a score shows when it is hovered or held.
String formatFullTime(DateTime when) {
  final DateTime local = when.toLocal();

  String two(int value) => value.toString().padLeft(2, "0");

  return "${local.year.toString().padLeft(4, "0")}-${two(local.month)}-${two(local.day)} "
      "${two(local.hour)}:${two(local.minute)}:${two(local.second)}";
}

const List<String> _weekdays = [
  "Mon",
  "Tue",
  "Wed",
  "Thu",
  "Fri",
  "Sat",
  "Sun",
];
const List<String> _months = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

/// The day of [when] as the Flutter client's medium date shows it in English:
/// `Sat, Nov 7`. For clients that have no localisation of their own.
String formatDay(DateTime when) {
  final DateTime local = when.toLocal();

  return "${_weekdays[local.weekday - 1]}, ${_months[local.month - 1]} ${local.day}";
}
