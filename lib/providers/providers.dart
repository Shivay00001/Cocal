import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../config/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme Mode Provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemePreference(state);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _saveThemePreference(state);
  }

  void _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
  }

  Future<ThemeMode> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode');
    if (themeString != null) {
      return ThemeMode.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => ThemeMode.dark,
      );
    }
    return ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// Service Providers
final authServiceProvider = Provider((ref) => AuthService());
final foodServiceProvider = Provider((ref) => FoodService());
final subscriptionServiceProvider = Provider((ref) => SubscriptionService());
final adaptiveEngineProvider = Provider((ref) => AdaptiveEngineService());
final paymentServiceProvider = Provider.autoDispose((ref) {
  final service = PaymentService();
  ref.onDispose(() => service.dispose());
  return service;
});
final reportServiceProvider = Provider((ref) => ReportService(ref.read(foodServiceProvider)));
final habitServiceProvider = Provider((ref) => HabitService());
final syncServiceProvider = Provider<SyncService>((ref) => throw UnimplementedError());
final excelServiceProvider = Provider((ref) => ExcelService());
final exerciseServiceProvider = Provider((ref) => ExerciseService());
final streakServiceProvider = Provider((ref) => StreakService());
final competitorServiceProvider = Provider((ref) => CompetitorService());

// This will be overridden in main.dart with the initialized instance
final localStorageServiceProvider = Provider<LocalStorageService>((ref) => throw UnimplementedError());

// Auth State
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.client.auth.currentUser;
});

// Profile State - Cache First
final profileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  final storage = ref.read(localStorageServiceProvider);
  final authService = ref.read(authServiceProvider);

  // Return cached if available (optimization: normally FutureProvider doesn't support emit, 
  // but we can return cached and let refresh happen via invalidation or manual sync)
  // Ideally we should use a Notifier for full offline support, but for now:
  
  // 1. Try fetch fresh
  try {
    final profile = await authService.getProfile();
    if (profile != null) {
      storage.saveProfile(profile);
    }
    return profile ?? storage.getProfile();
  } catch (e) {
    // 2. Fallback to cache on error
    return storage.getProfile();
  }
});

// Food Logs for Today
final todayFoodLogsProvider = FutureProvider<List<FoodLog>>((ref) async {
  final date = DateTime.now();
  final storage = ref.read(localStorageServiceProvider);
  final foodService = ref.read(foodServiceProvider);

  try {
    final logs = await foodService.getFoodLogsForDate(date);
    storage.saveFoodLogs(date, logs);
    return logs;
  } catch (e) {
    return storage.getFoodLogs(date);
  }
});

// Daily Summary
final todaySummaryProvider = FutureProvider<DailySummary?>((ref) async {
  final date = DateTime.now();
  final storage = ref.read(localStorageServiceProvider);
  final foodService = ref.read(foodServiceProvider);

  try {
    final summary = await foodService.getDailySummary(date);
    if (summary != null) {
      storage.saveDailySummary(date, summary);
    }
    return summary ?? storage.getDailySummary(date);
  } catch (e) {
    return storage.getDailySummary(date);
  }
});

// Weight Logs
final weightLogsProvider = FutureProvider<List<WeightLog>>((ref) async {
  final storage = ref.read(localStorageServiceProvider);
  final foodService = ref.read(foodServiceProvider);

  try {
    final logs = await foodService.getWeightLogs();
    storage.saveWeightLogs(logs);
    return logs;
  } catch (e) {
    return storage.getWeightLogs();
  }
});

// Weight Trend
final weightTrendProvider = Provider<WeightTrend>((ref) {
  final logsAsync = ref.watch(weightLogsProvider);
  return logsAsync.when(
    data: (logs) => NutritionCalculator.analyzeWeightTrend(logs),
    loading: () => WeightTrend.insufficient,
    error: (_, __) => WeightTrend.insufficient,
  );
});

// Subscription
final subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  final sub = await service.getCurrentSubscription();

  if (sub == null) {
    final trialResult = await service.getOrCreateTrialSubscription();
    return trialResult.subscription;
  }

  return sub;
});

final isPremiumProvider = Provider<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.when(
    data: (sub) => sub?.isPremium ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

final isInTrialProvider = Provider<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.when(
    data: (sub) => sub?.isInTrial ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

final trialDaysRemainingProvider = Provider<int>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.when(
    data: (sub) {
      if (sub?.isInTrial ?? false) {
        final service = ref.read(subscriptionServiceProvider);
        return service.getRemainingTrialDays(sub);
      }
      return 0;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Adaptive Engine Result
final engineAdjustmentProvider = FutureProvider<EngineAdjustment?>((ref) async {
  final isPremium = ref.watch(isPremiumProvider);
  if (!isPremium) return null;
  return ref.read(adaptiveEngineProvider).runAdaptiveEngine();
});

// Selected date for viewing different days - using a Notifier for Riverpod 3.x
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

// Food logs for selected date
final selectedDateFoodLogsProvider = FutureProvider<List<FoodLog>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  return ref.read(foodServiceProvider).getFoodLogsForDate(date);
});

