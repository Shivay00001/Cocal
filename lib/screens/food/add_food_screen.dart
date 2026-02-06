import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class AddFoodScreen extends ConsumerWidget {
  const AddFoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What did you eat?', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            
            // Packaged Food (USP)
            _buildFoodTypeCard(
              context,
              icon: Icons.qr_code_scanner,
              title: 'Packaged Food 📦',
              subtitle: 'Scan nutrition label from package',
              color: AppTheme.primary,
              onTap: () => context.push('/add-food/packaged'),
              isPrimary: true,
            ),
            const SizedBox(height: 12),

            // Home Cooked
            _buildFoodTypeCard(
              context,
              icon: Icons.home,
              title: 'Home Cooked',
              subtitle: 'Meals prepared at home',
              color: AppTheme.success,
              onTap: () => _showQuickAddSheet(context, ref, 'home'),
            ),
            const SizedBox(height: 12),

            // Restaurant
            _buildFoodTypeCard(
              context,
              icon: Icons.restaurant,
              title: 'Restaurant / Outside',
              subtitle: 'Eating out or takeaway',
              color: AppTheme.accent,
              onTap: () => _showQuickAddSheet(context, ref, 'restaurant'),
            ),
            const SizedBox(height: 12),

            // Quick Add
            _buildFoodTypeCard(
              context,
              icon: Icons.flash_on,
              title: 'Quick Add Calories',
              subtitle: 'Just enter the number',
              color: AppTheme.textSecondary,
              onTap: () => _showQuickCalorieSheet(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isPrimary ? Colors.white : color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPrimary ? Colors.white70 : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isPrimary ? Colors.white : AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref, String type) {
    final foodController = TextEditingController();
    final portionController = TextEditingController(text: '1');
    MealType selectedMeal = MealType.lunch;

    // Quick food database
    final foods = type == 'home' ? [
      {'name': 'Rice (1 cup)', 'cal': 200, 'p': 4, 'c': 45, 'f': 0.5},
      {'name': 'Dal (1 bowl)', 'cal': 150, 'p': 9, 'c': 20, 'f': 3},
      {'name': 'Roti (1 piece)', 'cal': 80, 'p': 3, 'c': 15, 'f': 1},
      {'name': 'Sabzi (1 bowl)', 'cal': 100, 'p': 3, 'c': 12, 'f': 5},
      {'name': 'Egg (1 boiled)', 'cal': 78, 'p': 6, 'c': 0.5, 'f': 5},
      {'name': 'Chicken (100g)', 'cal': 165, 'p': 31, 'c': 0, 'f': 4},
    ] : [
      {'name': 'Burger', 'cal': 350, 'p': 15, 'c': 40, 'f': 15},
      {'name': 'Pizza (1 slice)', 'cal': 285, 'p': 12, 'c': 36, 'f': 10},
      {'name': 'Biryani (plate)', 'cal': 450, 'p': 18, 'c': 55, 'f': 18},
      {'name': 'Thali (full)', 'cal': 700, 'p': 20, 'c': 90, 'f': 25},
      {'name': 'Sandwich', 'cal': 300, 'p': 12, 'c': 35, 'f': 12},
      {'name': 'Momos (6 pcs)', 'cal': 250, 'p': 10, 'c': 30, 'f': 10},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'home' ? 'Home Cooked Food' : 'Restaurant Food',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              
              // Meal Type
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MealType.values.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                      selected: selectedMeal == m,
                      onSelected: (_) => setState(() => selectedMeal = m),
                      selectedColor: AppTheme.primary,
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Quick picks
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: foods.map((f) => ActionChip(
                  label: Text('${f['name']} (${f['cal']} cal)'),
                  onPressed: () async {
                    await _logFood(
                      ref,
                      name: f['name'] as String,
                      calories: f['cal'] as int,
                      protein: (f['p'] as num).toDouble(),
                      carbs: (f['c'] as num).toDouble(),
                      fat: (f['f'] as num).toDouble(),
                      mealType: selectedMeal,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${f['name']}')),
                      );
                    }
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickCalorieSheet(BuildContext context, WidgetRef ref) {
    final calorieController = TextEditingController();
    final nameController = TextEditingController();
    MealType selectedMeal = MealType.snacks;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Add Calories', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Food name (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: calorieController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories', suffixText: 'kcal'),
              ),
              const SizedBox(height: 16),
              Row(
                children: MealType.values.map((m) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                    selected: selectedMeal == m,
                    onSelected: (_) => setState(() => selectedMeal = m),
                    selectedColor: AppTheme.primary,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final cal = int.tryParse(calorieController.text) ?? 0;
                    if (cal > 0) {
                      await _logFood(
                        ref,
                        name: nameController.text.isEmpty ? 'Quick add' : nameController.text,
                        calories: cal,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                        mealType: selectedMeal,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added $cal kcal')),
                        );
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logFood(
    WidgetRef ref, {
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required MealType mealType,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final log = FoodLog(
      id: '',
      userId: userId,
      foodName: name,
      mealType: mealType,
      quantityG: 100,
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      loggedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await ref.read(foodServiceProvider).addFoodLog(log);
    ref.invalidate(todayFoodLogsProvider);
    ref.invalidate(todaySummaryProvider);
  }
}
