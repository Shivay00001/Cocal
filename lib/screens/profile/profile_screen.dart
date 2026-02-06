import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/supabase_storage_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _selfPhoto;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickSelfPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() => _selfPhoto = File(photo.path));
        
        final storage = SupabaseStorageService();
        final userId = ref.read(authServiceProvider).currentUser?.id;
        if (userId == null) return;
        
        final imageUrl = await storage.uploadProfilePhoto(userId, File(photo.path));
        
        final currentProfile = ref.read(profileProvider).value;
        if (currentProfile != null) {
          await ref.read(authServiceProvider).updateProfile(
            currentProfile.copyWith(avatarUrl: imageUrl),
          );
          ref.invalidate(profileProvider);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo uploaded!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar with photo upload
              GestureDetector(
                onTap: _pickSelfPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(color: AppTheme.primary, width: 3),
                      ),
                      child: _selfPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(57),
                              child: Image.file(
                                _selfPhoto!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : profile?.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(57),
                                  child: Image.network(
                                    profile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    profile?.fullName?.isNotEmpty == true
                                        ? profile!.fullName![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 48, color: Colors.white),
                                  ),
                                ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(profile?.fullName ?? 'User', style: Theme.of(context).textTheme.headlineMedium),
              Text(profile?.email ?? '', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              
              // Subscription badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPremium ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPremium ? '⭐ Pro Member' : 'Free Plan',
                  style: TextStyle(color: isPremium ? Colors.white : AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Daily Calorie Target', '${profile?.dailyCalorieTarget ?? 2000} kcal'),
                    _buildStatRow('Protein Target', '${profile?.proteinTargetG ?? 60}g'),
                    _buildStatRow('Carbs Target', '${profile?.carbsTargetG ?? 250}g'),
                    _buildStatRow('Fat Target', '${profile?.fatTargetG ?? 65}g'),
                    _buildStatRow('Goal', _formatGoal(profile?.goal ?? 'maintain')),
                    _buildStatRow('Activity Level', _formatActivity(profile?.activityLevel ?? 'moderate')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu items
              _buildMenuItem(context, Icons.edit, 'Edit Profile', () => context.push('/edit-profile')),
              _buildMenuItem(context, Icons.analytics, 'Reports', () => context.push('/reports')),
              _buildMenuItem(context, Icons.star, isPremium ? 'Manage Subscription' : 'Upgrade to Pro', () => context.push('/premium')),
              _buildMenuItem(context, Icons.help, 'Help & Support', () => context.push('/help-support')),
              _buildMenuItem(context, Icons.policy, 'Privacy Policy', () => context.push('/privacy-policy')),
              _buildMenuItem(context, Icons.description, 'Terms of Service', () => _openTermsOfService()),
              const SizedBox(height: 24),

              // Sign Out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.error),
                  label: const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'lose': return 'Lose Weight';
      case 'gain': return 'Gain Weight';
      default: return 'Maintain';
    }
  }

  String _formatActivity(String activity) {
    switch (activity) {
      case 'sedentary': return 'Sedentary';
      case 'light': return 'Light Activity';
      case 'moderate': return 'Moderate';
      case 'active': return 'Active';
      case 'very_active': return 'Very Active';
      default: return 'Moderate';
    }
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _openTermsOfService() async {
    final Uri url = Uri.parse('https://cocal.visionquantech.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
