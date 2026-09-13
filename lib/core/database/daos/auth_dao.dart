import 'package:drift/drift.dart';
import '../app_database.dart';

part 'auth_dao.g.dart';

@DriftAccessor(tables: [AppUsers, UserProfiles])
class AuthDao extends DatabaseAccessor<AppDatabase> with _$AuthDaoMixin {
  AuthDao(super.db);

  Future<AppUser?> getLoggedInUser() =>
      (select(appUsers)..where((u) => u.isLoggedIn.equals(true))..limit(1))
          .getSingleOrNull();

  Stream<AppUser?> watchLoggedInUser() =>
      (select(appUsers)..where((u) => u.isLoggedIn.equals(true))..limit(1))
          .watchSingleOrNull();

  Future<AppUser?> getUserByEmail(String email) =>
      (select(appUsers)..where((u) => u.email.equals(email.trim().toLowerCase())))
          .getSingleOrNull();

  Future<int> createUser(String email, String passwordHash) async {
    await logoutAll();
    return into(appUsers).insert(
      AppUsersCompanion.insert(
        email: email.trim().toLowerCase(),
        passwordHash: passwordHash,
        isLoggedIn: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setLoggedIn(int userId, bool loggedIn) async {
    if (loggedIn) {
      await logoutAll();
    }
    await (update(appUsers)..where((u) => u.id.equals(userId))).write(
      AppUsersCompanion(isLoggedIn: Value(loggedIn)),
    );
  }

  Future<void> logoutAll() async {
    await update(appUsers).write(
      const AppUsersCompanion(isLoggedIn: Value(false)),
    );
  }
}
