import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

class AddWeightScreen extends ConsumerStatefulWidget {
  const AddWeightScreen({super.key});

  @override
  ConsumerState<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends ConsumerState<AddWeightScreen> {
  double _weight = 70;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Get last logged weight
    final weights = ref.read(weightLogsProvider).asData?.value;
    if (weights != null && weights.isNotEmpty) {
      _weight = weights.first.weightKg;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(foodServiceProvider).addWeightLog(
        _weight,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      ref.invalidate(weightLogsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weight logged: $_weight kg')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightTrend = ref.watch(weightTrendProvider);
    final weights = ref.watch(weightLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Weight')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Weight Display
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text('Today\'s Weight', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _weight.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(' kg', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Trend indicator
                  _buildTrendChip(weightTrend),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Weight Slider
            Slider(
              value: _weight,
              min: 30,
              max: 200,
              divisions: 340,
              onChanged: (v) => setState(() => _weight = double.parse(v.toStringAsFixed(1))),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() => _weight = (_weight - 0.1).clamp(30, 200)),
                ),
                Text('Drag or tap +/- for precision', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _weight = (_weight + 0.1).clamp(30, 200)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., After workout, morning weight',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Recent Weights
            weights.when(
              data: (logs) {
                if (logs.isEmpty) return const SizedBox();
                final recent = logs.take(5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    ...recent.map((w) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${w.weightKg} kg'),
                      subtitle: Text('${w.loggedAt.day}/${w.loggedAt.month}/${w.loggedAt.year}'),
                      trailing: _getWeightDiff(recent.indexOf(w), recent),
                    )),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveWeight,
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Save Weight', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChip(WeightTrend trend) {
    IconData icon;
    String label;
    Color color;

    switch (trend) {
      case WeightTrend.losing:
        icon = Icons.trending_down;
        label = 'Losing';
        color = AppTheme.success;
        break;
      case WeightTrend.gaining:
        icon = Icons.trending_up;
        label = 'Gaining';
        color = AppTheme.warning;
        break;
      case WeightTrend.stable:
        icon = Icons.trending_flat;
        label = 'Stable';
        color = AppTheme.textSecondary;
        break;
      case WeightTrend.insufficient:
        icon = Icons.hourglass_empty;
        label = 'Need more data';
        color = AppTheme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget? _getWeightDiff(int index, List logs) {
    if (index >= logs.length - 1) return null;
    final diff = logs[index].weightKg - logs[index + 1].weightKg;
    if (diff == 0) return null;

    return Text(
      '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
      style: TextStyle(
        color: diff > 0 ? AppTheme.warning : AppTheme.success,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
