import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utilities/date_utils.dart';
import '../../../core/widgets/section_header.dart';
import '../../profile/data/profile_provider.dart';
import '../../profile/domain/calculator/bmi_calculator.dart';
import '../../profile/domain/calculator/bmr_calculator.dart';
import '../data/fitness_provider.dart';
import '../domain/fitness_recommendation_engine.dart';
import 'add_food_screen.dart';
import 'add_exercise_screen.dart';
import 'widgets/progress_photos_section.dart';

class FitnessScreen extends ConsumerWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final profile = ref.watch(userProfileProvider).value;
    final date = ref.watch(selectedFitnessDateProvider);
    final caloriesConsumed = ref.watch(todayCaloriesConsumedProvider);
    final exerciseMinutes = ref.watch(todayExerciseMinutesProvider);
    final caloriesBurned = ref.watch(todayCaloriesBurnedProvider);
    final calorieTarget = ref.watch(dailyCalorieTargetProvider);
    final recommendation = ref.watch(fitnessRecommendationProvider);
    final foodAsync = ref.watch(todayFoodProvider);
    final exerciseAsync = ref.watch(todayExerciseProvider);
    final netCalories = caloriesConsumed - caloriesBurned;
    final progress = (netCalories / calorieTarget).clamp(0.0, 1.0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Fitness'),
            expandedHeight: 100,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                tooltip: 'Select date',
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    ref.read(selectedFitnessDateProvider.notifier).select(picked);
                  }
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Center(
                  child: Chip(
                    avatar: const Icon(Icons.calendar_today, size: 14),
                    label: Text(AppDateUtils.formatFullDay(date)),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.analytics_outlined, size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text('TODAY\'S SUMMARY',
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.primary, letterSpacing: 1.2)),
                        ]),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Net Calories', style: theme.textTheme.bodyMedium),
                            Text(
                              '${netCalories.round()} / $calorieTarget kcal',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: progress > 1.0 ? cs.error : cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (context, animVal, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: animVal,
                              minHeight: 10,
                              backgroundColor: cs.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                  progress > 1.0 ? cs.error : cs.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatPill(
                              icon: Icons.restaurant_outlined,
                              label: 'Eaten',
                              value: '${caloriesConsumed.round()} kcal',
                              color: cs.secondary,
                            ),
                            _StatPill(
                              icon: Icons.local_fire_department,
                              label: 'Burned',
                              value: '${caloriesBurned.round()} kcal',
                              color: Colors.orange,
                            ),
                            _StatPill(
                              icon: Icons.timer_outlined,
                              label: 'Active',
                              value: '$exerciseMinutes min',
                              color: cs.tertiary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // BMI / BMR card
                if (profile != null) ...[
                  Builder(builder: (context) {
                    final bmi = BmiCalculator.calculate(
                      weightKg: profile.weightKg,
                      heightCm: profile.heightCm,
                    );
                    final bmiCat = BmiCalculator.category(bmi);
                    final bmr = BmrCalculator.calculate(
                      weightKg: profile.weightKg,
                      heightCm: profile.heightCm,
                      age: profile.age,
                      gender: profile.gender,
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoChip(
                              label: 'BMI',
                              value: '$bmi',
                              sub: bmiCat.label,
                              color: _bmiColor(bmiCat, cs),
                            ),
                            _InfoChip(
                              label: 'BMR',
                              value: '${bmr.round()}',
                              sub: 'kcal/day',
                              color: cs.primary,
                            ),
                            _InfoChip(
                              label: 'Daily Target',
                              value: '$calorieTarget',
                              sub: 'kcal',
                              color: cs.secondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Recommendation card
                if (recommendation != null)
                  recommendation.isGoalMet
                      ? _GoalMetCard(recommendation: recommendation)
                      : _RecommendationCard(recommendation: recommendation),
                const SizedBox(height: 12),

                // Food log
                SectionHeader(
                  title: 'Food Log',
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddFoodScreen()),
                    ),
                  ),
                ),
                foodAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading food: $e'),
                  ),
                  data: (food) => food.isEmpty
                      ? const _EmptyItem(
                          icon: Icons.restaurant_outlined,
                          text: 'No food logged today. Tap Add to start.',
                        )
                      : _FoodList(entries: food),
                ),
                const SizedBox(height: 8),

                // Exercise log
                SectionHeader(
                  title: 'Exercise Log',
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
                    ),
                  ),
                ),
                exerciseAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading exercise: $e'),
                  ),
                  data: (exercise) => exercise.isEmpty
                      ? const _EmptyItem(
                          icon: Icons.directions_run_outlined,
                          text: 'No exercise logged today. Tap Add to log.',
                        )
                      : _ExerciseList(entries: exercise),
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 16),

                // ── Progress Photos (Same You, Stronger Every Day) ─────────
                const ProgressPhotosSection(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _bmiColor(BmiCategory cat, ColorScheme cs) => switch (cat) {
        BmiCategory.underweight => cs.tertiary,
        BmiCategory.normal => cs.primary,
        BmiCategory.overweight => Colors.orange,
        BmiCategory.obese => cs.error,
      };
}

