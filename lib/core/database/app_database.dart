import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/profile_dao.dart';
import 'daos/auth_dao.dart';
import 'daos/fitness_dao.dart';
import 'daos/routine_dao.dart';
import 'daos/calendar_dao.dart';
import 'daos/purchase_dao.dart';
import 'tables/tables.dart';

export 'tables/tables.dart';
export 'daos/profile_dao.dart';
export 'daos/auth_dao.dart';
export 'daos/fitness_dao.dart';
export 'daos/routine_dao.dart';
export 'daos/calendar_dao.dart';
export 'daos/purchase_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppUsers,
    UserProfiles,
    FoodEntries,
    ExerciseEntries,
    Routines,
    RoutineDays,
    RoutineCompletions,
    CalendarEvents,
    Purchases,
  ],
  daos: [
    AuthDao,
    ProfileDao,
    FitnessDao,
    RoutineDao,
    CalendarDao,
    PurchaseDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'trackmyself_db'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(appUsers);
            await m.addColumn(userProfiles, userProfiles.userId);
          }
          if (from < 3) {
            await m.addColumn(foodEntries, foodEntries.userId);
            await m.addColumn(exerciseEntries, exerciseEntries.userId);
            await m.addColumn(routines, routines.userId);
            await m.addColumn(calendarEvents, calendarEvents.userId);
            await m.addColumn(purchases, purchases.userId);
          }
        },
      );
}
