class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? currentWeightKg;
  final double? bodyFatPercentage;
  final String? muscleRating;
  final String activityLevel;
  final String goal;
  final double? targetWeightKg;
  final int dailyCalorieTarget;
  final int proteinTargetG;
  final int carbsTargetG;
  final int fatTargetG;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.currentWeightKg,
    this.bodyFatPercentage,
    this.muscleRating,
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
    this.targetWeightKg,
    this.dailyCalorieTarget = 2000,
    this.proteinTargetG = 60,
    this.carbsTargetG = 250,
    this.fatTargetG = 65,
    required this.createdAt,
    required this.updatedAt,
  });

  int get age {
    if (dateOfBirth == null) return 25;
    return DateTime.now().year - dateOfBirth!.year;
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'],
        email: json['email'],
        fullName: json['full_name'],
        avatarUrl: json['avatar_url'],
        gender: json['gender'],
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.parse(json['date_of_birth'])
            : null,
        heightCm: json['height_cm']?.toDouble(),
        currentWeightKg: json['current_weight_kg']?.toDouble(),
        bodyFatPercentage: json['body_fat_percentage']?.toDouble(),
        muscleRating: json['muscle_rating'],
        activityLevel: json['activity_level'] ?? 'moderate',
        goal: json['goal'] ?? 'maintain',
        targetWeightKg: json['target_weight_kg']?.toDouble(),
        dailyCalorieTarget: json['daily_calorie_target'] ?? 2000,
        proteinTargetG: json['protein_target_g'] ?? 60,
        carbsTargetG: json['carbs_target_g'] ?? 250,
        fatTargetG: json['fat_target_g'] ?? 65,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'gender': gender,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
        'height_cm': heightCm,
        'current_weight_kg': currentWeightKg,
        'body_fat_percentage': bodyFatPercentage,
        'muscle_rating': muscleRating,
        'activity_level': activityLevel,
        'goal': goal,
        'target_weight_kg': targetWeightKg,
        'daily_calorie_target': dailyCalorieTarget,
        'protein_target_g': proteinTargetG,
        'carbs_target_g': carbsTargetG,
        'fat_target_g': fatTargetG,
      };

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    double? heightCm,
    double? currentWeightKg,
    double? bodyFatPercentage,
    String? muscleRating,
    String? activityLevel,
    String? goal,
    double? targetWeightKg,
    int? dailyCalorieTarget,
    int? proteinTargetG,
    int? carbsTargetG,
    int? fatTargetG,
  }) =>
      Profile(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        heightCm: heightCm ?? this.heightCm,
        currentWeightKg: currentWeightKg ?? this.currentWeightKg,
        bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
        muscleRating: muscleRating ?? this.muscleRating,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
        proteinTargetG: proteinTargetG ?? this.proteinTargetG,
        carbsTargetG: carbsTargetG ?? this.carbsTargetG,
        fatTargetG: fatTargetG ?? this.fatTargetG,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
