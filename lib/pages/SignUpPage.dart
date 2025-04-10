import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'donations': TextEditingController(),
    'password': TextEditingController(),
    'confirmPassword': TextEditingController(),
  };
  String? _selectedBloodType;
  bool _isLoading = false;
  Position? _currentPosition;
  String _locationStatus = '';

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationStatus = 'Getting location...';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = 'Location captured';
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Error: ${e.toString()}';
      });
      rethrow;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodType == null) {
      _showError('Please select your blood type');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Get location first
      await _getCurrentLocation();
      if (_currentPosition == null) {
        throw Exception('Could not get current location');
      }

      // Create donor data with location coordinates at the top level
      final donorData = {
        'name': _controllers['name']!.text.trim(),
        'email': _controllers['email']!.text.trim(),
        'phone': _controllers['phone']!.text.trim(),
        'password': _controllers['password']!.text.trim(),
        'bloodGroup': _selectedBloodType!, 
        'donations': int.parse(_controllers['donations']!.text.trim()),
        'role': 'donor',
        'latitude': _currentPosition!.latitude,  // Changed: Now as top-level property
        'longitude': _currentPosition!.longitude,  // Changed: Now as top-level property
      };

      await _authService.registerDonor(donorData);

      if (mounted) {
        _showSuccess('Account created successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Registration'),
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.bloodtype, size: 100, color: Colors.red),
              const SizedBox(height: 20),
              _buildTextFormField(
                'name',
                'Full Name',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              _buildTextFormField(
                'email',
                'Email',
                validator: (value) =>
                    !value!.contains('@') ? 'Invalid email' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextFormField(
                'phone',
                'Phone Number',
                validator: (value) => value!.length < 8 ? 'Too short' : null,
                keyboardType: TextInputType.phone,
              ),
              _buildTextFormField(
                'donations',
                'Number of Donations',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                'password',
                'Password',
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? 'Minimum 6 characters' : null,
              ),
              _buildTextFormField(
                'confirmPassword',
                'Confirm Password',
                obscureText: true,
                validator: (value) => value != _controllers['password']!.text
                    ? 'Passwords don\'t match'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildBloodTypeDropdown(),
              const SizedBox(height: 16),
              // Location capture section
              _currentPosition != null
                  ? ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.green),
                      title: const Text('Location captured'),
                      subtitle: Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}\n'
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      ),
                    )
                  : Text(
                      _locationStatus,
                      style: TextStyle(
                        color: _locationStatus.startsWith('Error') 
                            ? Colors.red 
                            : Colors.grey,
                      ),
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'REGISTER',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    String key,
    String label, {
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodType,
      items: const [
        'A+',
        'A-',
        'B+',
        'B-',
        'AB+',
        'AB-',
        'O+',
        'O-',
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() => _selectedBloodType = newValue);
      },
      decoration: const InputDecoration(
        labelText: 'Blood Type',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}