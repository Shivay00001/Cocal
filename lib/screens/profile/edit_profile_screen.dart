import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _heightController;
  late final TextEditingController _targetWeightController;
  
  String _goal = 'maintain';
  String _activityLevel = 'moderate';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _heightController = TextEditingController(
      text: profile?.heightCm?.toString() ?? '',
    );
    _targetWeightController = TextEditingController(
      text: profile?.targetWeightKg?.toString() ?? '',
    );
    _goal = profile?.goal ?? 'maintain';
    _activityLevel = profile?.activityLevel ?? 'moderate';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      prefixIcon: Icon(Icons.height),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      final height = double.tryParse(value);
                      if (height == null || height < 50 || height > 300) {
                        return 'Enter a valid height (50-300 cm)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _targetWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Target Weight (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 20 || weight > 500) {
                        return 'Enter a valid weight (20-500 kg)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Fitness Goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildGoalSelector(),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Activity Level',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildActivityLevelSelector(),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Widget _buildGoalSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildGoalOption('lose', 'Lose Weight', Icons.trending_down),
          Divider(height: 1, color: Colors.grey.shade300),
          _buildGoalOption('maintain', 'Maintain Weight', Icons.trending_flat),
          Divider(height: 1, color: Colors.grey.shade300),
          _buildGoalOption('gain', 'Gain Weight', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String value, String label, IconData icon) {
    final isSelected = _goal == value;
    return InkWell(
      onTap: () => setState(() => _goal = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelSelector() {
    final activities = [
      {'value': 'sedentary', 'label': 'Sedentary', 'desc': 'Little to no exercise'},
      {'value': 'light', 'label': 'Light Activity', 'desc': 'Light exercise 1-3 days/week'},
      {'value': 'moderate', 'label': 'Moderate', 'desc': 'Moderate exercise 3-5 days/week'},
      {'value': 'active', 'label': 'Active', 'desc': 'Hard exercise 6-7 days/week'},
      {'value': 'very_active', 'label': 'Very Active', 'desc': 'Very hard exercise & physical job'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isSelected = _activityLevel == activity['value'];
          return Column(
            children: [
              if (index > 0) Divider(height: 1, color: Colors.grey.shade300),
              InkWell(
                onTap: () => setState(() => _activityLevel = activity['value']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['label'] as String,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              activity['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final currentProfile = ref.read(profileProvider).value;
      if (currentProfile == null) return;

      final updatedProfile = currentProfile.copyWith(
        fullName: _fullNameController.text.trim(),
        heightCm: double.tryParse(_heightController.text),
        targetWeightKg: double.tryParse(_targetWeightController.text),
        goal: _goal,
        activityLevel: _activityLevel,
      );

      await ref.read(authServiceProvider).updateProfile(updatedProfile);
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }
}
