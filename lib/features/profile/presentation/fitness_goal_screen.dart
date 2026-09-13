import '../data/onboarding_draft_provider.dart';
import '../../auth/data/auth_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/database/app_database.dart';
import '../data/profile_provider.dart';
import '../domain/calculator/bmi_calculator.dart';
import '../domain/calculator/bmr_calculator.dart';
import '../domain/calculator/calorie_calculator.dart';

/// Step 2 of onboarding � activity level & fitness goal.
class FitnessGoalScreen extends ConsumerStatefulWidget {
  const FitnessGoalScreen({super.key});

  @override
  ConsumerState<FitnessGoalScreen> createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends ConsumerState<FitnessGoalScreen> {
  String _activityLevel = 'lightly_active';
  String _fitnessGoal = 'maintain';
  bool _saving = false;

  static const _activityOptions = [
    _Option(
      value: 'sedentary',
      label: 'Sedentary',
      subtitle: 'Little to no exercise',
      icon: Icons.weekend_outlined,
    ),
    _Option(
      value: 'lightly_active',
      label: 'Lightly Active',
      subtitle: '1�3 days/week',
      icon: Icons.directions_walk_outlined,
    ),
    _Option(
      value: 'moderately_active',
      label: 'Moderately Active',
      subtitle: '3�5 days/week',
      icon: Icons.directions_bike_outlined,
    ),
    _Option(
      value: 'very_active',
      label: 'Very Active',
      subtitle: '6�7 days/week',
      icon: Icons.directions_run_outlined,
    ),
  ];

  static const _goalOptions = [
    _Option(
      value: 'lose_weight',
      label: 'Lose Weight',
      subtitle: '-500 kcal/day deficit',
      icon: Icons.trending_down,
    ),
    _Option(
      value: 'maintain',
      label: 'Maintain Weight',
      subtitle: 'Eat at your TDEE',
      icon: Icons.balance,
    ),
    _Option(
      value: 'improve',
      label: 'Improve Fitness',
      subtitle: 'Eat at TDEE, focus on activity',
      icon: Icons.fitness_center,
    ),
    _Option(
      value: 'gain_weight',
      label: 'Gain Weight',
      subtitle: '+400 kcal/day surplus',
      icon: Icons.trending_up,
    ),
    _Option(
      value: 'build_strength',
      label: 'Build Strength',
      subtitle: 'Eat at TDEE, lift heavy',
      icon: Icons.sports_gymnastics,
    ),
  ];

    Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final draft = ref.read(onboardingDraftProvider);
      final user = ref.read(authStateProvider);
      if (draft == null || user == null) {
        if (mounted) context.go(AppRoutes.profileSetup);
        return;
      }
      await ref.read(userProfileProvider.notifier).save(
            UserProfilesCompanion(
              userId: drift.Value(user.id),
              name: drift.Value(draft.name),
              age: drift.Value(draft.age),
              gender: drift.Value(draft.gender),
              heightCm: drift.Value(draft.heightCm),
              weightKg: drift.Value(draft.weightKg),
              activityLevel: drift.Value(_activityLevel),
              fitnessGoal: drift.Value(_fitnessGoal),
            ),
          );
      ref.read(onboardingDraftProvider.notifier).clear();
      if (mounted) context.go(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final profile = ref.watch(userProfileProvider).value;

    // Live computed preview
    String previewText = '';
    if (profile != null) {
      final bmr = BmrCalculator.calculate(
        weightKg: profile.weightKg,
        heightCm: profile.heightCm,
        age: profile.age,
        gender: profile.gender,
      );
      final tdee = CalorieCalculator.calculateTdee(
        bmr: bmr,
        activityLevel: _activityLevel,
      );
      final target = CalorieCalculator.dailyCalorieTarget(
        tdee: tdee,
        fitnessGoal: _fitnessGoal,
      );
      final bmi = BmiCalculator.calculate(
        weightKg: profile.weightKg,
        heightCm: profile.heightCm,
      );
      final bmiCat = BmiCalculator.category(bmi);
      previewText =
          'BMI $bmi (${bmiCat.label}) � Daily target: $target kcal';
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepBar(current: 2, total: 2),
              const SizedBox(height: 28),

              Text(
                'Your goals',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We use this to calculate your daily calorie targets.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // --- Activity level ---
              Text(
                'ACTIVITY LEVEL',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._activityOptions.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionCard(
                      opt: opt,
                      selected: _activityLevel == opt.value,
                      onTap: () =>
                          setState(() => _activityLevel = opt.value),
                    ),
                  )),

              const SizedBox(height: 24),

              // --- Fitness goal ---
              Text(
                'FITNESS GOAL',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._goalOptions.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionCard(
                      opt: opt,
                      selected: _fitnessGoal == opt.value,
                      onTap: () => setState(() => _fitnessGoal = opt.value),
                    ),
                  )),

              const SizedBox(height: 20),

              // Live preview card
              if (previewText.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          previewText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              FilledButton(
                onPressed: _saving ? null : _finish,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start Tracking'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Option {
  const _Option({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.opt,
    required this.selected,
    required this.onTap,
  });

  final _Option opt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              opt.icon,
              size: 22,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? cs.onPrimaryContainer
                          : cs.onSurface,
                    ),
                  ),
                  Text(
                    opt.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'Step $current of $total',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ),
      ],
    );
  }
}
