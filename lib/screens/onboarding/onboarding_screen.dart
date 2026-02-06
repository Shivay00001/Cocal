import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form data
  String _fullName = '';
  String _gender = 'male';
  DateTime _dob = DateTime(1995, 1, 1);
  double _heightCm = 170;
  double _weightKg = 70;
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  double _targetWeight = 70;

  bool _isLoading = false;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    if (_fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
        }
        return;
      }

      final bmr = NutritionCalculator.calculateBMR(
        weightKg: _weightKg,
        heightCm: _heightCm,
        age: DateTime.now().year - _dob.year,
        gender: _gender,
      );
      final tdee = NutritionCalculator.calculateTDEE(bmr, _activityLevel);
      final calorieTarget = NutritionCalculator.calculateCalorieTarget(tdee, _goal);
      final macros = NutritionCalculator.calculateMacroTargets(
        calorieTarget: calorieTarget,
        goal: _goal,
        weightKg: _weightKg,
      );

      final profile = Profile(
        id: user.id,
        email: user.email!,
        fullName: _fullName,
        gender: _gender,
        dateOfBirth: _dob,
        heightCm: _heightCm,
        activityLevel: _activityLevel,
        goal: _goal,
        targetWeightKg: _targetWeight,
        dailyCalorieTarget: calorieTarget,
        proteinTargetG: macros.proteinG,
        carbsTargetG: macros.carbsG,
        fatTargetG: macros.fatG,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(authServiceProvider).createProfile(profile);

      try {
        await ref.read(subscriptionServiceProvider).getOrCreateTrialSubscription();
      } catch (e) {
        debugPrint('Trial subscription error (table may not exist): $e');
      }

      try {
        await ref.read(foodServiceProvider).addWeightLog(_weightKg);
      } catch (e) {
        debugPrint('Weight log error (table may not exist): $e');
      }

      if (mounted) context.go('/home');
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppTheme.primary
                            : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildBasicInfoPage(),
                  _buildBodyMetricsPage(),
                  _buildActivityPage(),
                  _buildGoalPage(),
                ],
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  child: _isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Text(_currentPage < 3 ? 'Continue' : 'Get Started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's get to know you", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          TextField(
            onChanged: (v) => _fullName = v,
            decoration: const InputDecoration(labelText: 'Your Name'),
          ),
          const SizedBox(height: 24),
          Text('Gender', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Row(
            children: ['male', 'female', 'other'].map((g) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(g[0].toUpperCase() + g.substring(1)),
                    selected: _gender == g,
                    onSelected: (_) => setState(() => _gender = g),
                    selectedColor: AppTheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Date of Birth', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dob,
                firstDate: DateTime(1940),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _dob = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 12),
                  Text('${_dob.day}/${_dob.month}/${_dob.year}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetricsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Body Metrics', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          Text('Height: ${_heightCm.round()} cm', style: Theme.of(context).textTheme.bodyLarge),
          Slider(
            value: _heightCm,
            min: 120,
            max: 220,
            divisions: 100,
            onChanged: (v) => setState(() => _heightCm = v),
          ),
          const SizedBox(height: 24),
          Text('Current Weight: ${_weightKg.round()} kg', style: Theme.of(context).textTheme.bodyLarge),
          Slider(
            value: _weightKg,
            min: 30,
            max: 200,
            divisions: 170,
            onChanged: (v) => setState(() {
              _weightKg = v;
              if (_goal == 'maintain') _targetWeight = v;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    final levels = {
      'sedentary': 'Desk job, little exercise',
      'light': 'Light exercise 1-3 days/week',
      'moderate': 'Moderate exercise 3-5 days/week',
      'active': 'Hard exercise 6-7 days/week',
      'very_active': 'Athlete / Physical job',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Level', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('How active are you on a typical week?', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...levels.entries.map((e) => _buildActivityOption(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildActivityOption(String key, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _activityLevel = key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _activityLevel == key ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _activityLevel == key ? AppTheme.primary : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: key,
                groupValue: _activityLevel,
                onChanged: (v) => setState(() => _activityLevel = v!),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(desc)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Goal', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          _buildGoalCard('lose', 'Lose Weight', Icons.trending_down, 'Healthy calorie deficit for sustainable fat loss'),
          _buildGoalCard('maintain', 'Maintain Weight', Icons.balance, 'Keep your current weight with balanced nutrition'),
          _buildGoalCard('gain', 'Build Muscle', Icons.trending_up, 'Calorie surplus for muscle building'),
          if (_goal != 'maintain') ...[
            const SizedBox(height: 24),
            Text('Target Weight: ${_targetWeight.round()} kg', style: Theme.of(context).textTheme.bodyLarge),
            Slider(
              value: _targetWeight,
              min: 30,
              max: 200,
              divisions: 170,
              onChanged: (v) => setState(() => _targetWeight = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalCard(String key, String title, IconData icon, String desc) {
    final isSelected = _goal == key;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() {
          _goal = key;
          if (key == 'maintain') _targetWeight = _weightKg;
        }),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: isSelected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white70 : AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
