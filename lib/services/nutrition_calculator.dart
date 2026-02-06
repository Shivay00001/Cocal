import '../models/models.dart';

/// On-device nutrition calculations - NO AI APIs needed
class NutritionCalculator {
  /// Calculate BMR using Mifflin-St Jeor equation
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender == 'male') {
      return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  static double calculateTDEE(double bmr, String activityLevel) {
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    return bmr * (multipliers[activityLevel] ?? 1.2);
  }

  /// Calculate daily calorie target based on goal
  static int calculateCalorieTarget(double tdee, String goal) {
    switch (goal) {
      case 'lose':
        return (tdee - 500).round(); // ~0.5kg/week loss
      case 'gain':
        return (tdee + 300).round(); // ~0.3kg/week gain
      default:
        return tdee.round();
    }
  }

  /// Calculate macro targets based on calorie target
  static MacroTargets calculateMacroTargets({
    required int calorieTarget,
    required String goal,
    required double weightKg,
  }) {
    double proteinRatio, carbsRatio, fatRatio;

    switch (goal) {
      case 'lose':
        proteinRatio = 0.35; // Higher protein for muscle preservation
        carbsRatio = 0.35;
        fatRatio = 0.30;
        break;
      case 'gain':
        proteinRatio = 0.30;
        carbsRatio = 0.45;
        fatRatio = 0.25;
        break;
      default:
        proteinRatio = 0.25;
        carbsRatio = 0.50;
        fatRatio = 0.25;
    }

    // Protein: minimum 1.6g/kg for active individuals
    final minProtein = weightKg * 1.6;
    final calculatedProtein = (calorieTarget * proteinRatio) / 4;
    final proteinG = calculatedProtein > minProtein ? calculatedProtein : minProtein;

    return MacroTargets(
      proteinG: proteinG.round(),
      carbsG: ((calorieTarget * carbsRatio) / 4).round(),
      fatG: ((calorieTarget * fatRatio) / 9).round(),
    );
  }

  /// Calculate compliance score (0-100)
  static double calculateComplianceScore({
    required int actualCalories,
    required int targetCalories,
    required double actualProtein,
    required double targetProtein,
  }) {
    // Calorie compliance (60% weight) - allow 10% deviation
    final calorieDeviation =
        ((actualCalories - targetCalories).abs() / targetCalories);
    final calorieScore = (1 - (calorieDeviation - 0.1).clamp(0, 1)) * 100;

    // Protein compliance (40% weight)
    final proteinRatio = (actualProtein / targetProtein).clamp(0, 1.2);
    final proteinScore = proteinRatio > 1 ? 100 : proteinRatio * 100;

    return (calorieScore * 0.6 + proteinScore * 0.4).clamp(0, 100);
  }

  /// Simple linear regression for weight trend analysis
  static WeightTrend analyzeWeightTrend(List<WeightLog> logs) {
    if (logs.length < 3) return WeightTrend.insufficient;

    final n = logs.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += logs[i].weightKg;
      sumXY += i * logs[i].weightKg;
      sumX2 += i * i;
    }

    // Calculate slope using least squares
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    // Slope per week (assuming daily logs)
    if (slope < -0.05) return WeightTrend.losing;
    if (slope > 0.05) return WeightTrend.gaining;
    return WeightTrend.stable;
  }

  /// Detect if weight has plateaued
  static bool detectPlateau(List<WeightLog> logs, {int daysToCheck = 14}) {
    if (logs.length < daysToCheck) return false;

    final recent = logs.take(daysToCheck).toList();
    final weights = recent.map((l) => l.weightKg).toList();
    final avg = weights.reduce((a, b) => a + b) / weights.length;

    // Check if all weights are within 0.5kg of average
    return weights.every((w) => (w - avg).abs() < 0.5);
  }

  /// Calculate UPF (Ultra-Processed Food) score for the day
  static int calculateUPFScore(List<FoodLog> logs) {
    int score = 0;
    for (final log in logs) {
      if (log.isUltraProcessed) {
        score += 10;
      } else if (log.isPackaged) {
        score += 5;
      }
    }
    return score.clamp(0, 100);
  }

  /// Calculate hidden sugar from packaged foods
  static double calculateHiddenSugar(List<FoodLog> logs) {
    return logs
        .where((log) => log.isPackaged)
        .fold(0.0, (sum, log) => sum + log.sugarG);
  }

  /// Calculate protein gap and suggest foods
  static ProteinGap calculateProteinGap({
    required double currentProtein,
    required double targetProtein,
  }) {
    final gap = targetProtein - currentProtein;
    if (gap <= 0) {
      return ProteinGap(gap: 0, suggestion: 'Target met! Great job!');
    }

    String suggestion;
    if (gap <= 10) {
      suggestion = '1 egg (6g) or 100g yogurt (10g)';
    } else if (gap <= 20) {
      suggestion = '100g paneer (18g) or 100g chicken (25g)';
    } else if (gap <= 30) {
      suggestion = '150g chicken (38g) or protein shake (25g)';
    } else {
      suggestion = 'Add chicken/fish to your next meal + one protein shake';
    }

    return ProteinGap(gap: gap, suggestion: suggestion);
  }

  /// Predict next week weight based on calorie deficit/surplus
  static double predictWeeklyWeightChange({
    required int avgDailyCalories,
    required int tdee,
  }) {
    // 7700 calories = 1 kg of body fat
    final weeklyDeficit = (tdee - avgDailyCalories) * 7;
    return weeklyDeficit / 7700;
  }
}

enum WeightTrend { losing, stable, gaining, insufficient }

class MacroTargets {
  final int proteinG;
  final int carbsG;
  final int fatG;

  MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class ProteinGap {
  final double gap;
  final String suggestion;

  ProteinGap({required this.gap, required this.suggestion});
}
