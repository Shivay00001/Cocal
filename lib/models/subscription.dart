class Subscription {
  final String id;
  final String userId;
  final String planType;
  final String status;
  final String? paymentProvider;
  final String? providerSubscriptionId;
  final String? razorpayPaymentId;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? trialEndsAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    this.planType = 'free',
    this.status = 'active',
    this.paymentProvider,
    this.providerSubscriptionId,
    this.razorpayPaymentId,
    this.startedAt,
    this.expiresAt,
    this.trialEndsAt,
    this.cancelledAt,
    required this.createdAt,
  });

  bool get isPremium =>
      planType != 'free' && planType != 'trial' && status == 'active' && !isExpired;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isInTrial =>
      planType == 'trial' &&
      status == 'active' &&
      trialEndsAt != null &&
      trialEndsAt!.isAfter(DateTime.now());

  bool get isActive =>
      status == 'active' && (isPremium || isInTrial);

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'],
        userId: json['user_id'],
        planType: json['plan_type'] ?? 'free',
        status: json['status'] ?? 'active',
        paymentProvider: json['payment_provider'],
        providerSubscriptionId: json['razorpay_subscription_id'],
        razorpayPaymentId: json['razorpay_payment_id'],
        startedAt: json['current_period_start'] != null
            ? DateTime.parse(json['current_period_start'])
            : null,
        expiresAt: json['current_period_end'] != null
            ? DateTime.parse(json['current_period_end'])
            : null,
        trialEndsAt: json['premium_trial_ends_at'] != null
            ? DateTime.parse(json['premium_trial_ends_at'])
            : null,
        cancelledAt: json['cancelled_at'] != null
            ? DateTime.parse(json['cancelled_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'plan_type': planType,
        'status': status,
        'payment_provider': paymentProvider,
        'razorpay_subscription_id': providerSubscriptionId,
        'razorpay_payment_id': razorpayPaymentId,
        'current_period_start': startedAt?.toIso8601String(),
        'current_period_end': expiresAt?.toIso8601String(),
        'premium_trial_ends_at': trialEndsAt?.toIso8601String(),
        'cancelled_at': cancelledAt?.toIso8601String(),
      };
}
