import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class ExerciseService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

  // ============ EXERCISE LOGS ============

  Future<List<ExerciseLog>> getExerciseLogsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    // Need to filter by logged_at date part. 
    // Since logged_at is timestamptz, we range query the day.
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final response = await _client
        .from('exercise_logs')
        .select()
        .eq('user_id', _userId)
        .gte('logged_at', startOfDay)
        .lte('logged_at', endOfDay)
        .order('logged_at');

    return (response as List).map((e) => ExerciseLog.fromJson(e)).toList();
  }

  Future<List<ExerciseLog>> getExerciseLogsRange(DateTime start, DateTime end) async {
    // Ensure we cover the full range
    final startStr = start.toIso8601String();
    final endStr = end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)).toIso8601String();
    
    final response = await _client
        .from('exercise_logs')
        .select()
        .eq('user_id', _userId)
        .gte('logged_at', startStr)
        .lte('logged_at', endStr)
        .order('logged_at');

    return (response as List).map((e) => ExerciseLog.fromJson(e)).toList();
  }

  Future<ExerciseLog> addExerciseLog({
    required String activityName,
    required int durationMinutes,
    required int caloriesBurned,
    required DateTime loggedAt,
    String intensity = 'moderate',
    String? notes,
  }) async {
    final response = await _client
        .from('exercise_logs')
        .insert({
          'user_id': _userId,
          'activity_name': activityName,
          'duration_minutes': durationMinutes,
          'calories_burned': caloriesBurned,
          'intensity': intensity,
          'notes': notes,
          'logged_at': loggedAt.toIso8601String(),
        })
        .select()
        .single();

    return ExerciseLog.fromJson(response);
  }

  Future<void> deleteExerciseLog(String logId) async {
    await _client.from('exercise_logs').delete().eq('id', logId);
  }
}
