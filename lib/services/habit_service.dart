import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class HabitService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

  // ============ HABITS ============

  Future<List<Habit>> getHabits() async {
    final response = await _client
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    
    return (response as List).map((e) => Habit.fromJson(e)).toList();
  }

  Future<Habit> createHabit(String title, {int targetDays = 7}) async {
    final response = await _client.from('habits').insert({
      'user_id': _userId,
      'title': title,
      'target_days_per_week': targetDays,
    }).select().single();

    return Habit.fromJson(response);
  }

  Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
  }

  Future<Habit> updateHabit(String habitId, String title, {int targetDays = 7}) async {
    final response = await _client.from('habits').update({
      'title': title,
      'target_days_per_week': targetDays,
    }).eq('id', habitId).select().single();

    return Habit.fromJson(response);
  }

  // ============ HABIT LOGS ============

  Future<List<HabitLog>> getHabitLogsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _client
        .from('habit_logs')
        .select()
        .eq('user_id', _userId)
        .eq('log_date', dateStr);

    return (response as List).map((e) => HabitLog.fromJson(e)).toList();
  }

  Future<List<HabitLog>> getRecentHabitLogs({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startDateStr = startDate.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('habit_logs')
        .select()
        .eq('user_id', _userId)
        .gte('log_date', startDateStr);

    return (response as List).map((e) => HabitLog.fromJson(e)).toList();
  }

  Future<void> logHabit(String habitId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    await _client.from('habit_logs').upsert({
      'user_id': _userId,
      'habit_id': habitId,
      'log_date': dateStr,
      'completed': true,
    }, onConflict: 'user_id,habit_id,log_date');
  }

  Future<void> unlogHabit(String habitId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    await _client
        .from('habit_logs')
        .delete()
        .eq('user_id', _userId)
        .eq('habit_id', habitId)
        .eq('log_date', dateStr);
  }

  Future<Map<String, bool>> getCompletionStatus(DateTime date) async {
    final logs = await getHabitLogsForDate(date);
    return {for (var log in logs) log.habitId: log.completed};
  }
}
