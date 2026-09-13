import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/profile_provider.dart';
import '../data/fitness_provider.dart';

class ActivityRecommendation {
  const ActivityRecommendation({
    required this.activity,
    required this.durationMinutes,
    required this.reason,
  });
  final String activity;
  final int durationMinutes;
  final String reason;
}

class FitnessRecommendation {
  const FitnessRecommendation({
    required this.recommendations,
    required this.isGoalMet,
    required this.caloriesRemaining,
    required this.exerciseMinutesRemaining,
  });
  final List<ActivityRecommendation> recommendations;
  final bool isGoalMet;
  final double caloriesRemaining;
  final int exerciseMinutesRemaining;
}

class FitnessRecommendationEngine {
  static FitnessRecommendation generate({
    required String fitnessGoal,
    required String activityLevel,
    required int dailyCalorieTarget,
    required double caloriesConsumed,
    required int exerciseMinutesDone,
    required double caloriesBurned,
  }) {
    final targetMinutes = _targetMinutes(fitnessGoal, activityLevel);
    final remainingMinutes = (targetMinutes - exerciseMinutesDone).clamp(0, 999);
    final netCalories = caloriesConsumed - caloriesBurned;
    final caloriesRemaining = dailyCalorieTarget - netCalories;
    final isGoalMet = remainingMinutes == 0;

    if (isGoalMet) {
      return FitnessRecommendation(
        recommendations: const [],
        isGoalMet: true,
        caloriesRemaining: caloriesRemaining,
        exerciseMinutesRemaining: 0,
      );
    }

    return FitnessRecommendation(
      recommendations: _buildRecs(fitnessGoal, remainingMinutes),
      isGoalMet: false,
      caloriesRemaining: caloriesRemaining,
      exerciseMinutesRemaining: remainingMinutes,
    );
  }

  static int _targetMinutes(String goal, String activityLevel) {
    final base = switch (activityLevel) {
      'sedentary' => 20,
      'lightly_active' => 30,
      'moderately_active' => 45,
      'very_active' => 60,
      _ => 30,
    };
    final mod = switch (goal) {
      'lose_weight' => 15,
      'build_strength' => 10,
      'gain_weight' => -10,
      _ => 0,
    };
    return (base + mod).clamp(15, 90);
  }

  static List<ActivityRecommendation> _buildRecs(String goal, int remainingMinutes) {
    return switch (goal) {
      'lose_weight' => [
          ActivityRecommendation(
            activity: 'Brisk Walking',
            durationMinutes: remainingMinutes,
            reason: 'Great for burning fat at a sustainable pace',
          ),
          ActivityRecommendation(
            activity: 'Jump Rope',
            durationMinutes: (remainingMinutes * 0.6).round(),
            reason: 'High calorie burn in short time',
          ),
        ],
      'build_strength' => [
          ActivityRecommendation(
            activity: 'Resistance Training',
            durationMinutes: remainingMinutes,
            reason: 'Builds muscle and boosts metabolism',
          ),
          ActivityRecommendation(
            activity: 'Push-ups & Squats',
            durationMinutes: (remainingMinutes * 0.5).round(),
            reason: 'Compound movements for full-body strength',
          ),
        ],
      'improve' => [
          ActivityRecommendation(
            activity: 'Jogging',
            durationMinutes: remainingMinutes,
            reason: 'Improves cardiovascular fitness',
          ),
          ActivityRecommendation(
            activity: 'Cycling',
            durationMinutes: remainingMinutes,
            reason: 'Low impact, high endurance benefit',
          ),
        ],
      'gain_weight' => [
          ActivityRecommendation(
            activity: 'Weight Training',
            durationMinutes: remainingMinutes,
            reason: 'Ensures weight gain is muscle, not fat',
          ),
        ],
      _ => [
          ActivityRecommendation(
            activity: 'Brisk Walking',
            durationMinutes: remainingMinutes,
            reason: 'Maintains baseline fitness',
          ),
          ActivityRecommendation(
            activity: 'Stretching & Yoga',
            durationMinutes: 15,
            reason: 'Improves flexibility and reduces stress',
          ),
        ],
    };
  }
}

final fitnessRecommendationProvider = Provider<FitnessRecommendation?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return null;
  final caloriesConsumed = ref.watch(todayCaloriesConsumedProvider);
  final exerciseMinutes = ref.watch(todayExerciseMinutesProvider);
  final caloriesBurned = ref.watch(todayCaloriesBurnedProvider);
  final dailyTarget = ref.watch(dailyCalorieTargetProvider);
  return FitnessRecommendationEngine.generate(
    fitnessGoal: profile.fitnessGoal,
    activityLevel: profile.activityLevel,
    dailyCalorieTarget: dailyTarget,
    caloriesConsumed: caloriesConsumed,
    exerciseMinutesDone: exerciseMinutes,
    caloriesBurned: caloriesBurned,
  );
});
