import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

/// Data layer wrapper around [ProfileDao].
class ProfileRepository {
  const ProfileRepository(this._dao);

  final ProfileDao _dao;

  Future<UserProfile?> getProfile({int? userId}) =>
      _dao.getProfile(userId: userId);

  Stream<UserProfile?> watchProfile({int? userId}) =>
      _dao.watchProfile(userId: userId);

  Future<void> upsertProfile(UserProfilesCompanion profile) =>
      _dao.upsertProfile(profile);
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProfileRepository(db.profileDao);
});
