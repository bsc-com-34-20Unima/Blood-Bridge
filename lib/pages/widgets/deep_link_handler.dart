import 'dart:async';
import 'package:bloodbridge/pages/widgets/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:app_links/app_links.dart';

class DeepLinkHandler {
  static bool _initialUriHandled = false;
  static StreamSubscription? _deepLinkSubscription;
  static final AppLinks _appLinks = AppLinks();
  static BuildContext? _savedContext;

  // Initialize and handle deep links
  static Future<void> setupDeepLinks(BuildContext context) async {
    _savedContext = context;
    
    // Handle initial URI if the app was launched with one
    if (!_initialUriHandled) {
      _initialUriHandled = true;
      try {
        final initialUri = await _appLinks.getInitialAppLink();
        if (initialUri != null) {
          developer.log('Initial deep link: $initialUri');
          _handleDeepLink(initialUri, context);
        }
      } on PlatformException catch (e) {
        developer.log('Failed to get initial URI: $e');
      } on FormatException catch (e) {
        developer.log('Bad URI format: $e');
      }
    }

    // Cancel existing subscription to avoid duplicates
    await _deepLinkSubscription?.cancel();

    // Listen for subsequent deep links
    _deepLinkSubscription = _appLinks.allUriLinkStream.listen(
      (Uri uri) {
        developer.log('Incoming deep link: $uri');
        _handleDeepLink(uri, _savedContext ?? context);
      },
      onError: (error) {
        developer.log('Deep link error: $error');
      },
    );
  }

  // Clean up subscription
  static void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
    _savedContext = null;
  }

  // Handle deep link URI
  static void _handleDeepLink(Uri uri, BuildContext context) {
    developer.log('Processing deep link: $uri');
    developer.log('URI path: ${uri.path}');
    developer.log('URI query parameters: ${uri.queryParameters}');

    try {
      // Check if it's a password reset link
      if (uri.path.contains('reset-password') || 
          uri.host == 'reset-password' ||
          uri.queryParameters.containsKey('token')) {
        
        final token = uri.queryParameters['token'];
        
        if (token != null && token.isNotEmpty) {
          developer.log('Valid reset token found: ${token.substring(0, 8)}...');
          _navigateToResetPassword(context, token);
        } else {
          developer.log('No token found in deep link');
          _showErrorDialog(context, 'Invalid reset link - no token found');
        }
      } else {
        developer.log('Deep link does not match reset password pattern');
      }
    } catch (e) {
      developer.log('Error handling deep link: $e');
      _showErrorDialog(context, 'Error processing reset link');
    }
  }

  // Navigate to password reset page
  static void _navigateToResetPassword(BuildContext context, String token) {
    // Use a more robust delay to ensure the app is fully loaded
    Timer(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        // Use named route with arguments for better integration
        Navigator.of(context).pushNamed(
          '/reset-password',
          arguments: {'token': token},
        );
      }
    });
  }

  // Show error dialog for invalid links
  static void _showErrorDialog(BuildContext context, String message) {
    Timer(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Reset Link Error'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  // Update context when navigating between pages
  static void updateContext(BuildContext context) {
    _savedContext = context;
  }

  // Check if a deep link is a password reset link
  static bool isPasswordResetLink(Uri uri) {
    return (uri.path.contains('reset-password') || 
            uri.host == 'reset-password') &&
           uri.queryParameters.containsKey('token');
  }

  // Extract token from URI
  static String? extractTokenFromUri(Uri uri) {
    return uri.queryParameters['token'];
  }

  // Manual deep link processing (for testing)
  static void processManualLink(String link, BuildContext context) {
    try {
      final uri = Uri.parse(link);
      _handleDeepLink(uri, context);
    } catch (e) {
      developer.log('Error parsing manual link: $e');
      _showErrorDialog(context, 'Invalid reset link format');
    }
  }
}