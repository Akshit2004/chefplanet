import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static const String _keyId = 'rzp_test_SM26m0AHww7fmV';
  
  late Razorpay _razorpay;
  
  // Callbacks stored so listeners registered once can route to the right handler
  Function(Map<String, dynamic>)? _onSuccess;
  Function(String)? _onError;
  
  RazorpayService() {
    _razorpay = Razorpay();
    // Register listeners ONCE in constructor
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call({
      'razorpay_payment_id': response.paymentId ?? '',
      'razorpay_order_id': response.orderId ?? '',
      'razorpay_signature': response.signature ?? '',
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onError?.call(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onError?.call('External wallet selected: ${response.walletName}');
  }

  void checkout({
    required double amount,
    required String name,
    required String email,
    required String mobile,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) {
    // Store callbacks for the listeners
    _onSuccess = onSuccess;
    _onError = onError;

    final options = {
      'key': _keyId,
      'amount': (amount * 100).toInt(),
      'currency': 'INR',
      'name': 'Chef Planet',
      'description': 'Order Payment',
      // NOTE: Do NOT pass 'order_id' in test mode unless you create one
      // via the Razorpay Orders API. A fake order_id causes the checkout to hang.
      'prefill': {
        'contact': mobile,
        'email': email,
        'name': name,
      },
      'theme': {
        'color': '#E67E22',
      }
    };

    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}
