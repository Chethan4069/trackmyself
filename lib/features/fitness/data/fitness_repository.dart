import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class FitnessRepository {
  const FitnessRepository(this._dao);
  final FitnessDao _dao;

  Future<List<FoodEntry>> getFoodForDate(DateTime date, {int? userId}) =>
      _dao.getFoodForDate(date, userId: userId);

  Stream<List<FoodEntry>> watchFoodForDate(DateTime date, {int? userId}) =>
      _dao.watchFoodForDate(date, userId: userId);

  Future<int> insertFood(FoodEntriesCompanion e) => _dao.insertFood(e);
  Future<bool> updateFood(FoodEntriesCompanion e) => _dao.updateFood(e);
  Future<int> deleteFood(int id) => _dao.deleteFood(id);

  Future<List<ExerciseEntry>> getExerciseForDate(DateTime date, {int? userId}) =>
      _dao.getExerciseForDate(date, userId: userId);

  Stream<List<ExerciseEntry>> watchExerciseForDate(DateTime date, {int? userId}) =>
      _dao.watchExerciseForDate(date, userId: userId);

  Future<int> insertExercise(ExerciseEntriesCompanion e) => _dao.insertExercise(e);
  Future<bool> updateExercise(ExerciseEntriesCompanion e) => _dao.updateExercise(e);
  Future<int> deleteExercise(int id) => _dao.deleteExercise(id);
}

final fitnessRepositoryProvider = Provider<FitnessRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FitnessRepository(db.fitnessDao);
});
