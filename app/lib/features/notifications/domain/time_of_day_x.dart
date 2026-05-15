class TimeOfDayX {
  TimeOfDayX._();

  /// Parses `'07:00'`-style string. Throws [FormatException] on bad input.
  static ({int hour, int minute}) parse(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      throw FormatException('Expected HH:mm, got "$hhmm"');
    }
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    if (h < 0 || h > 23 || m < 0 || m > 59) {
      throw FormatException('Out of range: "$hhmm"');
    }
    return (hour: h, minute: m);
  }

  static String format({required int hour, required int minute}) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
