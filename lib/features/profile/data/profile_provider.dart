import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../auth/data/auth_provider.dart';
import 'profile_repository.dart';

final initialProfileProvider = Provider<UserProfile?>((ref) => null);

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(authStateProvider);
    if (user == null) return null;

    final initial = ref.watch(initialProfileProvider);
    if (initial != null && initial.userId == user.id) {
      return initial;
    }

    final repo = ref.watch(profileRepositoryProvider);
    return repo.getProfile(userId: user.id);
  }

  Future<void> save(UserProfilesCompanion companion) async {
    state = const AsyncLoading();
    final user = ref.read(authStateProvider);
    final repo = ref.read(profileRepositoryProvider);

    final companionWithUser = companion.copyWith(
      userId: Value(user?.id),
    );

    await repo.upsertProfile(companionWithUser);
    final updated = await repo.getProfile(userId: user?.id);
    state = AsyncData(updated);
  }

  void clear() {
    state = const AsyncData(null);
  }
}

final hasProfileProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.value != null;
});

final userNameProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.name ?? 'there';
});

final dailyCalorieTargetProvider = Provider<int>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return 2000;
  final bmr = _computeBmr(profile);
  final tdee = (bmr * _activityMultiplier(profile.activityLevel)).round();
  return _applyGoal(tdee, profile.fitnessGoal).clamp(1200, 5000);
});

double _computeBmr(UserProfile p) {
  final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
  return switch (p.gender) {
    'male' => base + 5,
    'female' => base - 161,
    _ => base - 78,
  };
}

double _activityMultiplier(String level) => switch (level) {
      'sedentary' => 1.2,
      'lightly_active' => 1.375,
      'moderately_active' => 1.55,
      'very_active' => 1.725,
      _ => 1.375,
    };

int _applyGoal(int tdee, String goal) => switch (goal) {
      'lose_weight' => tdee - 500,
      'gain_weight' => tdee + 400,
      _ => tdee,
    };
