import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/streak_service.dart';
import '../../models/streak.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaksAsync = ref.watch(streaksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Streaks')),
      body: streaksAsync.when(
        data: (streaks) {
          if (streaks.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildOverallCard(streaks),
              const SizedBox(height: 24),
              const Text('Active Streaks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...streaks.map((streak) => _buildStreakCard(streak)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading streaks')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.local_fire_department, size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Streaks Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start logging your meals, exercise, and habits to build streaks!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallCard(List<Streak> streaks) {
    final totalStreak = streaks.fold<int>(0, (sum, s) => sum + s.currentStreak);
    final longestStreak = streaks.fold<int>(0, (max, s) => s.longestStreak > max ? s.longestStreak : max);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Streak Days',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalStreak',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best Streak',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$longestStreak days',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(Streak streak) {
    final color = _getStreakColor(streak.type);
    final icon = _getStreakIcon(streak.type);
    final label = _getStreakLabel(streak.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${streak.currentStreak} day streak',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${streak.longestStreak}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Best',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStreakColor(String type) {
    switch (type) {
      case 'meal':
        return Colors.green;
      case 'exercise':
        return Colors.blue;
      case 'weight':
        return Colors.purple;
      case 'habit':
        return Colors.orange;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getStreakIcon(String type) {
    switch (type) {
      case 'meal':
        return Icons.restaurant;
      case 'exercise':
        return Icons.fitness_center;
      case 'weight':
        return Icons.monitor_weight;
      case 'habit':
        return Icons.check_circle;
      default:
        return Icons.star;
    }
  }

  String _getStreakLabel(String type) {
    switch (type) {
      case 'meal':
        return 'Meal Logging';
      case 'exercise':
        return 'Exercise';
      case 'weight':
        return 'Weight Tracking';
      case 'habit':
        return 'Habits';
      default:
        return 'Streak';
    }
  }
}

final streaksProvider = FutureProvider<List<Streak>>((ref) async {
  return ref.read(streakServiceProvider).getAllStreaks();
});
