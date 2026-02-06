class Streak {
  final String id;
  final String userId;
  final String type;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCompletedDate;
  final DateTime createdAt;

  Streak({
    required this.id,
    required this.userId,
    required this.type,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    required this.createdAt,
  });

  factory Streak.fromJson(Map<String, dynamic> json) => Streak(
        id: json['id'],
        userId: json['user_id'],
        type: json['type'],
        currentStreak: json['current_streak'] ?? 0,
        longestStreak: json['longest_streak'] ?? 0,
        lastCompletedDate: DateTime.parse(json['last_completed_date']),
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'type': type,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_completed_date': lastCompletedDate.toIso8601String().split('T')[0],
      };
}

class Competitor {
  final String id;
  final String userId;
  final String competitorUserId;
  final String competitorName;
  final String competitorAvatar;
  final int userScore;
  final int competitorScore;
  final String challengeType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  Competitor({
    required this.id,
    required this.userId,
    required this.competitorUserId,
    required this.competitorName,
    required this.competitorAvatar,
    required this.userScore,
    required this.competitorScore,
    required this.challengeType,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Competitor.fromJson(Map<String, dynamic> json) => Competitor(
        id: json['id'],
        userId: json['user_id'],
        competitorUserId: json['competitor_user_id'],
        competitorName: json['competitor_name'] ?? 'Unknown',
        competitorAvatar: json['competitor_avatar'] ?? '',
        userScore: json['user_score'] ?? 0,
        competitorScore: json['competitor_score'] ?? 0,
        challengeType: json['challenge_type'] ?? 'calories',
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
        status: json['status'] ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'competitor_user_id': competitorUserId,
        'competitor_name': competitorName,
        'competitor_avatar': competitorAvatar,
        'user_score': userScore,
        'competitor_score': competitorScore,
        'challenge_type': challengeType,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'status': status,
      };
}
