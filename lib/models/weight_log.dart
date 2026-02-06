class WeightLog {
  final String id;
  final String userId;
  final double weightKg;
  final DateTime loggedAt;
  final String? notes;
  final DateTime createdAt;

  WeightLog({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedAt,
    this.notes,
    required this.createdAt,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
        id: json['id'],
        userId: json['user_id'],
        weightKg: (json['weight_kg'] ?? 0).toDouble(),
        loggedAt: DateTime.parse(json['logged_at']),
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'weight_kg': weightKg,
        'logged_at': loggedAt.toIso8601String().split('T')[0],
        'notes': notes,
      };
}
