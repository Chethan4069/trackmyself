import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/password_hasher.dart';

final authDaoProvider = Provider<AuthDao>((ref) {
  return ref.watch(databaseProvider).authDao;
});

final initialUserProvider = Provider<AppUser?>((ref) => null);

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    return ref.watch(initialUserProvider);
  }

  Future<AppUser> login(String email, String password) async {
    final dao = ref.read(authDaoProvider);
    final cleanEmail = email.trim().toLowerCase();
    final user = await dao.getUserByEmail(cleanEmail);

    if (user == null) {
      throw Exception('No account found with $cleanEmail. Please sign up.');
    }

    final isValid = PasswordHasher.verify(password, user.passwordHash);
    if (!isValid) {
      throw Exception('Incorrect password. Please try again.');
    }

    await dao.setLoggedIn(user.id, true);
    final updated = await dao.getLoggedInUser();
    state = updated;
    return updated!;
  }

  Future<AppUser> register(String email, String password) async {
    final dao = ref.read(authDaoProvider);
    final cleanEmail = email.trim().toLowerCase();
    final existing = await dao.getUserByEmail(cleanEmail);

    if (existing != null) {
      throw Exception('An account with $cleanEmail already exists. Please log in.');
    }

    final hash = PasswordHasher.hash(password);
    await dao.createUser(cleanEmail, hash);
    final newUser = await dao.getLoggedInUser();
    state = newUser;
    return newUser!;
  }

  Future<void> logout() async {
    final dao = ref.read(authDaoProvider);
    await dao.logoutAll();
    state = null;
  }
}

final authStateProvider =
    NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

/// Compatibility bridge for widgets reading currentUserProvider
final currentUserProvider = Provider<AsyncValue<AppUser?>>((ref) {
  final user = ref.watch(authStateProvider);
  return AsyncData(user);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  return user != null;
});
