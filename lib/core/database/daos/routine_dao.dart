import 'package:drift/drift.dart';
import '../app_database.dart';

part 'routine_dao.g.dart';

@DriftAccessor(tables: [Routines, RoutineDays, RoutineCompletions])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);

  // ─── Routines ─────────────────────────────────────────────────────────────

  Future<List<Routine>> getAllActiveRoutines({int? userId}) {
    if (userId != null) {
      return (select(routines)
            ..where((r) => r.isActive.equals(true) & r.userId.equals(userId)))
          .get();
    }
    return (select(routines)
          ..where((r) => r.isActive.equals(true) & r.userId.isNull()))
        .get();
  }

  Stream<List<Routine>> watchAllActiveRoutines({int? userId}) {
    if (userId != null) {
      return (select(routines)
            ..where((r) => r.isActive.equals(true) & r.userId.equals(userId)))
          .watch();
    }
    return (select(routines)
          ..where((r) => r.isActive.equals(true) & r.userId.isNull()))
        .watch();
  }

  Future<Routine?> getRoutineById(int id) =>
      (select(routines)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> insertRoutine(RoutinesCompanion routine) =>
      into(routines).insert(routine);

  Future<bool> updateRoutine(RoutinesCompanion routine) =>
      update(routines).replace(routine);

  Future<int> deleteRoutine(int id) =>
      (delete(routines)..where((r) => r.id.equals(id))).go();

  // ─── Routine Days ─────────────────────────────────────────────────────────

  Future<List<RoutineDay>> getDaysForRoutine(int routineId) =>
      (select(routineDays)..where((d) => d.routineId.equals(routineId))).get();

  Stream<List<RoutineDay>> watchAllRoutineDays() => select(routineDays).watch();

  Future<void> setDaysForRoutine(int routineId, List<int> days) async {
    await (delete(routineDays)..where((d) => d.routineId.equals(routineId)))
        .go();
    for (final day in days) {
      await into(routineDays).insert(
        RoutineDaysCompanion.insert(routineId: routineId, dayOfWeek: day),
      );
    }
  }

  // ─── Routine Completions ──────────────────────────────────────────────────

  Future<RoutineCompletion?> getCompletion(int routineId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(routineCompletions)
          ..where(
            (c) =>
                c.routineId.equals(routineId) &
                c.date.isBetweenValues(start, end),
          ))
        .getSingleOrNull();
  }

  Stream<List<RoutineCompletion>> watchCompletionsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(routineCompletions)
          ..where((c) => c.date.isBetweenValues(start, end)))
        .watch();
  }

  Stream<List<RoutineCompletion>> watchAllCompletions() =>
      select(routineCompletions).watch();

  Future<void> toggleCompletion(
    int routineId,
    DateTime date,
    bool currentlyCompleted,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final existing = await (select(routineCompletions)
          ..where(
            (c) =>
                c.routineId.equals(routineId) &
                c.date.isBetweenValues(start, end),
          ))
        .getSingleOrNull();

    if (existing != null) {
      if (currentlyCompleted) {
        await (update(routineCompletions)..where((c) => c.id.equals(existing.id)))
            .write(
          const RoutineCompletionsCompanion(
            status: Value('pending'),
            completedAt: Value(null),
          ),
        );
      } else {
        await (update(routineCompletions)..where((c) => c.id.equals(existing.id)))
            .write(
          RoutineCompletionsCompanion(
            status: const Value('completed'),
            completedAt: Value(DateTime.now()),
          ),
        );
      }
    } else {
      await into(routineCompletions).insert(
        RoutineCompletionsCompanion.insert(
          routineId: routineId,
          date: start,
          status: currentlyCompleted ? 'pending' : 'completed',
          completedAt: Value(currentlyCompleted ? null : DateTime.now()),
        ),
      );
    }
  }

  Future<List<RoutineCompletion>> getCompletionsInRange(
    DateTime from,
    DateTime to,
  ) =>
      (select(routineCompletions)
            ..where((c) => c.date.isBetweenValues(from, to)))
          .get();
}
