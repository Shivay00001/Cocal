import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

/// Result of a subscription operation
class SubscriptionResult {
  final bool success;
  final Subscription? subscription;
  final String? errorMessage;

  SubscriptionResult({
    required this.success,
    this.subscription,
    this.errorMessage,
  });
}

class SubscriptionService {
  final SupabaseClient _client = SupabaseConfig.client;

  String? get _userId => _client.auth.currentUser?.id;

  static const int trialDays = 3;

  /// Safely get user ID with error handling
  String _requireUserId() {
    final id = _userId;
    if (id == null) {
      throw Exception('User not authenticated');
    }
    return id;
  }

  /// Get current active subscription
  Future<Subscription?> getCurrentSubscription() async {
    try {
      final userId = _requireUserId();
      
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      return null;
    }
  }

  bool isPremium(Subscription? sub) {
    if (sub == null) return false;
    return sub.isPremium;
  }

  bool isInTrial(Subscription? sub) {
    if (sub == null) return false;
    return sub.isInTrial;
  }

  bool hasActiveSubscription(Subscription? sub) {
    if (sub == null) return false;
    return sub.status == 'active' && (sub.isPremium || sub.isInTrial);
  }

  DateTime? getTrialEndDate(Subscription? sub) {
    if (sub == null) return null;
    return sub.trialEndsAt;
  }

  bool isTrialExpired(Subscription? sub) {
    if (sub == null || sub.trialEndsAt == null) return true;
    return DateTime.now().isAfter(sub.trialEndsAt!);
  }

  int getRemainingTrialDays(Subscription? sub) {
    if (sub == null || sub.trialEndsAt == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(sub.trialEndsAt!)) return 0;
    return sub.trialEndsAt!.difference(now).inDays + 1;
  }

  bool isFeatureAvailable(Subscription? sub, PremiumFeature feature) {
    if (hasActiveSubscription(sub)) return true;

    // Free features available to all users
    switch (feature) {
      case PremiumFeature.unlimitedFoodLogs:
        return true;
      case PremiumFeature.eveningReview:
        return true;
      case PremiumFeature.hiddenSugarAlerts:
        return true;
      case PremiumFeature.upfTracking:
        return true;
      // Premium-only features
      case PremiumFeature.weeklyReports:
      case PremiumFeature.adaptiveEngine:
      case PremiumFeature.exportPdf:
        return false;
    }
  }

  /// Create trial subscription for new users
  Future<SubscriptionResult> getOrCreateTrialSubscription() async {
    try {
      final userId = _requireUserId();
      
      // Check existing subscription first
      final existing = await getCurrentSubscription();
      if (existing != null) {
        return SubscriptionResult(success: true, subscription: existing);
      }

      final now = DateTime.now();
      final trialEndsAt = now.add(const Duration(days: trialDays));

      // Create trial subscription
      final response = await _client.from('subscriptions').insert({
        'user_id': userId,
        'plan_type': 'trial',
        'status': 'active',
        'current_period_start': now.toIso8601String(),
        'current_period_end': trialEndsAt.toIso8601String(),
      }).select().single();

      // Update profile
      await _client.from('profiles').update({
        'is_premium': true,
        'premium_trial_ends_at': trialEndsAt.toIso8601String(),
      }).eq('id', userId);

      return SubscriptionResult(
        success: true, 
        subscription: Subscription.fromJson(response),
      );
    } catch (e) {
      debugPrint('Error creating trial subscription: $e');
      return SubscriptionResult(
        success: false,
        errorMessage: 'Failed to create trial: $e',
      );
    }
  }

  /// Activate premium subscription after successful payment
  Future<SubscriptionResult> activatePremium({
    required String paymentId,
    String? subscriptionId,
    String? orderId,
    String? signature,
    required String planType,
  }) async {
    try {
      final userId = _requireUserId();
      
      // Determine subscription duration based on plan
      int months;
      switch (planType) {
        case 'yearly':
          months = 12;
          break;
        case 'lifetime':
          months = 1200; // ~100 years
          break;
        case 'monthly':
        default:
          months = 1;
          break;
      }

      final now = DateTime.now();
      final periodEnd = now.add(Duration(days: 30 * months));

      // Cancel any existing trial/subscriptions first
      await _client.from('subscriptions')
          .update({
            'status': 'superseded',
            'cancelled_at': now.toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('status', 'active');

      // Create new premium subscription
      final response = await _client.from('subscriptions').insert({
        'user_id': userId,
        'razorpay_subscription_id': subscriptionId ?? 'payment_$paymentId',
        'razorpay_payment_id': paymentId,
        'plan_type': planType,
        'status': 'active',
        'current_period_start': now.toIso8601String(),
        'current_period_end': periodEnd.toIso8601String(),
      }).select().single();

      // Update profile to premium
      await _client.from('profiles').update({
        'is_premium': true,
        'premium_expires_at': periodEnd.toIso8601String(),
        'premium_trial_ends_at': null, // Clear trial if any
      }).eq('id', userId);

      return SubscriptionResult(
        success: true,
        subscription: Subscription.fromJson(response),
      );
    } catch (e) {
      debugPrint('Error activating premium: $e');
      return SubscriptionResult(
        success: false,
        errorMessage: 'Failed to activate subscription: $e',
      );
    }
  }

  /// Cancel active subscription
  Future<SubscriptionResult> cancelSubscription() async {
    try {
      final userId = _requireUserId();
      final now = DateTime.now();

      await _client.from('subscriptions').update({
        'status': 'cancelled',
        'cancelled_at': now.toIso8601String(),
      }).eq('user_id', userId).eq('status', 'active');

      await _client.from('profiles').update({
        'is_premium': false,
        'premium_trial_ends_at': null,
        'premium_expires_at': null,
      }).eq('id', userId);

      return SubscriptionResult(success: true);
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      return SubscriptionResult(
        success: false,
        errorMessage: 'Failed to cancel subscription: $e',
      );
    }
  }

  /// Check and handle expired subscriptions
  Future<void> checkAndUpdateExpiredSubscriptions() async {
    try {
      final userId = _requireUserId();
      final sub = await getCurrentSubscription();
      
      if (sub == null) return;

      final now = DateTime.now();
      bool isExpired = false;

      // Check trial expiry
      if (sub.planType == 'trial' && sub.trialEndsAt != null) {
        isExpired = now.isAfter(sub.trialEndsAt!);
      }
      
      // Check regular subscription expiry
      if (sub.expiresAt != null) {
        isExpired = isExpired || now.isAfter(sub.expiresAt!);
      }

      if (isExpired) {
        await _client.from('subscriptions').update({
          'status': 'expired',
        }).eq('id', sub.id);

        await _client.from('profiles').update({
          'is_premium': false,
        }).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error checking expired subscriptions: $e');
    }
  }
}

enum PremiumFeature {
  unlimitedFoodLogs,
  weeklyReports,
  adaptiveEngine,
  eveningReview,
  exportPdf,
  hiddenSugarAlerts,
  upfTracking,
}
