import 'package:drift/drift.dart';
import '../app_database.dart';

part 'fitness_dao.g.dart';

@DriftAccessor(tables: [FoodEntries, ExerciseEntries])
class FitnessDao extends DatabaseAccessor<AppDatabase> with _$FitnessDaoMixin {
  FitnessDao(super.db);

  // ─── Food ──────────────────────────────────────────────────────────────────

  Future<List<FoodEntry>> getFoodForDate(DateTime date, {int? userId}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodEntries)
          ..where((f) {
            final dateMatch = f.date.isBetweenValues(start, end);
            if (userId != null) {
              return dateMatch & f.userId.equals(userId);
            }
            return dateMatch & f.userId.isNull();
          })
          ..orderBy([(f) => OrderingTerm.asc(f.date)]))
        .get();
  }

  Stream<List<FoodEntry>> watchFoodForDate(DateTime date, {int? userId}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodEntries)
          ..where((f) {
            final dateMatch = f.date.isBetweenValues(start, end);
            if (userId != null) {
              return dateMatch & f.userId.equals(userId);
            }
            return dateMatch & f.userId.isNull();
          })
          ..orderBy([(f) => OrderingTerm.asc(f.date)]))
        .watch();
  }

  Future<int> insertFood(FoodEntriesCompanion entry) =>
      into(foodEntries).insert(entry);

  Future<bool> updateFood(FoodEntriesCompanion entry) =>
      update(foodEntries).replace(entry);

  Future<int> deleteFood(int id) =>
      (delete(foodEntries)..where((f) => f.id.equals(id))).go();

  // ─── Exercise ──────────────────────────────────────────────────────────────

  Future<List<ExerciseEntry>> getExerciseForDate(DateTime date, {int? userId}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(exerciseEntries)
          ..where((e) {
            final dateMatch = e.date.isBetweenValues(start, end);
            if (userId != null) {
              return dateMatch & e.userId.equals(userId);
            }
            return dateMatch & e.userId.isNull();
          })
          ..orderBy([(e) => OrderingTerm.asc(e.date)]))
        .get();
  }

  Stream<List<ExerciseEntry>> watchExerciseForDate(DateTime date, {int? userId}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(exerciseEntries)
          ..where((e) {
            final dateMatch = e.date.isBetweenValues(start, end);
            if (userId != null) {
              return dateMatch & e.userId.equals(userId);
            }
            return dateMatch & e.userId.isNull();
          })
          ..orderBy([(e) => OrderingTerm.asc(e.date)]))
        .watch();
  }

  Future<int> insertExercise(ExerciseEntriesCompanion entry) =>
      into(exerciseEntries).insert(entry);

  Future<bool> updateExercise(ExerciseEntriesCompanion entry) =>
      update(exerciseEntries).replace(entry);

  Future<int> deleteExercise(int id) =>
      (delete(exerciseEntries)..where((e) => e.id.equals(id))).go();
}
