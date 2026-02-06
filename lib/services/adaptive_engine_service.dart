import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import 'nutrition_calculator.dart';

class AdaptiveEngineService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

  /// Run adaptive engine to adjust calorie/macro targets
  Future<EngineAdjustment> runAdaptiveEngine() async {
    // Get last 7 days summaries
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final summaries = await _client
        .from('daily_summaries')
        .select()
        .eq('user_id', _userId)
        .gte('log_date', sevenDaysAgo.split('T')[0])
        .order('log_date', ascending: false);

    // Get recent weight logs
    final weights = await _client
        .from('weight_logs')
        .select()
        .eq('user_id', _userId)
        .order('logged_at', ascending: false)
        .limit(7);

    // Get current profile
    final profileData = await _client
        .from('profiles')
        .select()
        .eq('id', _userId)
        .single();

    final profile = Profile.fromJson(profileData);
    final weightLogs =
        (weights as List).map((e) => WeightLog.fromJson(e)).toList();

    // Calculate metrics
    final avgCalories = summaries.isEmpty
        ? profile.dailyCalorieTarget
        : (summaries as List)
                .map((s) => s['total_calories'] as int)
                .reduce((a, b) => a + b) ~/
            summaries.length;

    final avgCompliance = summaries.isEmpty
        ? 0.0
        : summaries
                .map((s) => (s['compliance_score'] ?? 0.0) as num)
                .reduce((a, b) => a + b) /
            summaries.length;

    final weightTrend = NutritionCalculator.analyzeWeightTrend(weightLogs);

    return _calculateAdjustments(
      avgCalories: avgCalories,
      avgCompliance: avgCompliance.toDouble(),
      calorieTarget: profile.dailyCalorieTarget,
      proteinTarget: profile.proteinTargetG,
      weightTrend: weightTrend,
      goal: profile.goal,
    );
  }

  EngineAdjustment _calculateAdjustments({
    required int avgCalories,
    required double avgCompliance,
    required int calorieTarget,
    required int proteinTarget,
    required WeightTrend weightTrend,
    required String goal,
  }) {
    int calorieAdjustment = 0;
    int proteinAdjustment = 0;
    List<String> recommendations = [];

    // Rule 1: Good compliance but weight stagnant
    if (avgCompliance > 80 && weightTrend == WeightTrend.stable) {
      if (goal == 'lose') {
        calorieAdjustment = -100;
        recommendations.add('Reducing calories by 100 - your body has adapted');
      } else if (goal == 'gain') {
        calorieAdjustment = 150;
        recommendations.add('Increasing calories by 150 for continued gains');
      }
    }

    // Rule 2: Poor compliance - don't change targets
    if (avgCompliance < 60) {
      recommendations.add('Focus on consistency before adjusting targets');
    }

    // Rule 3: Losing too fast
    if (goal == 'lose' && weightTrend == WeightTrend.losing) {
      final deficit = calorieTarget - avgCalories;
      if (deficit > 700) {
        calorieAdjustment = 100;
        proteinAdjustment = 10;
        recommendations.add('Slowing down to protect muscle mass');
      }
    }

    // Rule 4: Gaining but wants to lose
    if (goal == 'lose' && weightTrend == WeightTrend.gaining) {
      if (avgCompliance > 70) {
        calorieAdjustment = -150;
        recommendations.add('Reducing calories - current target too high');
      } else {
        recommendations.add('Weight gaining due to low compliance');
      }
    }

    // Rule 5: Protein ratio check
    final proteinCalories = proteinTarget * 4;
    final proteinRatio = proteinCalories / calorieTarget;
    if (proteinRatio < 0.25 && goal == 'lose') {
      proteinAdjustment = 15;
      recommendations.add('Increasing protein for better satiety');
    }

    return EngineAdjustment(
      calorieAdjustment: calorieAdjustment,
      proteinAdjustment: proteinAdjustment,
      newCalorieTarget: calorieTarget + calorieAdjustment,
      newProteinTarget: proteinTarget + proteinAdjustment,
      recommendations: recommendations,
      weightTrend: weightTrend,
      avgCompliance: avgCompliance,
    );
  }

  /// Apply adjustments to profile
  Future<void> applyAdjustments(EngineAdjustment adjustment) async {
    if (adjustment.calorieAdjustment == 0 &&
        adjustment.proteinAdjustment == 0) {
      return;
    }

    await _client.from('profiles').update({
      'daily_calorie_target': adjustment.newCalorieTarget,
      'protein_target_g': adjustment.newProteinTarget,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);
  }
}

class EngineAdjustment {
  final int calorieAdjustment;
  final int proteinAdjustment;
  final int newCalorieTarget;
  final int newProteinTarget;
  final List<String> recommendations;
  final WeightTrend weightTrend;
  final double avgCompliance;

  EngineAdjustment({
    required this.calorieAdjustment,
    required this.proteinAdjustment,
    required this.newCalorieTarget,
    required this.newProteinTarget,
    required this.recommendations,
    required this.weightTrend,
    required this.avgCompliance,
  });

  bool get hasChanges => calorieAdjustment != 0 || proteinAdjustment != 0;
}
