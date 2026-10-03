/// Small, Flutter-free helpers shared by models and business logic.
///
/// These helpers deliberately avoid intl and other packages so they can be
/// checked with a plain Dart test runner after the Flutter SDK is installed.
String dateKey(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime parseDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.parse(value);
  throw FormatException('Expected a date/time value, got $value');
}

DateTime parseDateOnly(Object? value) {
  final parsed = parseDateTime(value);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

bool boolFromMap(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

int durationSeconds(Object? value) {
  if (value is Duration) return value.inSeconds;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

