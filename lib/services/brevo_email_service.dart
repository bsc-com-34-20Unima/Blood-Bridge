// brevo_email_service.dart
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class BrevoEmailService {
  static final String _apiKey = dotenv.env['BREVO_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.brevo.com/v3/smtp/email';

  /// Simplified email sending matching the original Firebase interface
  static Future<void> sendBasicEmail({
    required String to,
    required String subject,
    required String text,
  }) async {
    try {
      await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sender': {
            'name': 'BloodBridge',
            'email': 'noreply@bloodbridge.org',
          },
          'to': [{'email': to}],
          'subject': subject,
          'textContent': text,
        }),
      );
    } catch (e) {
      print('Failed to send email: $e');
      rethrow;
    }
  }
}