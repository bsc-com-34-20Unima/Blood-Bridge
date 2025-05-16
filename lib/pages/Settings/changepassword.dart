import 'package:bloodbridge/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:bloodbridge/services/auth_service.dart';
import 'dart:convert';

class UpdateHospitalPage extends StatefulWidget {
  const UpdateHospitalPage({Key? key}) : super(key: key);

  @override
  _UpdateHospitalPageState createState() => _UpdateHospitalPageState();
}

class _UpdateHospitalPageState extends State<UpdateHospitalPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadHospitalDetails();
  }

  Future<void> _loadHospitalDetails() async {
    try {
      final hospitalId = await _authService.getUserId();
      if (hospitalId == null) throw Exception("User ID not found");

      final response = await _authService.authenticatedRequest(
        'hospital/$hospitalId',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
        });
      } else {
        throw Exception('Failed to fetch hospital data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hospital info: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  void _updateHospital() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hospitalId = await _authService.getUserId();
      if (hospitalId == null) throw Exception("User ID not found");

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_passwordController.text.trim().isNotEmpty) {
        updateData['password'] = _passwordController.text.trim();
      }

      final response = await _authService.authenticatedRequest(
        'hospital/$hospitalId',
        method: 'PATCH',
        data: updateData,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hospital details updated successfully',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
        _passwordController.clear();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hospital Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmationDialog(context);

            },
          ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Hospital Name'),
                      validator: (value) => value!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.isEmpty || !value.contains('@')
                              ? 'Enter valid email'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _updateHospital,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Info'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Logout",
                  style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _authService.logout();
        navigator.pop(); // Close loading dialog
        
        // Navigate to login screen and clear navigation stack
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        navigator.pop(); // Close loading dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }
}
