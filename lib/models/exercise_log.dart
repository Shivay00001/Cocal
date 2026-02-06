class ExerciseLog {
  final String id;
  final String userId;
  final String activityName;
  final int durationMinutes;
  final int caloriesBurned;
  final String intensity;
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  ExerciseLog({
    required this.id,
    required this.userId,
    required this.activityName,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.intensity = 'moderate',
    this.notes,
    required this.loggedAt,
    required this.createdAt,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
        id: json['id'],
        userId: json['user_id'],
        activityName: json['activity_name'],
        durationMinutes: json['duration_minutes'],
        caloriesBurned: json['calories_burned'],
        intensity: json['intensity'] ?? 'moderate',
        notes: json['notes'],
        loggedAt: DateTime.parse(json['logged_at']),
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'activity_name': activityName,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
        'intensity': intensity,
        'notes': notes,
        'logged_at': loggedAt.toIso8601String(),
      };
}
