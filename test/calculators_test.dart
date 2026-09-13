import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_self/features/profile/domain/calculator/bmi_calculator.dart';
import 'package:track_my_self/features/profile/domain/calculator/bmr_calculator.dart';
import 'package:track_my_self/features/profile/domain/calculator/calorie_calculator.dart';

void main() {
  group('BmiCalculator', () {
    test('calculates BMI correctly — 70 kg / 175 cm', () {
      final bmi = BmiCalculator.calculate(weightKg: 70, heightCm: 175);
      expect(bmi, closeTo(22.9, 0.1));
    });

    test('normal BMI category', () {
      expect(BmiCalculator.category(22.9), BmiCategory.normal);
    });

    test('underweight BMI category', () {
      expect(BmiCalculator.category(17.0), BmiCategory.underweight);
    });

    test('overweight BMI category', () {
      expect(BmiCalculator.category(27.0), BmiCategory.overweight);
    });

    test('obese BMI category', () {
      expect(BmiCalculator.category(32.0), BmiCategory.obese);
    });
  });

  group('BmrCalculator', () {
    test('male BMR — 70 kg, 175 cm, age 24', () {
      // Expected: 10*70 + 6.25*175 - 5*24 + 5 = 700 + 1093.75 - 120 + 5 = 1678.75
      final bmr = BmrCalculator.calculate(
        weightKg: 70,
        heightCm: 175,
        age: 24,
        gender: 'male',
      );
      expect(bmr, closeTo(1678.8, 0.5));
    });

    test('female BMR — 60 kg, 165 cm, age 24', () {
      // Expected: 10*60 + 6.25*165 - 5*24 - 161 = 600 + 1031.25 - 120 - 161 = 1350.25
      final bmr = BmrCalculator.calculate(
        weightKg: 60,
        heightCm: 165,
        age: 24,
        gender: 'female',
      );
      expect(bmr, closeTo(1350.3, 0.5));
    });
  });

  group('CalorieCalculator', () {
    test('TDEE for sedentary — BMR 1678', () {
      final tdee =
          CalorieCalculator.calculateTdee(bmr: 1678, activityLevel: 'sedentary');
      expect(tdee, closeTo(2014, 5));
    });

    test('TDEE for moderately active — BMR 1678', () {
      final tdee = CalorieCalculator.calculateTdee(
          bmr: 1678, activityLevel: 'moderately_active');
      expect(tdee, closeTo(2601, 5));
    });

    test('daily target — lose_weight reduces by 500', () {
      final target = CalorieCalculator.dailyCalorieTarget(
          tdee: 2500, fitnessGoal: 'lose_weight');
      expect(target, 2000);
    });

    test('daily target — gain_weight adds 400', () {
      final target = CalorieCalculator.dailyCalorieTarget(
          tdee: 2500, fitnessGoal: 'gain_weight');
      expect(target, 2900);
    });

    test('daily target clamps below 1200', () {
      final target = CalorieCalculator.dailyCalorieTarget(
          tdee: 1500, fitnessGoal: 'lose_weight');
      expect(target, 1200); // 1500-500=1000, clamped to 1200
    });
  });
}
