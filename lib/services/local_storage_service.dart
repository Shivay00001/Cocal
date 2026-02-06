import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStorageService {
  static const String keyProfile = 'cached_profile';
  static const String keyDailySummaryPrefix = 'daily_summary_';
  static const String keyFoodLogsPrefix = 'food_logs_';
  static const String keyWeightLogs = 'cached_weight_logs';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // ============ PROFILE ============
  Future<void> saveProfile(Profile profile) async {
    await _prefs.setString(keyProfile, jsonEncode(profile.toJson()));
  }

  Profile? getProfile() {
    final jsonStr = _prefs.getString(keyProfile);
    if (jsonStr == null) return null;
    try {
      return Profile.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  // ============ FOOD LOGS ============
  Future<void> saveFoodLogs(DateTime date, List<FoodLog> logs) async {
    final key = '$keyFoodLogsPrefix${_dateKey(date)}';
    final jsonList = logs.map((l) => l.toJson()).toList();
    await _prefs.setString(key, jsonEncode(jsonList));
  }

  List<FoodLog> getFoodLogs(DateTime date) {
    final key = '$keyFoodLogsPrefix${_dateKey(date)}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return [];
    try {
      final List list = jsonDecode(jsonStr);
      return list.map((e) => FoodLog.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ============ DAILY SUMMARY ============
  Future<void> saveDailySummary(DateTime date, DailySummary summary) async {
    final key = '$keyDailySummaryPrefix${_dateKey(date)}';
    await _prefs.setString(key, jsonEncode(summary.toJson()));
  }

  DailySummary? getDailySummary(DateTime date) {
    final key = '$keyDailySummaryPrefix${_dateKey(date)}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      return DailySummary.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  // ============ WEIGHT LOGS ============
  Future<void> saveWeightLogs(List<WeightLog> logs) async {
    final jsonList = logs.map((l) => l.toJson()).toList();
    await _prefs.setString(keyWeightLogs, jsonEncode(jsonList));
  }

  List<WeightLog> getWeightLogs() {
    final jsonStr = _prefs.getString(keyWeightLogs);
    if (jsonStr == null) return [];
    try {
      final List list = jsonDecode(jsonStr);
      return list.map((e) => WeightLog.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  String _dateKey(DateTime date) => date.toIso8601String().split('T')[0];
}
