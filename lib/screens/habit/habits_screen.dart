import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

final selectedHabitDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

final habitsProvider = FutureProvider.autoDispose<List<Habit>>((ref) async {
  return ref.watch(habitServiceProvider).getHabits();
});

final habitStreaksProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final logs = await ref.watch(habitServiceProvider).getRecentHabitLogs();
  final Map<String, Set<String>> logsByHabit = {};
  
  for (final log in logs) {
    if (!logsByHabit.containsKey(log.habitId)) logsByHabit[log.habitId] = {};
    logsByHabit[log.habitId]!.add(log.date.toIso8601String().split('T')[0]);
  }
  
  return _calculateAllStreaks(logsByHabit);
});

Map<String, int> _calculateAllStreaks(Map<String, Set<String>> logsByHabit) {
  final streaks = <String, int>{};
  final today = DateTime.now();
  final todayStr = today.toIso8601String().split('T')[0];
  final yesterday = today.subtract(const Duration(days: 1));
  final yesterdayStr = yesterday.toIso8601String().split('T')[0];

  logsByHabit.forEach((id, dates) {
    int currentStreak = 0;
    
    if (dates.contains(todayStr)) {
      currentStreak++;
    } else if (!dates.contains(yesterdayStr)) {
      streaks[id] = 0;
      return;
    }
    
    DateTime pointer = yesterday;
    while (true) {
      final pointerStr = pointer.toIso8601String().split('T')[0];
      if (dates.contains(pointerStr)) {
        currentStreak++;
        pointer = pointer.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    streaks[id] = currentStreak;
  });
  
  return streaks;
}

final habitCompletionProvider = FutureProvider.family<Map<String, bool>, DateTime>((ref, date) async {
  final logs = await ref.watch(habitServiceProvider).getHabitLogsForDate(date);
  return {for (var log in logs) log.habitId: log.completed};
});

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedHabitDateProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final completionAsync = ref.watch(habitCompletionProvider(selectedDate));
    final streaksAsync = ref.watch(habitStreaksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: Column(
        children: [
          _buildWeekCalendar(context, ref, selectedDate),
          Expanded(
            child: habitsAsync.when(
              data: (habits) => completionAsync.when(
                data: (completion) => streaksAsync.when(
                  data: (streaks) => _buildHabitsList(context, ref, habits, completion, streaks, selectedDate),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildHabitsList(context, ref, habits, completion, {}, selectedDate), // Graceful fallback
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading status')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading habits')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitDialog(context, ref),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeekCalendar(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Align with Monday as start of week? Or just generic 7 days?
    // Let's stick to simple "current week starts Monday" logic if desired, or just "Sunday..Saturday"
    // Using `date.weekday` (1=Mon, 7=Sun).
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
          final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

          return InkWell(
            onTap: () => ref.read(selectedHabitDateProvider.notifier).state = date,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected ? Border.all(color: AppTheme.primary) : null,
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date)[0],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, WidgetRef ref, List<Habit> habits, Map<String, bool> completion, Map<String, int> streaks, DateTime date) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No habits yet', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('Add one to start your streak!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final isCompleted = completion[habit.id] ?? false;
        final streak = streaks[habit.id] ?? 0;

        return Dismissible(
          key: Key(habit.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppTheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(habitServiceProvider).deleteHabit(habit.id);
            ref.invalidate(habitsProvider);
            ref.invalidate(habitStreaksProvider);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              onLongPress: () => _showHabitDialog(context, ref, habit: habit),
              title: Text(
                habit.title,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Row(
                children: [
                  Icon(Icons.local_fire_department, size: 16, color: streak > 0 ? Colors.orange : Colors.grey),
                  const SizedBox(width: 4),
                  Text('$streak day streak', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              trailing: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onChanged: (val) async {
                    // Update log
                    if (val == true) {
                      await ref.read(habitServiceProvider).logHabit(habit.id, date);
                    } else {
                      await ref.read(habitServiceProvider).unlogHabit(habit.id, date);
                    }
                    // Refresh logs/status
                    ref.invalidate(habitCompletionProvider(date));
                    // Refresh streaks if we just modifed today/yesterday (which affects streaks)
                    ref.invalidate(habitStreaksProvider);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHabitDialog(BuildContext context, WidgetRef ref, {Habit? habit}) {
    final controller = TextEditingController(text: habit?.title ?? '');
    final isEditing = habit != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Drink water, Read 10 mins',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                if (isEditing) {
                  await ref.read(habitServiceProvider).updateHabit(habit.id, text);
                } else {
                  await ref.read(habitServiceProvider).createHabit(text);
                }
                
                ref.invalidate(habitsProvider);
                if (context.mounted) context.pop();
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }
}
