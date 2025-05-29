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

  // List of policies that users must agree to
  final List<String> _policies = [
    'Be ready to accept change of status if there is a defect in your blood',
    'Be ready to seek medical attention if status changes',
    'Be available to donate if status is okay and you are eligible',
    'Update the donation date after each donation',
    'Wait a full recovery period before your next donation (typically 56 days for whole blood)',
    'Maintain good health and inform the donation center of any new medications',
    'Do not donate when you are sick, have a fever, or feel unwell',
    'Inform the donation center of any recent travel to areas with endemic diseases',
    'Disclose complete and accurate medical history',
    'Follow all pre and post-donation instructions provided by staff'
  ];

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

    // Show policy dialog when user clicks Sign Up
    _showPolicyDialog();
  }

  void _showPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Donor Policies',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'As a blood donor, I agree to:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ..._policies.map((policy) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(policy, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                const Text(
                  'These policies are designed to ensure the safety of both donors and recipients. '
                  'Failure to comply may result in temporary or permanent deferral from the donation program.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Disagree', style: TextStyle(color: Colors.grey[700])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
              child: const Text('Agree', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _processRegistration();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRegistration() async {
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
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
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
      ),
    );
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
        title: const Text('Donor Registration', style: TextStyle(fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.red[700],
        iconTheme: const IconThemeData(color: Colors.white),
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
                hintText: '+265885043356',
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
                  backgroundColor: Colors.red[700],
                  disabledBackgroundColor: Colors.grey[400],
                  disabledForegroundColor: Colors.grey[700],
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white,
                        ),
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
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
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