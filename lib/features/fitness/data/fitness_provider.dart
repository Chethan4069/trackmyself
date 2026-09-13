import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../auth/data/auth_provider.dart';
import 'fitness_repository.dart';

class SelectedFitnessDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void select(DateTime date) => state = date;
}

final selectedFitnessDateProvider =
    NotifierProvider<SelectedFitnessDateNotifier, DateTime>(
  SelectedFitnessDateNotifier.new,
);

// ── Food ─────────────────────────────────────────────────────────────────
final todayFoodProvider =
    AsyncNotifierProvider<TodayFoodNotifier, List<FoodEntry>>(
  TodayFoodNotifier.new,
);

class TodayFoodNotifier extends AsyncNotifier<List<FoodEntry>> {
  @override
  Future<List<FoodEntry>> build() async {
    final repo = ref.watch(fitnessRepositoryProvider);
    final date = ref.watch(selectedFitnessDateProvider);
    final user = ref.watch(authStateProvider);
    return repo.getFoodForDate(date, userId: user?.id);
  }

  Future<void> add(FoodEntriesCompanion entry) async {
    final user = ref.read(authStateProvider);
    final withUser = entry.copyWith(userId: drift.Value(user?.id));
    await ref.read(fitnessRepositoryProvider).insertFood(withUser);
    ref.invalidateSelf();
  }

  Future<void> edit(FoodEntriesCompanion entry) async {
    final user = ref.read(authStateProvider);
    final withUser = entry.copyWith(userId: drift.Value(user?.id));
    await ref.read(fitnessRepositoryProvider).updateFood(withUser);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(fitnessRepositoryProvider).deleteFood(id);
    ref.invalidateSelf();
  }
}

// ── Exercise ─────────────────────────────────────────────────────────────
final todayExerciseProvider =
    AsyncNotifierProvider<TodayExerciseNotifier, List<ExerciseEntry>>(
  TodayExerciseNotifier.new,
);

class TodayExerciseNotifier extends AsyncNotifier<List<ExerciseEntry>> {
  @override
  Future<List<ExerciseEntry>> build() async {
    final repo = ref.watch(fitnessRepositoryProvider);
    final date = ref.watch(selectedFitnessDateProvider);
    final user = ref.watch(authStateProvider);
    return repo.getExerciseForDate(date, userId: user?.id);
  }

  Future<void> add(ExerciseEntriesCompanion entry) async {
    final user = ref.read(authStateProvider);
    final withUser = entry.copyWith(userId: drift.Value(user?.id));
    await ref.read(fitnessRepositoryProvider).insertExercise(withUser);
    ref.invalidateSelf();
  }

  Future<void> edit(ExerciseEntriesCompanion entry) async {
    final user = ref.read(authStateProvider);
    final withUser = entry.copyWith(userId: drift.Value(user?.id));
    await ref.read(fitnessRepositoryProvider).updateExercise(withUser);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(fitnessRepositoryProvider).deleteExercise(id);
    ref.invalidateSelf();
  }
}

// ── Derived providers ─────────────────────────────────────────────────────
final todayCaloriesConsumedProvider = Provider<double>((ref) {
  final food = ref.watch(todayFoodProvider).value ?? [];
  return food.fold(0.0, (sum, e) => sum + e.calories);
});

final todayExerciseMinutesProvider = Provider<int>((ref) {
  final exercise = ref.watch(todayExerciseProvider).value ?? [];
  return exercise.fold(0, (sum, e) => sum + e.durationMinutes);
});

final todayCaloriesBurnedProvider = Provider<double>((ref) {
  final exercise = ref.watch(todayExerciseProvider).value ?? [];
  return exercise.fold(0.0, (sum, e) => sum + (e.estimatedCalories ?? 0.0));
});

// ── Water Tracker ─────────────────────────────────────────────────────────
class DailyWaterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void addGlass() => state += 250;
  void removeGlass() {
    if (state >= 250) state -= 250;
  }
  void reset() => state = 0;
}

final dailyWaterProvider = NotifierProvider<DailyWaterNotifier, int>(
  DailyWaterNotifier.new,
);
