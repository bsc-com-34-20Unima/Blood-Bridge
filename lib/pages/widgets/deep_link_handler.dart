import 'dart:async';
import 'package:bloodbridge/pages/widgets/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:app_links/app_links.dart';

class DeepLinkHandler {
  static bool _initialUriHandled = false;
  static StreamSubscription? _deepLinkSubscription;
  static final AppLinks _appLinks = AppLinks(); // Create AppLinks instance

  // Initialize and handle deep links
  static Future<void> setupDeepLinks(BuildContext context) async {
    // Handle initial URI if the app was launched with one
    if (!_initialUriHandled) {
      _initialUriHandled = true;
      try {
        final initialUri = await _appLinks.getInitialAppLink(); // Use AppLinks method
        if (initialUri != null) {
          _handleDeepLink(initialUri, context);
        }
      } on PlatformException {
        // Handle exception if needed
        developer.log('Failed to get initial URI');
      } on FormatException {
        // Handle bad URI format
        developer.log('Bad URI format');
      }
    }

    // Listen for subsequent deep links
    _deepLinkSubscription = _appLinks.allUriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri, context);
    }, onError: (error) {
      developer.log('Deep link error: $error');
    });
  }

  // Clean up subscription
  static void dispose() {
    _deepLinkSubscription?.cancel();
  }

  // Handle deep link URI
  static void _handleDeepLink(Uri uri, BuildContext context) {
    developer.log('Deep link received: $uri');

    // Check if it's a password reset link
    if (uri.path.contains('reset-password') ||
        uri.path.contains('auth/reset-password')) {
      final token = uri.queryParameters['token'];

      if (token != null) {
        developer.log('Reset token found: $token');

        // Navigate to reset password page
        _navigateToResetPassword(context, token);
      }
    }
  }

  // Navigate to password reset page
  static void _navigateToResetPassword(BuildContext context, String token) {
    // Delay slightly to ensure context is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(token: token),
        ),
      );
    });
  }
}