import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class PackagedFoodScreen extends ConsumerStatefulWidget {
  const PackagedFoodScreen({super.key});

  @override
  ConsumerState<PackagedFoodScreen> createState() => _PackagedFoodScreenState();
}

class _PackagedFoodScreenState extends ConsumerState<PackagedFoodScreen> {
  Uint8List? _labelImageBytes;
  XFile? _pickedFile;
  final _formKey = GlobalKey<FormState>();

  // Nutrition per 100g
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _sodiumController = TextEditingController();

  double _servingSize = 100; // grams consumed
  MealType _mealType = MealType.snacks;
  bool _isUltraProcessed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _labelImageBytes = bytes;
      });
    }
  }

  double get _calculatedCalories {
    final per100 = double.tryParse(_caloriesController.text) ?? 0;
    return per100 * _servingSize / 100;
  }

  double get _calculatedProtein {
    final per100 = double.tryParse(_proteinController.text) ?? 0;
    return per100 * _servingSize / 100;
  }

  double get _calculatedCarbs {
    final per100 = double.tryParse(_carbsController.text) ?? 0;
    return per100 * _servingSize / 100;
  }

  double get _calculatedFat {
    final per100 = double.tryParse(_fatController.text) ?? 0;
    return per100 * _servingSize / 100;
  }

  double get _calculatedSugar {
    final per100 = double.tryParse(_sugarController.text) ?? 0;
    return per100 * _servingSize / 100;
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      String? labelUrl;
      if (_labelImageBytes != null && _pickedFile != null) {
        final ext = _pickedFile!.name.split('.').last;
        labelUrl = await ref.read(foodServiceProvider).uploadFoodPhoto(
          _labelImageBytes!,
          ext,
          isLabel: true,
        );
      }

      final log = FoodLog(
        id: '',
        userId: userId,
        foodName: _nameController.text.isEmpty ? 'Packaged Food' : _nameController.text,
        mealType: _mealType,
        quantityG: _servingSize,
        calories: _calculatedCalories.round(),
        proteinG: _calculatedProtein,
        carbsG: _calculatedCarbs,
        fatG: _calculatedFat,
        sugarG: _calculatedSugar,
        isPackaged: true,
        isUltraProcessed: _isUltraProcessed,
        labelPhotoUrl: labelUrl,
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await ref.read(foodServiceProvider).addFoodLog(log);
      ref.invalidate(todayFoodLogsProvider);
      ref.invalidate(todaySummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${_calculatedCalories.round()} kcal')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packaged Food')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Capture
              Text('Step 1: Capture Nutrition Label', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: _labelImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_labelImageBytes!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 48, color: AppTheme.primary),
                            const SizedBox(height: 8),
                            Text('Tap to capture label', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Nutrition Info Form
              Text('Step 2: Enter Nutrition (per 100g)', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Copy values from the nutrition table on the package', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField(_nameController, 'Food Name', optional: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_brandController, 'Brand', optional: true)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField(_caloriesController, 'Calories *', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_proteinController, 'Protein (g)', isNumber: true, optional: true)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField(_carbsController, 'Carbs (g)', isNumber: true, optional: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_fatController, 'Fat (g)', isNumber: true, optional: true)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField(_sugarController, 'Sugar (g)', isNumber: true, optional: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_sodiumController, 'Sodium (mg)', isNumber: true, optional: true)),
                ],
              ),
              const SizedBox(height: 24),

              // Serving Size Slider
              Text('Step 3: How much did you eat?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              Text('${_servingSize.round()}g', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Slider(
                value: _servingSize,
                min: 10,
                max: 500,
                divisions: 49,
                onChanged: (v) => setState(() => _servingSize = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickServing('25g', 25),
                  _buildQuickServing('50g', 50),
                  _buildQuickServing('100g', 100),
                  _buildQuickServing('150g', 150),
                  _buildQuickServing('200g', 200),
                ],
              ),
              const SizedBox(height: 24),

              // Calculated Values Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('You\'re adding:', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Text('${_calculatedCalories.round()} kcal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMacroPreview('P', _calculatedProtein, AppTheme.success),
                        _buildMacroPreview('C', _calculatedCarbs, AppTheme.accent),
                        _buildMacroPreview('F', _calculatedFat, AppTheme.error),
                        if (_calculatedSugar > 0)
                          _buildMacroPreview('S', _calculatedSugar, Colors.pink),
                      ],
                    ),
                  ],
                ),
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
                      selected: _mealType == m,
                      onSelected: (_) => setState(() => _mealType = m),
                      selectedColor: AppTheme.primary,
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Ultra Processed Toggle
              SwitchListTile(
                title: const Text('Ultra-Processed Food'),
                subtitle: Text('Chips, cookies, instant noodles, etc.', style: TextStyle(color: AppTheme.textSecondary)),
                value: _isUltraProcessed,
                onChanged: (v) => setState(() => _isUltraProcessed = v),
                activeColor: AppTheme.warning,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFood,
                  child: _isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('Add to Log', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool optional = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label),
      validator: optional ? null : (v) => v?.isEmpty == true ? 'Required' : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildQuickServing(String label, double value) {
    final isSelected = _servingSize == value;
    return InkWell(
      onTap: () => setState(() => _servingSize = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildMacroPreview(String label, double value, Color color) {
    return Column(
      children: [
        Text('${value.round()}g', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}
