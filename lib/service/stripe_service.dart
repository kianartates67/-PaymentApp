import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {

  static const Map<String, String> _testToken = {
    '4242424242424242': 'tok_visa',
    '4000000034576934': 'tok_visa_debit',
    '5555555555554444': 'tok_mastercard',
    '5200828282828210': 'tok_mastercard_debit',
    '4000000000000001': 'tok_chargeDecline',
    '4000000000009995': 'tok_chargeDeclineIndufficientFunds',
  };

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
}) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _testToken[cleanCard];

    if (token == null) {
      return {
        'success': false,
        'error': 'unknown test card, use 4242424242424242 (success)',

      };
    }
      try {
        final response = await http.post(
          Uri.parse('${StripeConfig.apiUrl}/charges'),
          headers: {
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'amount': amountInCentavos,
            'currency': 'php',
            'source': token,
            'description': 'Flutter Payment App Purchase',
          },
        );
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && (data['status'] == 'succeeded' || data['paid'] == true)) {
          return {
            'success': true,
            'id': data['id'],
            'amount': data['amount'] / 100,
            'status': data['status'] ?? 'succeeded',
          };
        } else {
          return {
            'success': false,
            'error':data['error']?['message']??'Payment failed',
          };

        }
    } catch (e) {
        return {
          'success': false,
          'error': e.toString(),
        };
      }
  }

}