class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;
  final double? fiberPer100g;
  final bool isPackaged;
  final bool isUltraProcessed;
  final bool isVerified;
  final String? createdBy;
  final DateTime createdAt;

  FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
    this.fiberPer100g,
    this.isPackaged = false,
    this.isUltraProcessed = false,
    this.isVerified = false,
    this.createdBy,
    required this.createdAt,
  });

  // Calculate macros for a given quantity
  NutritionInfo calculateForQuantity(double quantityG) {
    final factor = quantityG / 100;
    return NutritionInfo(
      calories: (caloriesPer100g * factor).round(),
      protein: proteinPer100g * factor,
      carbs: carbsPer100g * factor,
      fat: fatPer100g * factor,
      sugar: (sugarPer100g ?? 0) * factor,
      sodium: (sodiumPer100g ?? 0) * factor,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'],
        name: json['name'],
        brand: json['brand'],
        category: json['category'],
        caloriesPer100g: json['calories_per_100g'] ?? 0,
        proteinPer100g: (json['protein_per_100g'] ?? 0).toDouble(),
        carbsPer100g: (json['carbs_per_100g'] ?? 0).toDouble(),
        fatPer100g: (json['fat_per_100g'] ?? 0).toDouble(),
        sugarPer100g: json['sugar_per_100g']?.toDouble(),
        sodiumPer100g: json['sodium_per_100g']?.toDouble(),
        fiberPer100g: json['fiber_per_100g']?.toDouble(),
        isPackaged: json['is_packaged'] ?? false,
        isUltraProcessed: json['is_ultra_processed'] ?? false,
        isVerified: json['is_verified'] ?? false,
        createdBy: json['created_by'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'category': category,
        'calories_per_100g': caloriesPer100g,
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fat_per_100g': fatPer100g,
        'sugar_per_100g': sugarPer100g,
        'sodium_per_100g': sodiumPer100g,
        'fiber_per_100g': fiberPer100g,
        'is_packaged': isPackaged,
        'is_ultra_processed': isUltraProcessed,
      };
}

class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double sodium;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar = 0,
    this.sodium = 0,
  });
}
