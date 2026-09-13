import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_self/features/routine/domain/streak_calculator.dart';

void main() {
  group('StreakCalculator', () {
    final refDate = DateTime(2026, 9, 10); // Thursday (weekday = 4)

    test('returns zero streak when no completions exist', () {
      final result = StreakCalculator.calculate(
        scheduledDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {},
        referenceDate: refDate,
      );

      expect(result.currentStreak, 0);
      expect(result.bestStreak, 0);
      expect(result.completionRate, 0.0);
    });

    test('calculates streak when today is completed', () {
      // Completed today (2026-09-10) and yesterday (2026-09-09)
      final result = StreakCalculator.calculate(
        scheduledDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {
          '2026-09-10',
          '2026-09-09',
          '2026-09-08',
        },
        referenceDate: refDate,
      );

      expect(result.currentStreak, 3);
      expect(result.bestStreak, 3);
    });

    test('keeps streak alive if today is not completed yet but yesterday was', () {
      // Completed yesterday (2026-09-09) and day before (2026-09-08), but not today yet
      final result = StreakCalculator.calculate(
        scheduledDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {
          '2026-09-09',
          '2026-09-08',
        },
        referenceDate: refDate,
      );

      expect(result.currentStreak, 2);
    });

    test('resets streak if previous scheduled day was missed', () {
      // Completed 3 days ago, missed yesterday
      final result = StreakCalculator.calculate(
        scheduledDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {
          '2026-09-07',
          '2026-09-06',
        },
        referenceDate: refDate,
      );

      // Missed 2026-09-09 and 2026-09-08
      expect(result.currentStreak, 0);
      expect(result.bestStreak, 2);
    });

    test('non-scheduled days do not break the streak (Weekday habit)', () {
      // Suppose reference date is Monday, 2026-09-14
      final monday = DateTime(2026, 9, 14); // weekday = 1
      // Habit is weekdays only: [1, 2, 3, 4, 5]
      // Completed Friday (2026-09-11) and Thursday (2026-09-10)
      // Sat (12) and Sun (13) are NOT scheduled, so they shouldn't break the streak!
      final result = StreakCalculator.calculate(
        scheduledDays: [1, 2, 3, 4, 5],
        completedDates: {
          '2026-09-11', // Friday
          '2026-09-10', // Thursday
        },
        referenceDate: monday,
      );

      expect(result.currentStreak, 2);
    });

    test('computes best streak across history correctly', () {
      final result = StreakCalculator.calculate(
        scheduledDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: {
          // Old run: 4 consecutive days
          '2026-08-01',
          '2026-08-02',
          '2026-08-03',
          '2026-08-04',
          // Current run: 2 consecutive days
          '2026-09-09',
          '2026-09-10',
        },
        referenceDate: refDate,
      );

      expect(result.currentStreak, 2);
      expect(result.bestStreak, 4);
    });

    test('computes 30-day completion rate', () {
      // 10 completions in last 30 days for daily routine
      final dates = <String>{};
      for (int i = 0; i < 10; i++) {
        final d = refDate.subtract(Duration(days: i));
        dates.add(StreakCalculator.dateKey(d));
      }

      final result = StreakCalculator.calculate(
        scheduledDays: [1, 2, 3, 4, 5, 6, 7],
        completedDates: dates,
        referenceDate: refDate,
      );

      // 10 / 30 = 0.333...
      expect(result.completionRate, closeTo(0.33, 0.02));
    });
  });
}
