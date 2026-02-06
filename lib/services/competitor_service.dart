import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/streak.dart';

class CompetitorService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Competitor>> getActiveCompetitions() async {
    final response = await _client
        .from('competitors')
        .select()
        .eq('user_id', _userId)
        .eq('status', 'active')
        .gte('end_date', DateTime.now().toIso8601String().split('T')[0]);

    return (response as List).map((e) => Competitor.fromJson(e)).toList();
  }

  Future<List<Competitor>> getAllCompetitions() async {
    final response = await _client
        .from('competitors')
        .select()
        .eq('user_id', _userId)
        .order('start_date', ascending: false);

    return (response as List).map((e) => Competitor.fromJson(e)).toList();
  }

  Future<Competitor> createCompetition({
    required String competitorUserId,
    required String challengeType,
    required int durationDays,
  }) async {
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: durationDays));

    final response = await _client
        .from('competitors')
        .insert({
          'user_id': _userId,
          'competitor_user_id': competitorUserId,
          'challenge_type': challengeType,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'status': 'active',
        })
        .select()
        .single();

    return Competitor.fromJson(response);
  }

  Future<void> updateScore(String competitionId, int score) async {
    await _client
        .from('competitors')
        .update({'user_score': score})
        .eq('id', competitionId);
  }

  Future<void> endCompetition(String competitionId, String winnerId) async {
    await _client
        .from('competitors')
        .update({
          'status': 'completed',
          'winner_id': winnerId,
        })
        .eq('id', competitionId);
  }
}
