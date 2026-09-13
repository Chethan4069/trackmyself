// BMR (Basal Metabolic Rate) calculator using Mifflin-St Jeor equation.
///
/// Male:   BMR = 10w + 6.25h - 5a + 5
/// Female: BMR = 10w + 6.25h - 5a - 161
/// Other:  Average of male and female formulas
class BmrCalculator {
  const BmrCalculator._();

  /// Returns BMR in kcal/day.
  static double calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender, // 'male' | 'female' | 'other'
  }) {
    assert(weightKg > 0);
    assert(heightCm > 0);
    assert(age > 0);

    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    final bmr = switch (gender) {
      'male' => base + 5,
      'female' => base - 161,
      _ => base - 78, // average of +5 and -161
    };
    return double.parse(bmr.toStringAsFixed(1));
  }
}
