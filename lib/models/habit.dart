class Habit {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final int targetDaysPerWeek;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.targetDaysPerWeek = 7,
    required this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDaysPerWeek: json['target_days_per_week'] as int? ?? 7,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'target_days_per_week': targetDaysPerWeek,
      // created_at is handled by DB defaults usually, but for local creation we might need logic
    };
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date;
  final bool completed;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    this.completed = true,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['log_date'] as String),
      completed: json['completed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habit_id': habitId,
      'user_id': userId,
      'log_date': date.toIso8601String().split('T')[0],
      'completed': completed,
    };
  }
}
