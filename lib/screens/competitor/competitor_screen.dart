import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/competitor_service.dart';
import '../../models/streak.dart';

class CompetitorScreen extends ConsumerWidget {
  const CompetitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionsAsync = ref.watch(competitionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Competitions')),
      body: competitionsAsync.when(
        data: (competitions) {
          if (competitions.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Active Competitions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...competitions.map((comp) => _buildCompetitionCard(context, comp)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading competitions')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCompetitionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Challenge'),
        backgroundColor: AppTheme.primary,
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
              child: const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Competitions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Challenge friends to stay on track!\nCompete on calories, streaks, or exercise.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionCard(BuildContext context, Competitor comp) {
    final daysLeft = comp.endDate.difference(DateTime.now()).inDays;
    final userPercent = comp.userScore + comp.competitorScore > 0
        ? (comp.userScore / (comp.userScore + comp.competitorScore) * 100).round()
        : 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comp.challengeType == 'calories' ? 'Calorie Challenge' :
                    comp.challengeType == 'streak' ? 'Streak Battle' : 'Exercise Duel',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('$daysLeft days left', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  comp.status.toUpperCase(),
                  style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary,
                      child: Text('You', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    Text('${comp.userScore}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('points', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: userPercent / 100,
                            strokeWidth: 8,
                            backgroundColor: AppTheme.surface,
                            valueColor: const AlwaysStoppedAnimation(Colors.amber),
                          ),
                        ),
                        Text('VS', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.red,
                      child: Text('Rival', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    Text('${comp.competitorScore}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('points', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: userPercent / 100,
              minHeight: 8,
              backgroundColor: AppTheme.surface,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCompetitionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Create Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter competitor email to challenge them!'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Competitor Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Challenge sent!')),
              );
            },
            child: Text('Send Challenge'),
          ),
        ],
      ),
    );
  }
}

final competitionsProvider = FutureProvider<List<Competitor>>((ref) async {
  return ref.read(competitorServiceProvider).getActiveCompetitions();
});
