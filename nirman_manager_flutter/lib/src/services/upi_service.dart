import 'package:url_launcher/url_launcher.dart';

/// Launches the user's UPI app (GPay / PhonePe / Paytm / BHIM …) with a
/// pre-filled payment via the standard upi://pay deep link.
///
/// Note: the deep link opens the UPI app with amount and payee filled in;
/// the user completes the payment there. Record the payment in the app
/// after it succeeds.
class UpiService {
  UpiService._();

  static Future<bool> pay({
    required String payeeVpa, // e.g. worker@upi
    required String payeeName,
    required double amount,
    String note = 'Payment from Nirman Manager',
  }) async {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': payeeVpa,
        'pn': payeeName,
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
        'tn': note,
      },
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
