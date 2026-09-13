import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calendar Event Logic', () {
    test('calculates exact reminder offset time correctly', () {
      final eventDateTime = DateTime(2026, 9, 15, 14, 30); // 02:30 PM

      // 15 mins before
      final trigger15 = eventDateTime.subtract(const Duration(minutes: 15));
      expect(trigger15, DateTime(2026, 9, 15, 14, 15));

      // 1 hour before
      final trigger60 = eventDateTime.subtract(const Duration(minutes: 60));
      expect(trigger60, DateTime(2026, 9, 15, 13, 30));

      // 1 day before
      final trigger1440 = eventDateTime.subtract(const Duration(minutes: 1440));
      expect(trigger1440, DateTime(2026, 9, 14, 14, 30));
    });

    test('event date key formatting is consistent with YYYY-MM-DD', () {
      final d1 = DateTime(2026, 9, 5);
      final key1 =
          '${d1.year.toString().padLeft(4, '0')}-${d1.month.toString().padLeft(2, '0')}-${d1.day.toString().padLeft(2, '0')}';
      expect(key1, '2026-09-05');

      final d2 = DateTime(2026, 12, 25);
      final key2 =
          '${d2.year.toString().padLeft(4, '0')}-${d2.month.toString().padLeft(2, '0')}-${d2.day.toString().padLeft(2, '0')}';
      expect(key2, '2026-12-25');
    });

    test('event sorting by time works as expected', () {
      final times = ['14:30', '09:15', '20:00', '11:00', '07:45'];
      times.sort();
      expect(times, ['07:45', '09:15', '11:00', '14:30', '20:00']);
    });
  });
}
