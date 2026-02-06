import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/streak.dart';

class StreakService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<Streak?> getStreak(String type) async {
    final response = await _client
        .from('streaks')
        .select()
        .eq('user_id', _userId)
        .eq('type', type)
        .maybeSingle();

    if (response == null) return null;
    return Streak.fromJson(response);
  }

  Future<Streak> updateStreak({
    required String type,
    required bool completedToday,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    var streak = await getStreak(type);
    
    if (streak == null) {
      streak = Streak(
        id: '',
        userId: _userId,
        type: type,
        currentStreak: completedToday ? 1 : 0,
        longestStreak: completedToday ? 1 : 0,
        lastCompletedDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final response = await _client
          .from('streaks')
          .insert(streak.toJson())
          .select()
          .single();
      return Streak.fromJson(response);
    }

    final lastDate = streak.lastCompletedDate.toIso8601String().split('T')[0];
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    int newStreak = streak.currentStreak;
    if (completedToday && lastDate != today) {
      if (lastDate == yesterday) {
        newStreak = streak.currentStreak + 1;
      } else {
        newStreak = 1;
      }
    }

    final updatedStreak = streak.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > streak.longestStreak ? newStreak : streak.longestStreak,
      lastCompletedDate: DateTime.now(),
    );

    final response = await _client
        .from('streaks')
        .update(updatedStreak.toJson())
        .eq('id', streak.id)
        .select()
        .single();

    return Streak.fromJson(response);
  }

  Future<List<Streak>> getAllStreaks() async {
    final response = await _client
        .from('streaks')
        .select()
        .eq('user_id', _userId)
        .order('type');

    return (response as List).map((e) => Streak.fromJson(e)).toList();
  }
}

extension on Streak {
  Streak copyWith({
    String? id,
    String? userId,
    String? type,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    DateTime? createdAt,
  }) =>
      Streak(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
        createdAt: createdAt ?? this.createdAt,
      );
}
