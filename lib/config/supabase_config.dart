import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://gwjwtfqnjfgbwclkvcvh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3and0ZnFuamZnYndjbGt2Y3ZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDE4MTIsImV4cCI6MjA4NTc3NzgxMn0.NJMFoIhxb5iuNcVgzB6Q7PHigOUgmJAC8jVpowoFqWU';
  
  // NOTE: Service role key should NEVER be in client code.
  // Use Supabase Edge Functions or a backend server for admin operations.

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
