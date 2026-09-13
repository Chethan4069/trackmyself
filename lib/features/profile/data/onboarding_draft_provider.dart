import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileDraft {
  final String name;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;

  const ProfileDraft({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
  });
}

class OnboardingDraftNotifier extends Notifier<ProfileDraft?> {
  @override
  ProfileDraft? build() => null;

  void setDraft(ProfileDraft draft) => state = draft;
  void clear() => state = null;
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, ProfileDraft?>(
  OnboardingDraftNotifier.new,
);
