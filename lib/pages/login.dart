import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloodbridge/pages/SignUpPage.dart';
import 'package:bloodbridge/pages/hospitadashboard.dart';
import 'package:bloodbridge/screens/donor_dashboard_screen.dart';
import 'package:bloodbridge/services/auth_service.dart';

class LocationFailure implements Exception {
  final String message;
  LocationFailure({required this.message});
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
  final String _baseUrl = 'http://localhost:3005';
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 1. Get current location
        final position = await _getCurrentPosition();
        
        // 2. Authenticate with server
        final authResponse = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // 3. Save hospital ID if user is a hospital
        if (authResponse['role'] != 'donor' && authResponse['hospitalId'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('hospitalId', authResponse['hospitalId']);
          await prefs.setString('authToken', authResponse['token']);
          debugPrint('Saved hospitalId: ${authResponse['hospitalId']}');
        }

        // 4. Navigate to appropriate dashboard
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => authResponse['role'] == 'donor'
                ? const DonorDashboardScreen()
                : const HospitalDashboard(),
          ),
        );
      } on LocationFailure catch (e) {
        _showError(e.message);
      } catch (e) {
        _showError("Login failed: ${e.toString()}");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<Position> _getCurrentPosition() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      throw LocationFailure(
          message: 'Location services are disabled. Please enable location services to continue.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationFailure(
            message: 'Location permission denied. Location access is required to log in.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
          message:
              'Location permissions permanently denied. Please enable location permissions in app settings to log in.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 100),
        ),
      );
    } catch (e) {
      throw LocationFailure(message: 'Could not get current location: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 71, 67, 67),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
                const SizedBox(height: 15),
                _buildLocationRequirementNote(),
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUpPage()),
        ),
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

  Widget _buildLocationRequirementNote() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3))
      ),
      child: const Row(
        children: [
          Icon(Icons.location_on, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Location access is required to use BloodBridge.",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}