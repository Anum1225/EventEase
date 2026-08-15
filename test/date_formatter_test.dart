import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatEventDate formats properly with day and year', () {
      final date = DateTime(2026, 10, 25);
      final formatted = DateFormatter.formatEventDate(date);
      expect(formatted, contains('Oct'));
      expect(formatted, contains('2026'));
    });

    test('formatShortDate formats cleanly', () {
      final date = DateTime(2026, 5, 12);
      final formatted = DateFormatter.formatShortDate(date);
      expect(formatted, contains('May'));
      expect(formatted, contains('12'));
    });

    test('formatRelative produces human readable timestamps', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), 'Just now');
      expect(DateFormatter.formatRelative(null), 'Recently');
    });
  });
}
