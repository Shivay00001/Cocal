class DailySummary {
  final String id;
  final String userId;
  final DateTime logDate;
  final int totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalSugarG;
  final int packagedFoodCount;
  final int upfScore;
  final double? complianceScore;
  final int calorieTarget;
  final int proteinTarget;
  final bool eveningReviewDone;

  DailySummary({
    required this.id,
    required this.userId,
    required this.logDate,
    this.totalCalories = 0,
    this.totalProteinG = 0,
    this.totalCarbsG = 0,
    this.totalFatG = 0,
    this.totalSugarG = 0,
    this.packagedFoodCount = 0,
    this.upfScore = 0,
    this.complianceScore,
    this.calorieTarget = 2000,
    this.proteinTarget = 60,
    this.eveningReviewDone = false,
  });

  double get calorieProgress => (totalCalories / calorieTarget).clamp(0, 2);
  double get proteinProgress => (totalProteinG / proteinTarget).clamp(0, 2);
  double get proteinGap => (proteinTarget - totalProteinG).clamp(0, 200);

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        id: json['id'],
        userId: json['user_id'],
        logDate: DateTime.parse(json['log_date']),
        totalCalories: json['total_calories'] ?? 0,
        totalProteinG: (json['total_protein_g'] ?? 0).toDouble(),
        totalCarbsG: (json['total_carbs_g'] ?? 0).toDouble(),
        totalFatG: (json['total_fat_g'] ?? 0).toDouble(),
        totalSugarG: (json['total_sugar_g'] ?? 0).toDouble(),
        packagedFoodCount: json['packaged_food_count'] ?? 0,
        upfScore: json['upf_score'] ?? 0,
        complianceScore: json['compliance_score']?.toDouble(),
        calorieTarget: json['calorie_target'] ?? 2000,
        proteinTarget: json['protein_target'] ?? 60,
        eveningReviewDone: json['evening_review_done'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'log_date': logDate.toIso8601String().split('T')[0],
        'total_calories': totalCalories,
        'total_protein_g': totalProteinG,
        'total_carbs_g': totalCarbsG,
        'total_fat_g': totalFatG,
        'total_sugar_g': totalSugarG,
        'packaged_food_count': packagedFoodCount,
        'upf_score': upfScore,
        'compliance_score': complianceScore,
        'calorie_target': calorieTarget,
        'protein_target': proteinTarget,
        'evening_review_done': eveningReviewDone,
      };
}
