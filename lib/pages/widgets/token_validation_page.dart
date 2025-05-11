// File: lib/pages/token_validation_page.dart
import 'package:flutter/material.dart';
import 'package:bloodbridge/pages/widgets/reset_password_page.dart';
import 'package:bloodbridge/services/auth_service.dart';

class TokenValidationPage extends StatefulWidget {
  final String token;

  const TokenValidationPage({
    super.key,
    required this.token,
  });

  @override
  _TokenValidationPageState createState() => _TokenValidationPageState();
}

class _TokenValidationPageState extends State<TokenValidationPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isValid = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    try {
      final isValid = await _authService.validateResetToken(widget.token);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isValid = isValid;
        });

        if (isValid) {
          // Short delay before navigating to the reset page
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordPage(token: widget.token),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isValid = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Validating Reset Link"),
        centerTitle: true,
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.red),
                  const SizedBox(height: 20),
                  const Text("Validating your reset link..."),
                ],
              )
            : _isValid
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                      const SizedBox(height: 20),
                      const Text(
                        "Token Validated!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Redirecting to password reset page..."),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: Colors.green),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 20),
                      const Text(
                        "Invalid or Expired Link",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage.isEmpty
                              ? "The password reset link you clicked is invalid or has expired."
                              : _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/forgot-password',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                        ),
                        child: const Text(
                          "Request New Link",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}