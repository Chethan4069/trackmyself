import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_self/features/fitness/domain/fitness_recommendation_engine.dart';

void main() {
  group('FitnessRecommendationEngine', () {
    test('isGoalMet=true when minutes done exceed target', () {
      final result = FitnessRecommendationEngine.generate(
        fitnessGoal: 'maintain',
        activityLevel: 'lightly_active',
        dailyCalorieTarget: 2000,
        caloriesConsumed: 1800,
        exerciseMinutesDone: 60,
        caloriesBurned: 200,
      );
      expect(result.isGoalMet, true);
      expect(result.recommendations, isEmpty);
      expect(result.exerciseMinutesRemaining, 0);
    });

    test('returns recommendations when minutes remaining > 0', () {
      final result = FitnessRecommendationEngine.generate(
        fitnessGoal: 'lose_weight',
        activityLevel: 'moderately_active',
        dailyCalorieTarget: 1500,
        caloriesConsumed: 1200,
        exerciseMinutesDone: 10,
        caloriesBurned: 100,
      );
      expect(result.isGoalMet, false);
      expect(result.recommendations, isNotEmpty);
      expect(result.exerciseMinutesRemaining, greaterThan(0));
    });

    test('caloriesRemaining positive when under target', () {
      final result = FitnessRecommendationEngine.generate(
        fitnessGoal: 'maintain',
        activityLevel: 'lightly_active',
        dailyCalorieTarget: 2000,
        caloriesConsumed: 1000,
        exerciseMinutesDone: 0,
        caloriesBurned: 0,
      );
      expect(result.caloriesRemaining, closeTo(1000, 1));
    });

    test('caloriesRemaining negative when over target', () {
      final result = FitnessRecommendationEngine.generate(
        fitnessGoal: 'maintain',
        activityLevel: 'lightly_active',
        dailyCalorieTarget: 2000,
        caloriesConsumed: 2500,
        exerciseMinutesDone: 0,
        caloriesBurned: 0,
      );
      expect(result.caloriesRemaining, closeTo(-500, 1));
    });

    test('gain_weight goal provides weight-training recommendation', () {
      final result = FitnessRecommendationEngine.generate(
        fitnessGoal: 'gain_weight',
        activityLevel: 'lightly_active',
        dailyCalorieTarget: 2900,
        caloriesConsumed: 2800,
        exerciseMinutesDone: 0,
        caloriesBurned: 0,
      );
      expect(result.isGoalMet, false);
      expect(
        result.recommendations.any((r) => r.activity.contains('Weight')),
        true,
      );
    });

    test('sedentary target is 20 min for maintain goal', () {
      final result = FitnessRecommendationEngine.generate(
        fitnessGoal: 'maintain',
        activityLevel: 'sedentary',
        dailyCalorieTarget: 1800,
        caloriesConsumed: 0,
        exerciseMinutesDone: 0,
        caloriesBurned: 0,
      );
      expect(result.exerciseMinutesRemaining, 20);
    });
  });
}