// ── Recommendation cards ────────────────────────────────────────────────────

class _GoalMetCard extends StatelessWidget {
  const _GoalMetCard({required this.recommendation});
  final FitnessRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      color: cs.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.check_circle, color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity Goal Complete!',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
                Text(
                  'Great work! You\'ve hit your exercise target for today.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});
  final FitnessRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.lightbulb_outline, size: 18, color: cs.tertiary),
              const SizedBox(width: 8),
              Text('RECOMMENDED',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.tertiary, letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 4),
            Text(
              '${recommendation.exerciseMinutesRemaining} min of activity remaining today',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ...recommendation.recommendations.take(2).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.activity} · ${r.durationMinutes} min',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(r.reason,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ── Food list ────────────────────────────────────────────────────────────────

class _FoodList extends ConsumerWidget {
  const _FoodList({required this.entries});
  final List<FoodEntry> entries;

  String _mealLabel(String m) => m
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final grouped = <String, List<FoodEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.mealType, () => []).add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                _mealLabel(group.key),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ...group.value.map((e) => _FoodTile(entry: e)),
          ],
        );
      }).toList(),
    );
  }
}

class _FoodTile extends ConsumerWidget {
  const _FoodTile({required this.entry});
  final FoodEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key('food-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.error,
        child: Icon(Icons.delete_outline, color: cs.onError),
      ),
      onDismissed: (_) =>
          ref.read(todayFoodProvider.notifier).remove(entry.id),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.restaurant_outlined,
              size: 18, color: cs.onPrimaryContainer),
        ),
        title: Text(entry.foodName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(entry.quantity),
        trailing: Text(
          '${entry.calories.round()} kcal',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddFoodScreen(entry: entry)),
        ),
      ),
    );
  }
}

// ── Exercise list ─────────────────────────────────────────────────────────────

class _ExerciseList extends ConsumerWidget {
  const _ExerciseList({required this.entries});
  final List<ExerciseEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: entries.map((e) => _ExerciseTile(entry: e)).toList());
  }
}

class _ExerciseTile extends ConsumerWidget {
  const _ExerciseTile({required this.entry});
  final ExerciseEntry entry;

  String _label(String type) => type
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final intensityColor = switch (entry.intensity) {
      'high' => cs.error,
      'moderate' => Colors.orange,
      _ => cs.tertiary,
    };
    return Dismissible(
      key: Key('exercise-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.error,
        child: Icon(Icons.delete_outline, color: cs.onError),
      ),
      onDismissed: (_) =>
          ref.read(todayExerciseProvider.notifier).remove(entry.id),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fitness_center,
              size: 18, color: cs.onSecondaryContainer),
        ),
        title: Text(_label(entry.exerciseType),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
          Text('${entry.durationMinutes} min'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: intensityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.intensity,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: intensityColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ]),
        trailing: entry.estimatedCalories != null
            ? Text(
                '${entry.estimatedCalories!.round()} kcal',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                    ),
              )
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExerciseScreen(entry: entry)),
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 4),
      Text(value,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      Text(label,
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value,
          style: theme.textTheme.titleLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w800)),
      Text(sub,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _EmptyItem extends StatelessWidget {
  const _EmptyItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
        ),
      ]),
    );
  }
}
