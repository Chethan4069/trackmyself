import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../auth/data/auth_provider.dart';
import '../domain/streak_calculator.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class RoutineItem {
  final Routine routine;
  final List<int> scheduledDays;
  final bool isCompleted;
  final RoutineCompletion? completion;
  final int currentStreak;
  final int bestStreak;
  final double completionRate;
  final bool isScheduledForDate;

  const RoutineItem({
    required this.routine,
    required this.scheduledDays,
    required this.isCompleted,
    this.completion,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.isScheduledForDate,
  });
}

class RoutineDayStats {
  final int totalScheduled;
  final int completedCount;
  final double completionPercentage;

  const RoutineDayStats({
    required this.totalScheduled,
    required this.completedCount,
    required this.completionPercentage,
  });

  static const zero = RoutineDayStats(
    totalScheduled: 0,
    completedCount: 0,
    completionPercentage: 0.0,
  );
}

// ─── Selected Routine Date ───────────────────────────────────────────────────

class SelectedRoutineDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void goToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }
}

final selectedRoutineDateProvider =
    NotifierProvider<SelectedRoutineDateNotifier, DateTime>(
  SelectedRoutineDateNotifier.new,
);

// ─── Category Filter Provider ────────────────────────────────────────────────

class RoutineCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String category) => state = category;
}

final routineCategoryFilterProvider =
    NotifierProvider<RoutineCategoryFilterNotifier, String>(
  RoutineCategoryFilterNotifier.new,
);

// ─── Stream Providers ────────────────────────────────────────────────────────

final routineDaoProvider = Provider<RoutineDao>((ref) {
  return ref.watch(databaseProvider).routineDao;
});

final activeRoutinesStreamProvider = StreamProvider<List<Routine>>((ref) {
  final dao = ref.watch(routineDaoProvider);
  final user = ref.watch(authStateProvider);
  return dao.watchAllActiveRoutines(userId: user?.id);
});

final allRoutineDaysStreamProvider = StreamProvider<List<RoutineDay>>((ref) {
  final dao = ref.watch(routineDaoProvider);
  return dao.watchAllRoutineDays();
});

final allRoutineCompletionsStreamProvider =
    StreamProvider<List<RoutineCompletion>>((ref) {
  final dao = ref.watch(routineDaoProvider);
  return dao.watchAllCompletions();
});

// ─── Combined Routines for Selected Date ─────────────────────────────────────

