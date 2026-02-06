import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final summaryAsync = ref.watch(todaySummaryProvider);
    final foodLogsAsync = ref.watch(todayFoodLogsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoCal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(todayFoodLogsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              profileAsync.when(
                data: (profile) => Text(
                  'Hi, ${profile?.fullName?.split(' ').first ?? 'there'}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 4),
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Daily Progress Card
              summaryAsync.when(
                data: (summary) => _buildProgressCard(context, ref, summary),
                loading: () => _buildLoadingCard(),
                error: (_, __) => _buildProgressCard(context, ref, null),
              ),
              const SizedBox(height: 16),

              // Macro Rings
              profileAsync.when(
                data: (profile) => summaryAsync.when(
                  data: (summary) => _buildMacroRings(context, profile, summary),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(child: _buildQuickAction(context, 'Log Food', Icons.restaurant, '/add-food', AppTheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction(context, 'Exercise', Icons.directions_run, '/add-exercise', const Color(0xFF00BCD4))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildQuickAction(context, 'Habits', Icons.check_circle_outline, '/habits', AppTheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction(context, 'Streaks', Icons.local_fire_department, '/streaks', Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(child: _buildQuickAction(context, 'Log Weight', Icons.monitor_weight, '/add-weight', AppTheme.accent)),
                   const SizedBox(width: 12),
                   Expanded(child: _buildQuickAction(context, 'Compete', Icons.emoji_events, '/competitions', Colors.amber)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(child: _buildQuickAction(context, 'Reports', Icons.analytics, '/reports', const Color(0xFF9C27B0))),
                   const SizedBox(width: 12),
                   Expanded(child: _buildQuickAction(context, 'Review', Icons.rate_review, '/evening-review', const Color(0xFF673AB7))),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Meals
              _buildSectionHeader(context, 'Today\'s Meals'),
              const SizedBox(height: 12),
              foodLogsAsync.when(
                data: (logs) => _buildMealsList(context, logs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading meals'),
              ),
               const SizedBox(height: 24),

              // Body Composition Card
              profileAsync.when(
                data: (profile) {
                  if (profile?.bodyFatPercentage != null || profile?.muscleRating != null) {
                    return _buildBodyCompositionCard(profile!);
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Evening Review Button (show after 6 PM)
              if (DateTime.now().hour >= 18)
                _buildEveningReviewCard(context),

              // Upgrade Banner (if not premium)
              if (!isPremium)
                _buildUpgradeBanner(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-food'),
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildProgressCard(BuildContext context, WidgetRef ref, DailySummary? summary) {
    final profile = ref.watch(profileProvider).asData?.value;
    final target = profile?.dailyCalorieTarget ?? 2000;
    final consumed = summary?.totalCalories ?? 0;
    final remaining = target - consumed;
    final progress = (consumed / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calories Today', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  // Animated Text for Calories
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: consumed),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, _) {
                      return Text(
                        '$value',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  Text('of $target kcal', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Backing Ring
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation(AppTheme.surface),
                    ),
                    // Animated Progress Ring
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            value > 1.0 ? AppTheme.error : AppTheme.primary,
                          ),
                          strokeCap: StrokeCap.round,
                        );
                      },
                    ),
                    Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusPill(remaining),
        ],
      ),
    );
  }

  Widget _buildStatusPill(int remaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: remaining > 0 ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            remaining > 0 ? Icons.check_circle : Icons.warning,
            color: remaining > 0 ? AppTheme.success : AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            remaining > 0 ? '$remaining kcal remaining' : '${-remaining} kcal over limit',
            style: TextStyle(
              color: remaining > 0 ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRings(BuildContext context, Profile? profile, DailySummary? summary) {
    final proteinTarget = profile?.proteinTargetG ?? 60;
    final carbsTarget = profile?.carbsTargetG ?? 250;
    final fatTarget = profile?.fatTargetG ?? 65;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMacroRing('Protein', summary?.totalProteinG ?? 0, proteinTarget.toDouble(), AppTheme.success, 0),
        _buildMacroRing('Carbs', summary?.totalCarbsG ?? 0, carbsTarget.toDouble(), AppTheme.accent, 200),
        _buildMacroRing('Fat', summary?.totalFatG ?? 0, fatTarget.toDouble(), AppTheme.error, 400),
      ],
    );
  }

  Widget _buildMacroRing(String label, double value, double target, Color color, int delayMs) {
    final progress = (value / target).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation(AppTheme.surface),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: Duration(milliseconds: 1000 + delayMs),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
              Text('${value.round()}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, String route, Color color) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18));
  }

  Widget _buildMealsList(BuildContext context, List<FoodLog> logs) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text('No meals logged yet', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('Tap + to add your first meal'),
          ],
        ),
      );
    }

    // Group by meal type
    final grouped = <MealType, List<FoodLog>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.mealType, () => []).add(log);
    }

    return Column(
      children: MealType.values.map((type) {
        final meals = grouped[type] ?? [];
        if (meals.isEmpty) return const SizedBox();
        
        final totalCal = meals.fold(0, (sum, m) => sum + m.calories);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            title: Text(_getMealTypeName(type), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('$totalCal kcal • ${meals.length} items'),
            children: meals.map((m) => ListTile(
              title: Text(m.foodName),
              subtitle: Text('${m.quantityG.round()}g'),
              trailing: Text('${m.calories} kcal', style: TextStyle(color: AppTheme.textSecondary)),
            )).toList(),
          ),
        );
      }).toList(),
    );
  }

   String _getMealTypeName(MealType type) {
    switch (type) {
      case MealType.breakfast: return '🌅 Breakfast';
      case MealType.lunch: return '☀️ Lunch';
      case MealType.snacks: return '🍿 Snacks';
      case MealType.dinner: return '🌙 Dinner';
    }
  }

  Widget _buildBodyCompositionCard(Profile profile) {
    final bodyFat = profile.bodyFatPercentage;
    final muscleRating = profile.muscleRating;
    final currentWeight = profile.currentWeightKg;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardBg, AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.accessibility_new, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Body Composition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (currentWeight != null) ...[
                Expanded(
                  child: _buildBodyMetric('Weight', '${currentWeight.round()} kg'),
                ),
              ],
              if (bodyFat != null) ...[
                Expanded(
                  child: _buildBodyMetric('Body Fat', '${bodyFat.round()}%'),
                ),
              ],
              if (muscleRating != null) ...[
                Expanded(
                  child: _buildMuscleMetric(muscleRating),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMuscleMetric(String rating) {
    final color = _getMuscleColor(rating);
    final label = _getMuscleLabel(rating);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Muscle', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.fitness_center, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Color _getMuscleColor(String rating) {
    switch (rating) {
      case 'excellent': return const Color(0xFF4CAF50);
      case 'good': return const Color(0xFF8BC34A);
      case 'average': return const Color(0xFFFF9800);
      case 'low': return const Color(0xFFFF5722);
      default: return AppTheme.textSecondary;
    }
  }

  String _getMuscleLabel(String rating) {
    switch (rating) {
      case 'excellent': return 'Excellent';
      case 'good': return 'Good';
      case 'average': return 'Average';
      case 'low': return 'Low';
      default: return 'Unknown';
    }
  }

  Widget _buildEveningReviewCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/evening-review'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.accent.withValues(alpha: 0.2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.nightlight_round, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Evening Body Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('See what worked today', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/premium'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Unlock Adaptive Engine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Calories that evolve with your body', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
