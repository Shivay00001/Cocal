import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseStorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  static const String _avatarsBucket = 'avatars';
  static const String _foodPhotosBucket = 'food-photos';

  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    final fileName = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    try {
      await _client.storage
          .from(_avatarsBucket)
          .upload(fileName, imageFile);

      final publicUrl = _client.storage
          .from(_avatarsBucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  Future<String> uploadFoodPhoto(String userId, File imageFile) async {
    final fileName = 'food-photos/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    try {
      await _client.storage
          .from(_foodPhotosBucket)
          .upload(fileName, imageFile);

      final publicUrl = _client.storage
          .from(_foodPhotosBucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload food photo: $e');
    }
  }

  Future<void> deleteProfilePhoto(String filePath) async {
    try {
      await _client.storage
          .from(_avatarsBucket)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete profile photo: $e');
    }
  }

  Future<void> deleteFoodPhoto(String filePath) async {
    try {
      await _client.storage
          .from(_foodPhotosBucket)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete food photo: $e');
    }
  }

  String getProfilePhotoUrl(String userId, String fileName) {
    return _client.storage
        .from(_avatarsBucket)
        .getPublicUrl('avatars/$userId/$fileName');
  }

  String getFoodPhotoUrl(String userId, String fileName) {
    return _client.storage
        .from(_foodPhotosBucket)
        .getPublicUrl('food-photos/$userId/$fileName');
  }
}