final routinesForDateProvider = Provider<AsyncValue<List<RoutineItem>>>((ref) {
  final routinesAsync = ref.watch(activeRoutinesStreamProvider);
  final daysAsync = ref.watch(allRoutineDaysStreamProvider);
  final completionsAsync = ref.watch(allRoutineCompletionsStreamProvider);
  final selectedDate = ref.watch(selectedRoutineDateProvider);

  if (routinesAsync is AsyncLoading ||
      daysAsync is AsyncLoading ||
      completionsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (routinesAsync.hasError) {
    return AsyncValue.error(routinesAsync.error!, routinesAsync.stackTrace!);
  }

  final routines = routinesAsync.value ?? [];

  final allDays = daysAsync.value ?? [];
  final allCompletions = completionsAsync.value ?? [];

  final Map<int, List<int>> daysByRoutine = {};
  for (final d in allDays) {
    daysByRoutine.putIfAbsent(d.routineId, () => []).add(d.dayOfWeek);
  }

  final Map<int, Set<String>> completedDatesByRoutine = {};
  final Map<int, RoutineCompletion> selectedDateCompletionByRoutine = {};

  final selDateStart =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final selDateEnd = selDateStart.add(const Duration(days: 1));

  for (final c in allCompletions) {
    if (c.status == 'completed') {
      completedDatesByRoutine
          .putIfAbsent(c.routineId, () => {})
          .add(StreakCalculator.dateKey(c.date));
    }

    if (c.date.isAfter(selDateStart.subtract(const Duration(seconds: 1))) &&
        c.date.isBefore(selDateEnd)) {
      selectedDateCompletionByRoutine[c.routineId] = c;
    }
  }

  final items = routines.map((routine) {
    final scheduledDays = daysByRoutine[routine.id] ?? const [1, 2, 3, 4, 5, 6, 7];
    final isScheduled = scheduledDays.contains(selectedDate.weekday);
    final comp = selectedDateCompletionByRoutine[routine.id];
    final isCompleted = comp?.status == 'completed';

    final streak = StreakCalculator.calculate(
      scheduledDays: scheduledDays,
      completedDates: completedDatesByRoutine[routine.id] ?? const {},
      referenceDate: selectedDate,
    );

    return RoutineItem(
      routine: routine,
      scheduledDays: scheduledDays,
      isCompleted: isCompleted,
      completion: comp,
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
      completionRate: streak.completionRate,
      isScheduledForDate: isScheduled,
    );
  }).toList();

  items.sort((a, b) {
    if (a.isScheduledForDate && !b.isScheduledForDate) return -1;
    if (!a.isScheduledForDate && b.isScheduledForDate) return 1;
    return a.routine.time.compareTo(b.routine.time);
  });

  return AsyncValue.data(items);
});

// ─── Daily Stats ─────────────────────────────────────────────────────────────

final routineDayStatsProvider = Provider<RoutineDayStats>((ref) {
  final itemsAsync = ref.watch(routinesForDateProvider);
  return itemsAsync.when(
    data: (items) {
      final scheduled = items.where((i) => i.isScheduledForDate).toList();
      if (scheduled.isEmpty) return RoutineDayStats.zero;
      final completed = scheduled.where((i) => i.isCompleted).length;
      return RoutineDayStats(
        totalScheduled: scheduled.length,
        completedCount: completed,
        completionPercentage: completed / scheduled.length,
      );
    },
    loading: () => RoutineDayStats.zero,
    error: (_, _) => RoutineDayStats.zero,
  );
});

// ─── Best Overall Streak ─────────────────────────────────────────────────────

final bestOverallStreakProvider = Provider<int>((ref) {
  final itemsAsync = ref.watch(routinesForDateProvider);
  return itemsAsync.when(
    data: (items) {
      if (items.isEmpty) return 0;
      int best = 0;
      for (final item in items) {
        if (item.currentStreak > best) best = item.currentStreak;
        if (item.bestStreak > best) best = item.bestStreak;
      }
      return best;
    },
    loading: () => 0,
    error: (_, _) => 0,
  );
});

// ─── Controller ──────────────────────────────────────────────────────────────

final routineControllerProvider = Provider<RoutineController>((ref) {
  final dao = ref.watch(routineDaoProvider);
  final user = ref.watch(authStateProvider);
  return RoutineController(dao, user?.id);
});

class RoutineController {
  final RoutineDao _dao;
  final int? _userId;

  RoutineController(this._dao, [this._userId]);

  Future<int> saveRoutine({
    int? id,
    required String name,
    required String time, // 'HH:mm'
    required String category,
    required bool reminderEnabled,
    required List<int> daysOfWeek,
  }) async {
    final cleanDays = daysOfWeek.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : daysOfWeek;

    if (id == null) {
      final newId = await _dao.insertRoutine(
        RoutinesCompanion.insert(
          userId: Value(_userId),
          name: name.trim(),
          time: time,
          category: category,
          reminderEnabled: Value(reminderEnabled),
          isActive: const Value(true),
          createdAt: Value(DateTime.now()),
        ),
      );

      await _dao.setDaysForRoutine(newId, cleanDays);

      if (reminderEnabled) {
        await NotificationService.instance.scheduleDailyRoutineReminder(
          id: newId,
          title: name.trim(),
          time: time,
          daysOfWeek: cleanDays,
        );
      }

      return newId;
    } else {
      final existing = await _dao.getRoutineById(id);
      if (existing != null) {
        await _dao.updateRoutine(
          RoutinesCompanion(
            id: Value(id),
            userId: Value(existing.userId ?? _userId),
            name: Value(name.trim()),
            time: Value(time),
            category: Value(category),
            reminderEnabled: Value(reminderEnabled),
            isActive: Value(existing.isActive),
            createdAt: Value(existing.createdAt),
          ),
        );

        await _dao.setDaysForRoutine(id, cleanDays);

        if (reminderEnabled) {
          await NotificationService.instance.scheduleDailyRoutineReminder(
            id: id,
            title: name.trim(),
            time: time,
            daysOfWeek: cleanDays,
          );
        } else {
          await NotificationService.instance.cancel(id);
        }
      }
      return id;
    }
  }

  Future<void> toggleCompletion({
    required int routineId,
    required DateTime date,
    required bool currentlyCompleted,
  }) async {
    await _dao.toggleCompletion(routineId, date, currentlyCompleted);
  }

  Future<void> deleteRoutine(int id) async {
    await _dao.deleteRoutine(id);
    await NotificationService.instance.cancel(id);
  }
}
