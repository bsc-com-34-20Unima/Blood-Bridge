import 'dart:async';
import 'package:bloodbridge/pages/widgets/token_validation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';


class DeepLinkHandler {
  static bool _isInitialized = false;
  static StreamSubscription? _sub;
  static bool _initialUriHandled = false;

  // Handle the initial URI if the app was opened with it
  static Future<bool> handleInitialUri(BuildContext context) async {
    if (_initialUriHandled) return false;
    _initialUriHandled = true;

    try {
      final initialUri = await getInitialUri();
      debugPrint("Initial URI: $initialUri");
      
      if (initialUri != null) {
        return _handleUri(initialUri, context);
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get initial uri: $e");
    } on FormatException catch (e) {
      debugPrint("Bad initial uri format: $e");
    } catch (e) {
      debugPrint("Unknown exception handling initial uri: $e");
    }
    return false;
  }

  // Set up ongoing listener for links that open the app
  static void initUriHandler(BuildContext context) {
    if (_isInitialized) return;
    _isInitialized = true;

    // Handle the initial URI first
    handleInitialUri(context);

    // Listen for subsequent links
    _sub = uriLinkStream.listen((Uri? uri) {
      debugPrint("Received URI: $uri");
      if (uri != null) {
        // Handle link while app is running
        _handleUri(uri, context);
      }
    }, onError: (Object err) {
      debugPrint('Error handling deeplink: $err');
    });
  }

  // Clean up subscription
  static void dispose() {
    if (_isInitialized && _sub != null) {
      _sub!.cancel();
      _isInitialized = false;
    }
  }

  // Handle different URI paths and extract relevant data
  static bool _handleUri(Uri uri, BuildContext context) {
    debugPrint("Handling deeplink: ${uri.toString()}");
    
    // Handle reset password deeplinks - more flexible pattern matching
    final bool isResetPasswordLink = 
        uri.host == 'reset-password' || // bloodbridge://reset-password
        uri.pathSegments.contains('reset-password') || // bloodbridge://app/reset-password
        uri.path.contains('reset-password') || // fallback for other patterns
        (uri.host.isEmpty && uri.queryParameters.containsKey('token')); // bloodbridge://?token=xyz
    
    if (isResetPasswordLink) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        debugPrint("Reset password token found: $token");
        
        // Navigate to token validation page first
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TokenValidationPage(token: token),
            ),
          );
        });
        return true;
      } else {
        debugPrint("Reset password link found but no token parameter");
      }
    }
    
    // Add more deep link handlers as needed
    
    return false;
  }

  // For testing in local environment
  static void simulateDeepLink(BuildContext context, String link) {
    try {
      final uri = Uri.parse(link);
      _handleUri(uri, context);
    } catch (e) {
      debugPrint("Failed to simulate deep link: $e");
    }
  }
}