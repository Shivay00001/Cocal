import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/services.dart';
import 'providers/providers.dart';
import 'config/supabase_config.dart';
import 'config/firebase_config.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'screens/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();
  
  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    // Firebase initialization will work when google-services.json is added
  }

  await NotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorageService(prefs);
  final syncService = SyncService(prefs);

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorage),
        syncServiceProvider.overrideWithValue(syncService),
      ],
      child: const CocalApp(),
    ),
  );
}

class CocalApp extends ConsumerStatefulWidget {
  const CocalApp({super.key});

  @override
  ConsumerState<CocalApp> createState() => _CocalAppState();
}

class _CocalAppState extends ConsumerState<CocalApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        title: 'CoCal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: SplashScreen(
          onComplete: () {
            setState(() => _showSplash = false);
          },
        ),
      );
    }

    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CoCal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
