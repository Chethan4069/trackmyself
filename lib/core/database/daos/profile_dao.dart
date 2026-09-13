import 'package:drift/drift.dart';
import '../app_database.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [UserProfiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  /// Returns user profile for a specific user ID.
  Future<UserProfile?> getProfile({int? userId}) async {
    if (userId != null) {
      return (select(userProfiles)
            ..where((u) => u.userId.equals(userId))
            ..limit(1))
          .getSingleOrNull();
    }
    return null;
  }

  /// Stream version for reactive UI updates scoped to user ID.
  Stream<UserProfile?> watchProfile({int? userId}) {
    if (userId != null) {
      return (select(userProfiles)
            ..where((u) => u.userId.equals(userId))
            ..limit(1))
          .watchSingleOrNull();
    }
    return Stream.value(null);
  }

  /// Insert or update the user profile for a specific user.
  Future<void> upsertProfile(UserProfilesCompanion profile) async {
    final userId = profile.userId.value;
    if (userId != null) {
      final existing = await (select(userProfiles)
            ..where((u) => u.userId.equals(userId))
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) {
        await (update(userProfiles)..where((u) => u.id.equals(existing.id)))
            .write(profile.copyWith(id: Value(existing.id)));
        return;
      }
    }
    await into(userProfiles).insert(profile);
  }
}
