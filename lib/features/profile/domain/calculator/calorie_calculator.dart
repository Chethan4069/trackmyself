// TDEE (Total Daily Energy Expenditure) calculator.
///
/// TDEE = BMR × activity multiplier
/// Goal adjustments applied on top.
class CalorieCalculator {
  const CalorieCalculator._();

  /// Returns TDEE in kcal/day rounded to the nearest integer.
  static int calculateTdee({
    required double bmr,
    required String activityLevel,
  }) {
    final multiplier = _activityMultiplier(activityLevel);
    return (bmr * multiplier).round();
  }

  /// Returns the daily calorie target based on TDEE + goal offset.
  static int dailyCalorieTarget({
    required int tdee,
    required String fitnessGoal,
  }) {
    final offset = switch (fitnessGoal) {
      'lose_weight' => -500, // ~0.5 kg/week deficit
      'gain_weight' => 400,  // lean bulk surplus
      'maintain' || 'improve' || 'build_strength' => 0,
      _ => 0,
    };
    return (tdee + offset).clamp(1200, 5000); // safe bounds
  }

  static double _activityMultiplier(String activityLevel) {
    return switch (activityLevel) {
      'sedentary' => 1.2,
      'lightly_active' => 1.375,
      'moderately_active' => 1.55,
      'very_active' => 1.725,
      _ => 1.375,
    };
  }
}
