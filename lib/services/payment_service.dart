// lib/services/payment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import 'db_service.dart';

class PaymentService {
  // These would typically be stored securely (e.g., in Firebase Functions or .env)
  static const String _mpesaShortCode = 'YOUR_MPESA_SHORT_CODE';
  static const String _mpesaConsumerKey = 'YOUR_MPESA_CONSUMER_KEY';
  static const String _mpesaConsumerSecret = 'YOUR_MPESA_CONSUMER_SECRET';
  static const String _mpesaPasskey = 'YOUR_MPESA_PASSKEY';
  static const String _mpesaCallbackUrl = 'YOUR_CALLBACK_URL';

  final DBService _dbService = DBService();

  // Get access token from M-Pesa API
  Future<String> _getAccessToken() async {
    try {
      final String credentials = '$_mpesaConsumerKey:$_mpesaConsumerSecret';
      final String encodedCredentials = base64Encode(utf8.encode(credentials));

      final response = await http.get(
        Uri.parse(
          'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
        ),
        headers: {'Authorization': 'Basic $encodedCredentials'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting access token: $e');
    }
  }

  // Initiate STK Push
  Future<bool> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String orderId,
    String? accountReference,
  }) async {
    try {
      // Get access token
      String accessToken = await _getAccessToken();

      // Format phone number (remove leading 0 and add country code)
      String formattedPhone = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhone = '254${phoneNumber.substring(1)}';
      } else if (!phoneNumber.startsWith('254')) {
        formattedPhone = '254$phoneNumber';
      }

      // Generate timestamp
      DateTime now = DateTime.now();
      String timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      // Generate password
      String password = base64Encode(
        utf8.encode('$_mpesaShortCode$_mpesaPasskey$timestamp'),
      );

      // Make STK Push request
      final response = await http.post(
        Uri.parse(
          'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'BusinessShortCode': _mpesaShortCode,
          'Password': password,
          'Timestamp': timestamp,
          'TransactionType': 'CustomerBuyGoodsOnline',
          'Amount': amount.toInt(),
          'PartyA': formattedPhone,
          'PartyB': _mpesaShortCode,
          'PhoneNumber': formattedPhone,
          'CallBackURL': _mpesaCallbackUrl,
          'AccountReference': accountReference ?? orderId,
          'TransactionDesc': 'Order Payment - $orderId',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if request was successful
        if (data['ResponseCode'] == '0') {
          // Update order with pending payment status
          await _dbService.updatePaymentInfo(orderId, 'pending', null);
          return true;
        } else {
          throw Exception('STK Push failed: ${data['ResponseDescription']}');
        }
      } else {
        throw Exception('Failed to initiate STK Push: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error initiating payment: $e');
    }
  }

  // Handle M-Pesa callback (would be called from backend)
  Future<void> handleMpesaCallback(Map<String, dynamic> callbackData) async {
    try {
      // Extract payment details from callback
      Map<String, dynamic> stkCallback = callbackData['Body']['stkCallback'];
      String resultCode = stkCallback['ResultCode'];
      String merchantRequestId = stkCallback['MerchantRequestID'];
      String checkoutRequestId = stkCallback['CheckoutRequestID'];

      // Find order by merchant request ID (you would need to store this)
      // For now, we'll just log the callback
      print('M-Pesa Callback received: $resultCode');

      if (resultCode == '0') {
        // Payment successful
        // Extract receipt number from callback
        Map<String, dynamic> callbackMetadata =
            stkCallback['CallbackMetadata']['Item'];
        String? receiptNumber;
        for (var item in callbackMetadata) {
          if (item['Name'] == 'MpesaReceiptNumber') {
            receiptNumber = item['Value'];
            break;
          }
        }

        // Update order payment status
        // Note: You would need to map the checkoutRequestId to orderId in your database
        print('Payment successful! Receipt: $receiptNumber');
      } else {
        // Payment failed
        print('Payment failed with code: $resultCode');
      }
    } catch (e) {
      throw Exception('Error handling M-Pesa callback: $e');
    }
  }

  // Check payment status
  Future<String> checkPaymentStatus(String checkoutRequestId) async {
    try {
      String accessToken = await _getAccessToken();

      // Generate timestamp
      DateTime now = DateTime.now();
      String timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      // Generate password
      String password = base64Encode(
        utf8.encode('$_mpesaShortCode$_mpesaPasskey$timestamp'),
      );

      final response = await http.post(
        Uri.parse(
          'https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'BusinessShortCode': _mpesaShortCode,
          'Password': password,
          'Timestamp': timestamp,
          'CheckoutRequestID': checkoutRequestId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ResultCode'];
      } else {
        throw Exception('Failed to check payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }

  // Process order payment
  Future<bool> processOrderPayment(Order order, String phoneNumber) async {
    try {
      return await initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: order.totalAmount,
        orderId: order.id,
        accountReference: 'ORDER-${order.id}',
      );
    } catch (e) {
      throw Exception('Error processing order payment: $e');
    }
  }
}
