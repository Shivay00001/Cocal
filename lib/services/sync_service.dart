import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SyncService {
  static const String _queueKey = 'sync_queue';
  final SharedPreferences _prefs;
  final SupabaseClient _client = SupabaseConfig.client;

  SyncService(this._prefs) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final isOnline = result == ConnectivityResult.mobile || 
                      result == ConnectivityResult.wifi || 
                      result == ConnectivityResult.ethernet;
      
      if (isOnline) {
        processQueue();
      }
    });
  }

  Future<void> addToQueue(String table, Map<String, dynamic> data, {String action = 'upsert'}) async {
    final queue = _getQueue();
    queue.add({
      'table': table,
      'data': data,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _saveQueue(queue);
    
    processQueue();
  }

  List<Map<String, dynamic>> _getQueue() {
    final jsonStr = _prefs.getString(_queueKey);
    if (jsonStr == null) return [];
    try {
      final List list = jsonDecode(jsonStr);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _prefs.setString(_queueKey, jsonEncode(queue));
  }

  Future<void> processQueue() async {
    final queue = _getQueue();
    if (queue.isEmpty) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult == ConnectivityResult.mobile || 
                    connectivityResult == ConnectivityResult.wifi || 
                    connectivityResult == ConnectivityResult.ethernet;
                    
    if (!isOnline) return;

    final List<Map<String, dynamic>> remaining = [];

    for (final item in queue) {
      try {
        final table = item['table'] as String;
        final data = item['data'] as Map<String, dynamic>;
        final action = item['action'] as String;

        if (action == 'upsert') {
          await _client.from(table).upsert(data);
        } else if (action == 'insert') {
           await _client.from(table).insert(data);
        } else if (action == 'delete') {
           await _client.from(table).delete().match(Map<String, Object>.from(data));
        }

      } catch (e) {
        debugPrint('Sync failed for item: $e');
        remaining.add(item);
      }
    }

    await _saveQueue(remaining);
  }
}
