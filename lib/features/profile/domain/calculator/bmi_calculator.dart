// BMI (Body Mass Index) calculator.
///
/// Formula: weight(kg) / height(m)²
class BmiCalculator {
  const BmiCalculator._();

  /// Returns BMI value rounded to 1 decimal place.
  static double calculate({
    required double weightKg,
    required double heightCm,
  }) {
    assert(weightKg > 0, 'weightKg must be positive');
    assert(heightCm > 0, 'heightCm must be positive');
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Returns a human-readable BMI category.
  static BmiCategory category(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25.0) return BmiCategory.normal;
    if (bmi < 30.0) return BmiCategory.overweight;
    return BmiCategory.obese;
  }
}

enum BmiCategory {
  underweight,
  normal,
  overweight,
  obese;

  String get label {
    return switch (this) {
      BmiCategory.underweight => 'Underweight',
      BmiCategory.normal => 'Normal',
      BmiCategory.overweight => 'Overweight',
      BmiCategory.obese => 'Obese',
    };
  }
}
