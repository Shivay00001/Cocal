import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import 'nutrition_calculator.dart';

class FoodService {
  final SupabaseClient _client = SupabaseConfig.client;

  String get _userId => _client.auth.currentUser!.id;

  // ============ FOOD ITEMS ============

  Future<List<FoodItem>> searchFoodItems(String query) async {
    final response = await _client
        .from('food_items')
        .select()
        .or('name.ilike.%$query%,brand.ilike.%$query%')
        .limit(20);

    return (response as List).map((e) => FoodItem.fromJson(e)).toList();
  }

  Future<FoodItem> createFoodItem(FoodItem item) async {
    final response = await _client
        .from('food_items')
        .insert({...item.toJson(), 'created_by': _userId})
        .select()
        .single();
    return FoodItem.fromJson(response);
  }

  // ============ FOOD LOGS ============

  Future<List<FoodLog>> getFoodLogsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _client
        .from('food_logs')
        .select()
        .eq('user_id', _userId)
        .eq('logged_at', dateStr)
        .order('created_at');

    return (response as List).map((e) => FoodLog.fromJson(e)).toList();
  }

  Future<List<FoodLog>> getFoodLogsRange(DateTime start, DateTime end) async {
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('food_logs')
        .select()
        .eq('user_id', _userId)
        .gte('logged_at', startStr)
        .lte('logged_at', endStr)
        .order('logged_at', ascending: true); // Primary sort
        // .order('created_at', ascending: true); // Secondary sort implied usually

    return (response as List).map((e) => FoodLog.fromJson(e)).toList();
  }

  Future<FoodLog> addFoodLog(FoodLog log) async {
    final response = await _client
        .from('food_logs')
        .insert(log.toJson())
        .select()
        .single();

    // Update daily summary
    await _updateDailySummary(log.loggedAt);

    return FoodLog.fromJson(response);
  }

  Future<void> deleteFoodLog(String logId, DateTime date) async {
    await _client.from('food_logs').delete().eq('id', logId);
    await _updateDailySummary(date);
  }

  // ============ DAILY SUMMARY ============

  Future<DailySummary?> getDailySummary(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _client
        .from('daily_summaries')
        .select()
        .eq('user_id', _userId)
        .eq('log_date', dateStr)
        .maybeSingle();

    if (response == null) return null;
    return DailySummary.fromJson(response);
  }

  Future<List<DailySummary>> getDailySummariesRange(DateTime start, DateTime end) async {
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final response = await _client
        .from('daily_summaries')
        .select()
        .eq('user_id', _userId)
        .gte('log_date', startStr)
        .lte('log_date', endStr)
        .order('log_date');

    return (response as List).map((e) => DailySummary.fromJson(e)).toList();
  }

  Future<void> _updateDailySummary(DateTime date) async {
    final logs = await getFoodLogsForDate(date);
    final dateStr = date.toIso8601String().split('T')[0];

    // Calculate totals
    int totalCalories = 0;
    double totalProtein = 0, totalCarbs = 0, totalFat = 0, totalSugar = 0;
    int packagedCount = 0;

    for (final log in logs) {
      totalCalories += log.calories;
      totalProtein += log.proteinG;
      totalCarbs += log.carbsG;
      totalFat += log.fatG;
      totalSugar += log.sugarG;
      if (log.isPackaged) packagedCount++;
    }

    final upfScore = NutritionCalculator.calculateUPFScore(logs);

    // Upsert summary
    await _client.from('daily_summaries').upsert({
      'user_id': _userId,
      'log_date': dateStr,
      'total_calories': totalCalories,
      'total_protein_g': totalProtein,
      'total_carbs_g': totalCarbs,
      'total_fat_g': totalFat,
      'total_sugar_g': totalSugar,
      'packaged_food_count': packagedCount,
      'upf_score': upfScore,
    }, onConflict: 'user_id,log_date');
  }

  // ============ WEIGHT LOGS ============

  Future<List<WeightLog>> getWeightLogs({int limit = 30}) async {
    final response = await _client
        .from('weight_logs')
        .select()
        .eq('user_id', _userId)
        .order('logged_at', ascending: false)
        .limit(limit);

    return (response as List).map((e) => WeightLog.fromJson(e)).toList();
  }
  
  Future<List<WeightLog>> getWeightLogsRange(DateTime start, DateTime end) async {
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('weight_logs')
        .select()
        .eq('user_id', _userId)
        .gte('logged_at', startStr)
        .lte('logged_at', endStr)
        .order('logged_at', ascending: true);

    return (response as List).map((e) => WeightLog.fromJson(e)).toList();
  }

  Future<WeightLog> addWeightLog(double weightKg, {String? notes}) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _client.from('weight_logs').upsert({
      'user_id': _userId,
      'weight_kg': weightKg,
      'logged_at': today,
      'notes': notes,
    }, onConflict: 'user_id,logged_at').select().single();

    return WeightLog.fromJson(response);
  }

  // ============ PHOTO UPLOAD ============

  Future<String> uploadFoodPhoto(Uint8List bytes, String ext, {bool isLabel = false}) async {
    final path =
        '$_userId/${isLabel ? 'labels' : 'foods'}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('food-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _client.storage.from('food-photos').getPublicUrl(path);
  }
}
