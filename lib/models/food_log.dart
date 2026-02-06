enum MealType { breakfast, lunch, snacks, dinner }

class FoodLog {
  final String id;
  final String userId;
  final String? foodItemId;
  final String foodName;
  final String? brandName;
  final MealType mealType;
  final double quantityG;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double sugarG;
  final bool isPackaged;
  final bool isUltraProcessed;
  final String? photoUrl;
  final String? labelPhotoUrl;
  final String? healthinessPhotoUrl;
  final DateTime loggedAt;
  final DateTime createdAt;

  FoodLog({
    required this.id,
    required this.userId,
    this.foodItemId,
    required this.foodName,
    this.brandName,
    required this.mealType,
    required this.quantityG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.sugarG = 0,
    this.isPackaged = false,
    this.isUltraProcessed = false,
    this.photoUrl,
    this.labelPhotoUrl,
    this.healthinessPhotoUrl,
    required this.loggedAt,
    required this.createdAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) => FoodLog(
        id: json['id'],
        userId: json['user_id'],
        foodItemId: json['food_item_id'],
        foodName: json['food_name'] ?? 'Unknown',
        brandName: json['brand_name'],
        mealType: MealType.values.firstWhere(
          (e) => e.name == json['meal_type'],
          orElse: () => MealType.snacks,
        ),
        quantityG: (json['quantity_g'] ?? 0).toDouble(),
        calories: json['calories'] ?? 0,
        proteinG: (json['protein_g'] ?? 0).toDouble(),
        carbsG: (json['carbs_g'] ?? 0).toDouble(),
        fatG: (json['fat_g'] ?? 0).toDouble(),
        sugarG: (json['sugar_g'] ?? 0).toDouble(),
        isPackaged: json['is_packaged'] ?? false,
        isUltraProcessed: json['is_ultra_processed'] ?? false,
        photoUrl: json['photo_url'],
        labelPhotoUrl: json['label_photo_url'],
        healthinessPhotoUrl: json['healthiness_photo_url'],
        loggedAt: DateTime.parse(json['logged_at']),
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'food_item_id': foodItemId,
        'food_name': foodName,
        'brand_name': brandName,
        'meal_type': mealType.name,
        'quantity_g': quantityG,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'sugar_g': sugarG,
        'is_packaged': isPackaged,
        'is_ultra_processed': isUltraProcessed,
        'photo_url': photoUrl,
        'label_photo_url': labelPhotoUrl,
        'healthiness_photo_url': healthinessPhotoUrl,
        'logged_at': loggedAt.toIso8601String().split('T')[0],
      };
}
