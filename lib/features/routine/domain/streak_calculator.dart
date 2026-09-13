/// Result of habit streak calculations.
class StreakResult {
  final int currentStreak;
  final int bestStreak;
  final double completionRate;

  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
  });

  static const zero = StreakResult(
    currentStreak: 0,
    bestStreak: 0,
    completionRate: 0.0,
  );
}

/// Pure domain calculator for habit streaks and completion consistency.
class StreakCalculator {
  const StreakCalculator._();

  /// Formats date to 'YYYY-MM-DD' for key lookup.
  static String dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Computes current streak, best streak, and 30-day completion rate.
  ///
  /// [scheduledDays]: List of weekday integers (1=Monday ... 7=Sunday). If empty, assumes all 7 days.
  /// [completedDates]: Set of 'YYYY-MM-DD' strings on which the habit was completed.
  /// [referenceDate]: The base date to compute backwards from (defaults to today).
  static StreakResult calculate({
    required List<int> scheduledDays,
    required Set<String> completedDates,
    DateTime? referenceDate,
  }) {
    final activeScheduledDays =
        scheduledDays.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : scheduledDays;

    final base = referenceDate ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);

    final currentStreak = _calculateCurrentStreak(
      today: today,
      scheduledDays: activeScheduledDays,
      completedDates: completedDates,
    );

    final bestStreak = _calculateBestStreak(
      today: today,
      scheduledDays: activeScheduledDays,
      completedDates: completedDates,
    );

    final completionRate = _calculateCompletionRate(
      today: today,
      scheduledDays: activeScheduledDays,
      completedDates: completedDates,
    );

    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completionRate: completionRate,
    );
  }

  static int _calculateCurrentStreak({
    required DateTime today,
    required List<int> scheduledDays,
    required Set<String> completedDates,
  }) {
    final todayKey = dateKey(today);
    final isTodayScheduled = scheduledDays.contains(today.weekday);
    final isTodayCompleted = completedDates.contains(todayKey);

    DateTime checkDate;
    int streak = 0;

    if (isTodayScheduled && isTodayCompleted) {
      streak = 1;
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      // If today is not completed yet, the current streak from previous scheduled days is still alive!
      checkDate = today.subtract(const Duration(days: 1));
    }

    // Traverse backwards up to 365 days
    for (int i = 0; i < 365; i++) {
      final isScheduled = scheduledDays.contains(checkDate.weekday);
      if (isScheduled) {
        final key = dateKey(checkDate);
        if (completedDates.contains(key)) {
          streak++;
        } else {
          // Missed scheduled day: streak ends
          break;
        }
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static int _calculateBestStreak({
    required DateTime today,
    required List<int> scheduledDays,
    required Set<String> completedDates,
  }) {
    if (completedDates.isEmpty) return 0;

    // Scan backwards 180 days to find maximum consecutive run
    int maxStreak = 0;
    int currentRun = 0;

    DateTime cursor = today.subtract(const Duration(days: 180));
    while (!cursor.isAfter(today)) {
      final isScheduled = scheduledDays.contains(cursor.weekday);
      if (isScheduled) {
        final key = dateKey(cursor);
        if (completedDates.contains(key)) {
          currentRun++;
          if (currentRun > maxStreak) {
            maxStreak = currentRun;
          }
        } else {
          currentRun = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return maxStreak;
  }

  static double _calculateCompletionRate({
    required DateTime today,
    required List<int> scheduledDays,
    required Set<String> completedDates,
    int days = 30,
  }) {
    int scheduledCount = 0;
    int completedCount = 0;

    DateTime cursor = today.subtract(Duration(days: days - 1));
    while (!cursor.isAfter(today)) {
      if (scheduledDays.contains(cursor.weekday)) {
        scheduledCount++;
        if (completedDates.contains(dateKey(cursor))) {
          completedCount++;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (scheduledCount == 0) return 0.0;
    return (completedCount / scheduledCount).clamp(0.0, 1.0);
  }
}
