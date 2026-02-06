import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/payment_service.dart';
import '../../services/subscription_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isProcessing = false;
  String? _selectedPlan;

  void _handlePaymentResult(PaymentResult result) {
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      _activateSubscription(result.paymentId ?? '');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Payment failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _activateSubscription(String paymentId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Activating your subscription...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ref.read(subscriptionServiceProvider).activatePremium(
        paymentId: paymentId,
        subscriptionId: '',
        planType: _selectedPlan ?? 'monthly',
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ref.invalidate(subscriptionProvider);
      ref.invalidate(isPremiumProvider);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Welcome to Pro!'),
          content: const Text('Your premium subscription is now active.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activation failed: $e')),
      );
    }
  }

  void _handlePayment(String plan, int amount) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _selectedPlan = plan;
    });

    ref.read(paymentServiceProvider).initialize(
      onResult: _handlePaymentResult,
    );

    ref.read(paymentServiceProvider).openCheckout(
      amount: amount,
      name: 'CoCal Pro',
      description: '$plan subscription',
      email: ref.read(currentUserProvider)?.email ?? '',
      contact: '',
    );
  }

  int _getPlanAmount(String plan) {
    switch (plan) {
      case 'monthly':
        return 14900;
      case 'yearly':
        return 99900;
      case 'lifetime':
        return 199900;
      default:
        return 14900;
    }
  }

  String _getPlanInterval(String plan) {
    switch (plan) {
      case 'monthly':
        return '/month';
      case 'yearly':
        return '/year';
      case 'lifetime':
        return 'once';
      default:
        return '/month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Pro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Unlock Full Potential',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get access to all premium features',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFeature(Icons.analytics, 'Weekly PDF Reports', 'Detailed progress analysis'),
            _buildFeature(Icons.auto_graph, 'Adaptive Engine', 'AI-powered recommendations'),
            _buildFeature(Icons.trending_up, 'Weight Trends', 'Visual progress tracking'),
            _buildFeature(Icons.lock_open, 'Everything Unlocked', 'No limits'),
            const SizedBox(height: 24),
            _buildPlanCard('Monthly', '149', true, false),
            const SizedBox(height: 12),
            _buildPlanCard('Yearly', '999', false, true),
            const SizedBox(height: 12),
            _buildPlanCard('Lifetime', '1999', false, false),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, bool isPopular, bool isBest) {
    final isSelected = _selectedPlan == name.toLowerCase();

    return GestureDetector(
      onTap: _isProcessing ? null : () => _handlePayment(name.toLowerCase(), _getPlanAmount(name.toLowerCase())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPopular ? AppTheme.primaryGradient : null,
          color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : (isBest ? AppTheme.success : Colors.transparent),
            width: isBest ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPopular ? Colors.white : AppTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPopular ? AppTheme.primary : Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$price',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
                Text(
                  _getPlanInterval(name.toLowerCase()),
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
