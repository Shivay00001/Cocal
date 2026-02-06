import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

class EveningReviewScreen extends ConsumerWidget {
  const EveningReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todaySummaryProvider);
    final profileAsync = ref.watch(profileProvider);
    final foodLogsAsync = ref.watch(todayFoodLogsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evening Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: profileAsync.when(
          data: (profile) => summaryAsync.when(
            data: (summary) => foodLogsAsync.when(
              data: (logs) => _buildReview(context, ref, profile, summary, logs, isPremium),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading data'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading summary'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading profile'),
        ),
      ),
    );
  }

  Widget _buildReview(
    BuildContext context,
    WidgetRef ref,
    Profile? profile,
    DailySummary? summary,
    List<FoodLog> logs,
    bool isPremium,
  ) {
    final calorieTarget = profile?.dailyCalorieTarget ?? 2000;
    final proteinTarget = profile?.proteinTargetG ?? 60;
    final actualCalories = summary?.totalCalories ?? 0;
    final actualProtein = summary?.totalProteinG ?? 0;

    final complianceScore = NutritionCalculator.calculateComplianceScore(
      actualCalories: actualCalories,
      targetCalories: calorieTarget,
      actualProtein: actualProtein.toDouble(),
      targetProtein: proteinTarget.toDouble(),
    );

    final proteinGap = NutritionCalculator.calculateProteinGap(
      currentProtein: actualProtein.toDouble(),
      targetProtein: proteinTarget.toDouble(),
    );

    final hiddenSugar = NutritionCalculator.calculateHiddenSugar(logs);
    final upfScore = NutritionCalculator.calculateUPFScore(logs);

    final bodyFat = profile?.bodyFatPercentage;
    final muscleRating = profile?.muscleRating;
    final currentWeight = profile?.currentWeightKg ?? 0.0;

    // Insights
    final List<ReviewInsight> insights = [];

    // Calorie insight
    final calorieDiff = actualCalories - calorieTarget;
    if (calorieDiff.abs() <= calorieTarget * 0.1) {
      insights.add(ReviewInsight(
        icon: Icons.check_circle,
        title: 'Great calorie control!',
        subtitle: 'You stayed within 10% of your target',
        color: AppTheme.success,
        type: InsightType.positive,
      ));
    } else if (calorieDiff > 0) {
      insights.add(ReviewInsight(
        icon: Icons.warning,
        title: '${calorieDiff.abs()} kcal over target',
        subtitle: 'Try reducing portion sizes tomorrow',
        color: AppTheme.warning,
        type: InsightType.warning,
      ));
    } else {
      insights.add(ReviewInsight(
        icon: Icons.info,
        title: '${calorieDiff.abs()} kcal under target',
        subtitle: 'Make sure you\'re eating enough!',
        color: AppTheme.accent,
        type: InsightType.info,
      ));
    }

    // Protein insight
    if (proteinGap.gap > 0) {
      insights.add(ReviewInsight(
        icon: Icons.fitness_center,
        title: 'Protein gap: ${proteinGap.gap.round()}g',
        subtitle: proteinGap.suggestion,
        color: AppTheme.warning,
        type: InsightType.warning,
      ));
    } else {
      insights.add(ReviewInsight(
        icon: Icons.check_circle,
        title: 'Protein target hit!',
        subtitle: 'Great for muscle maintenance',
        color: AppTheme.success,
        type: InsightType.positive,
      ));
    }

    // Hidden sugar alert
    if (hiddenSugar > 15) {
      insights.add(ReviewInsight(
        icon: Icons.warning_amber,
        title: '${hiddenSugar.round()}g hidden sugar',
        subtitle: 'From packaged foods - reduce tomorrow',
        color: AppTheme.error,
        type: InsightType.warning,
      ));
    }

    // UPF alert
    if (upfScore >= 30) {
      insights.add(ReviewInsight(
        icon: Icons.fastfood,
        title: 'High UPF intake today',
        subtitle: 'Try more whole foods tomorrow',
        color: AppTheme.warning,
        type: InsightType.warning,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getScoreColor(complianceScore).withValues(alpha: 0.2),
                _getScoreColor(complianceScore).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text('Today\'s Discipline Score', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              Text(
                '${complianceScore.round()}',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(complianceScore),
                ),
              ),
              Text(_getScoreLabel(complianceScore), style: TextStyle(fontSize: 18, color: _getScoreColor(complianceScore))),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary stats
        Row(
          children: [
            Expanded(child: _buildStatCard('Calories', '$actualCalories / $calorieTarget', 'kcal')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Protein', '${actualProtein.round()} / $proteinTarget', 'g')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Sugar', '${(summary?.totalSugarG ?? 0).round()}', 'g')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('UPF Score', '$upfScore', '/100')),
          ],
        ),
        const SizedBox(height: 12),
        if (bodyFat != null || muscleRating != null) ...[
          Row(
            children: [
              if (bodyFat != null) ...[
                Expanded(child: _buildStatCard('Body Fat', '${bodyFat.round()}', '%')),
                const SizedBox(width: 12),
              ],
              if (muscleRating != null) ...[
                Expanded(child: _buildMuscleRatingCard(muscleRating)),
              ],
            ],
          ),
        ],
        const SizedBox(height: 24),

        // Insights
        Text('What to know', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        ...insights.map((i) => _buildInsightCard(i)),

        // Tomorrow's plan
        const SizedBox(height: 24),
        Text('Tomorrow\'s Focus', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (proteinGap.gap > 0)
                _buildTomorrowTip('Add protein to breakfast (eggs, yogurt)'),
              if (hiddenSugar > 15)
                _buildTomorrowTip('Choose whole foods over packaged snacks'),
              if (calorieDiff > 200)
                _buildTomorrowTip('Reduce portion sizes slightly'),
              if (complianceScore >= 80)
                _buildTomorrowTip('Keep up the great work! 🎉'),
            ],
          ),
        ),

        // Premium CTA
        if (!isPremium) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () => context.push('/premium'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Get Adaptive Recommendations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Targets that evolve with your body', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(' $unit', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleRatingCard(String rating) {
    final color = _getMuscleRatingColor(rating);
    final icon = _getMuscleRatingIcon(rating);
    final label = _getMuscleRatingLabel(rating);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text('Muscle Rating', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMuscleRatingColor(String rating) {
    switch (rating) {
      case 'excellent':
        return const Color(0xFF4CAF50);
      case 'good':
        return const Color(0xFF8BC34A);
      case 'average':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFFFF5722);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getMuscleRatingIcon(String rating) {
    switch (rating) {
      case 'excellent':
        return Icons.fitness_center;
      case 'good':
        return Icons.health_and_safety;
      case 'average':
        return Icons.accessibility_new;
      case 'low':
        return Icons.accessibility;
      default:
        return Icons.fitness_center;
    }
  }

  String _getMuscleRatingLabel(String rating) {
    switch (rating) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'average':
        return 'Average';
      case 'low':
        return 'Needs Work';
      default:
        return 'Unknown';
    }
  }

  Widget _buildInsightCard(ReviewInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(insight.icon, color: insight.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: TextStyle(fontWeight: FontWeight.w600, color: insight.color)),
                Text(insight.subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.accent;
    return AppTheme.warning;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great job!';
    if (score >= 70) return 'Good effort';
    if (score >= 60) return 'Room for improvement';
    return 'Let\'s do better tomorrow';
  }
}

class ReviewInsight {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final InsightType type;

  ReviewInsight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.type,
  });
}

enum InsightType { positive, warning, info }
