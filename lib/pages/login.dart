import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloodbridge/pages/SignUpPage.dart';
import 'package:bloodbridge/pages/hospitadashboard.dart';
import 'package:bloodbridge/screens/donor_dashboard_screen.dart';
import 'package:geolocator/geolocator.dart';

enum UserRole { donor, hospital }

class AuthFailure implements Exception {
  final String message;
  AuthFailure({required this.message});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final String _baseUrl = 'http://10.0.2.2:3004';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 1. Authenticate user with backend
        final authResponse = await _authenticateUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // 2. Save auth data
        await _saveAuthData(authResponse);

        // 3. Get current position
        final position = await _getCurrentPosition();

        // 4. Update user location
        await _updateUserLocation(
          authResponse['userId'],
          position,
          authResponse['role'] == 'donor' ? UserRole.donor : UserRole.hospital,
          authResponse['token']
        );

        // 5. Navigate to appropriate dashboard
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => authResponse['role'] == 'donor'
                ? const DonorDashboardScreen()
                : const HospitalDashboard(),
          ),
        );
      } on AuthFailure catch (e) {
        _showError(e.message);
      } catch (e) {
        _showError("Login failed: ${e.toString()}");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _authenticateUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authData = json.decode(response.body);
        
        // Ensure we have all required fields
        if (authData['token'] == null || 
            authData['userId'] == null ||
            authData['role'] == null ||
            authData['name'] == null) {
          throw AuthFailure(message: "Invalid response from server");
        }
        
        return authData;
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Authentication failed';
        throw AuthFailure(message: message);
      }
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure(message: "Network error: ${e.toString()}");
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', authData['token']);
    await prefs.setString('user_id', authData['userId']);
    await prefs.setString('user_role', authData['role']);
    await prefs.setString('user_name', authData['name']);
  }

  Future<Position> _getCurrentPosition() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) throw Exception('Location services are disabled');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> _updateUserLocation(
    String userId, 
    Position position, 
    UserRole role,
    String token
  ) async {
    final endpoint = role == UserRole.donor ? 'donors' : 'hospitals';
    
    try {
      await http.patch(
        Uri.parse('$_baseUrl/$endpoint/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'lastActive': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      // Log error but don't prevent login if location update fails
      debugPrint('Failed to update location: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' BloodBridge Login'),
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.bloodtype, size: 100, color: Colors.red),
                const SizedBox(height: 20),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 10),
                _buildForgotPassword(),
                const SizedBox(height: 30),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildSignUpPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: "Email",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Email is required";
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return "Enter a valid email";
        }
        return null;
      },
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Password",
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Password is required";
        if (value.length < 6) return "Minimum 6 characters";
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _showError("Password reset feature coming soon!"),
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : const Text(
                "LOGIN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpPage()),
          ),
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}