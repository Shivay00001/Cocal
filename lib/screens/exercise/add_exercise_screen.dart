import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/exercise_service.dart';
import '../../models/exercise_log.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  String _selectedActivity = 'Running';
  int _durationMinutes = 30;
  String _intensity = 'moderate';
  final TextEditingController _caloriesController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _activities = [
    {'name': 'Running', 'icon': Icons.directions_run, 'caloriesPerMin': 10},
    {'name': 'Walking', 'icon': Icons.directions_walk, 'caloriesPerMin': 4},
    {'name': 'Cycling', 'icon': Icons.directions_bike, 'caloriesPerMin': 8},
    {'name': 'Gym', 'icon': Icons.fitness_center, 'caloriesPerMin': 7},
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'caloriesPerMin': 4},
    {'name': 'Swimming', 'icon': Icons.pool, 'caloriesPerMin': 9},
    {'name': 'HIIT', 'icon': Icons.timer, 'caloriesPerMin': 12},
    {'name': 'Jump Rope', 'icon': Icons.sports_kabaddi, 'caloriesPerMin': 13},
    {'name': 'Dance', 'icon': Icons.music_note, 'caloriesPerMin': 6},
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'caloriesPerMin': 8},
  ];

  @override
  void initState() {
    super.initState();
    _calculateCalories();
  }

  void _calculateCalories() {
    final activity = _activities.firstWhere((a) => a['name'] == _selectedActivity);
    final intensityMultiplier = _intensity == 'high' ? 1.3 : (_intensity == 'low' ? 0.7 : 1.0);
    final calories = (_durationMinutes * activity['caloriesPerMin'] * intensityMultiplier).round();
    _caloriesController.text = calories.toString();
  }

  Future<void> _saveExercise() async {
    if (_caloriesController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final calories = int.parse(_caloriesController.text);

      await ref.read(exerciseServiceProvider).addExerciseLog(
        activityName: _selectedActivity,
        durationMinutes: _durationMinutes,
        caloriesBurned: calories,
        loggedAt: DateTime.now(),
        intensity: _intensity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise logged successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  final isSelected = _selectedActivity == activity['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedActivity = activity['name'];
                        _calculateCalories();
                      });
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(activity['icon'], size: 32, color: isSelected ? Colors.white : AppTheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            activity['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    onChanged: (value) {
                      setState(() {
                        _durationMinutes = value.round();
                        _calculateCalories();
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_durationMinutes min',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Intensity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: ['low', 'moderate', 'high'].map((intensity) {
                final isSelected = _intensity == intensity;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _intensity = intensity;
                        _calculateCalories();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        intensity[0].toUpperCase() + intensity.substring(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Est. Calories Burned', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _caloriesController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  filled: false,
                                  border: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const Text(' kcal', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Text('Save Exercise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
