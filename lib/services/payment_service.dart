import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Payment result model for structured callbacks
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;
  final int? errorCode;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
    this.errorCode,
  });
}

/// Enhanced payment service with proper error handling and verification support
class PaymentService {
  late Razorpay _razorpay;
  Function(PaymentResult)? _onResult;
  bool _isCheckoutOpen = false;

  // Razorpay key - ideally should come from environment
  static const String _keyId = 'rzp_live_RsWuyPx9Re47op';

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Initialize with a unified result callback
  void initialize({Function(PaymentResult)? onResult}) {
    _onResult = onResult;
  }

  /// Legacy initialize for backward compatibility
  void initializeLegacy({
    Function(String)? onSuccess, 
    Function(String)? onError,
  }) {
    _onResult = (result) {
      if (result.success) {
        onSuccess?.call(result.paymentId ?? '');
      } else {
        onError?.call(result.errorMessage ?? 'Payment failed');
      }
    };
  }

  /// Check if checkout is currently open
  bool get isCheckoutOpen => _isCheckoutOpen;

  /// Open Razorpay checkout
  void openCheckout({
    required int amount,
    required String name,
    required String description,
    required String email,
    required String contact,
    String? orderId,
    String? customerId,
    Map<String, dynamic>? notes,
    int? timeout, // in seconds
  }) {
    if (_isCheckoutOpen) {
      debugPrint('Checkout already open, ignoring request');
      return;
    }

    // Validate inputs
    if (amount <= 0) {
      _onResult?.call(PaymentResult(
        success: false,
        errorMessage: 'Invalid amount: must be greater than 0',
        errorCode: -1,
      ));
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _onResult?.call(PaymentResult(
        success: false,
        errorMessage: 'Invalid email address',
        errorCode: -2,
      ));
      return;
    }

    var options = <String, dynamic>{
      'key': _keyId,
      'amount': amount, // Amount in paise
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe'],
      },
      'theme': {
        'color': '#00D9A5', // Match app theme
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
    };

    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    if (customerId != null && customerId.isNotEmpty) {
      options['customer_id'] = customerId;
    }

    if (notes != null && notes.isNotEmpty) {
      options['notes'] = notes;
    }

    if (timeout != null && timeout > 0) {
      options['timeout'] = timeout;
    }

    try {
      _isCheckoutOpen = true;
      _razorpay.open(options);
    } catch (e) {
      _isCheckoutOpen = false;
      debugPrint('Error opening checkout: $e');
      _onResult?.call(PaymentResult(
        success: false,
        errorMessage: 'Failed to open payment gateway: $e',
        errorCode: -3,
      ));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _isCheckoutOpen = false;
    debugPrint('Payment Success: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');
    
    _onResult?.call(PaymentResult(
      success: true,
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isCheckoutOpen = false;
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    
    String userMessage = _getUserFriendlyError(response.code, response.message);
    
    _onResult?.call(PaymentResult(
      success: false,
      errorMessage: userMessage,
      errorCode: response.code,
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet selected: ${response.walletName}');
    // External wallet flow continues, don't close checkout state yet
  }

  /// Convert Razorpay error codes to user-friendly messages
  String _getUserFriendlyError(int? code, String? message) {
    switch (code) {
      case 0:
        return 'Network error. Please check your internet connection.';
      case 1:
        return 'Payment was cancelled.';
      case 2:
        return 'Payment session timed out. Please try again.';
      case 3:
        return 'Payment method not supported.';
      case 4:
        return 'Bank server error. Please try a different payment method.';
      case 5:
        return 'Authentication failed. Please try again.';
      default:
        return message ?? 'Payment failed. Please try again.';
    }
  }

  /// Dispose and cleanup
  void dispose() {
    _razorpay.clear();
    _isCheckoutOpen = false;
  }
}
