import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/features/notifications/domain/time_of_day_x.dart';

void main() {
  group('TimeOfDayX.parse', () {
    test('parses valid time string correctly', () {
      final result = TimeOfDayX.parse('07:00');
      expect(result.hour, 7);
      expect(result.minute, 0);
    });

    test('parses midnight correctly', () {
      final result = TimeOfDayX.parse('00:00');
      expect(result.hour, 0);
      expect(result.minute, 0);
    });

    test('parses end-of-day time correctly', () {
      final result = TimeOfDayX.parse('23:59');
      expect(result.hour, 23);
      expect(result.minute, 59);
    });

    test('parses time with leading zeros', () {
      final result = TimeOfDayX.parse('09:05');
      expect(result.hour, 9);
      expect(result.minute, 5);
    });

    test('throws FormatException for missing colon', () {
      expect(() => TimeOfDayX.parse('0700'), throwsFormatException);
    });

    test('throws FormatException for too many parts', () {
      expect(() => TimeOfDayX.parse('07:00:00'), throwsFormatException);
    });

    test('throws FormatException for hour out of range', () {
      expect(() => TimeOfDayX.parse('24:00'), throwsFormatException);
    });

    test('throws FormatException for minute out of range', () {
      expect(() => TimeOfDayX.parse('12:60'), throwsFormatException);
    });

    test('throws FormatException for non-numeric input', () {
      expect(() => TimeOfDayX.parse('ab:cd'), throwsFormatException);
    });

    test('throws FormatException for empty string', () {
      expect(() => TimeOfDayX.parse(''), throwsFormatException);
    });
  });

  group('TimeOfDayX.format', () {
    test('formats single-digit hour and minute with leading zeros', () {
      final result = TimeOfDayX.format(hour: 7, minute: 5);
      expect(result, '07:05');
    });

    test('formats midnight as 00:00', () {
      final result = TimeOfDayX.format(hour: 0, minute: 0);
      expect(result, '00:00');
    });

    test('formats end-of-day time correctly', () {
      final result = TimeOfDayX.format(hour: 23, minute: 59);
      expect(result, '23:59');
    });

    test('formats double-digit values without extra padding', () {
      final result = TimeOfDayX.format(hour: 14, minute: 30);
      expect(result, '14:30');
    });
  });

  group('TimeOfDayX round-trip', () {
    test('parse then format produces the same string', () {
      const original = '07:30';
      final parsed = TimeOfDayX.parse(original);
      final formatted = TimeOfDayX.format(
        hour: parsed.hour,
        minute: parsed.minute,
      );
      expect(formatted, original);
    });
  });
}
