import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

enum UserRole { donor, hospital, unknown }

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  Future<void> registerDonor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String bloodType,
    required int donations,
  }) async {
    try {
      // Input validation
      if (bloodType.isEmpty) throw AuthFailure(message: "Blood type is required");

      // Get location
      final position = await getUserPosition();

      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save to Firestore
      await _firestore.collection('donors').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'bloodType': bloodType,
        'donations' : donations,
        'role': UserRole.donor.name,
        'location': GeoPoint(position.latitude, position.longitude),
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(code: e.code, message: e.message ?? 'Authentication failed');
    } catch (e) {
      throw AuthFailure(message: 'Registration failed: ${e.toString()}');
    }
  }

  Future<Position> getUserPosition() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) throw Exception('Enable location services');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      throw AuthFailure(message: 'Location error: ${e.toString()}');
    }
  }

  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(code: e.code, message: e.message ?? 'Login failed');
    }
  }

  Future<UserRole> getUserRole(String uid) async {
    try {
      final snapshot = await _firestore.collection('donors').doc(uid).get();
      return snapshot.exists ? UserRole.donor : UserRole.unknown;
    } catch (e) {
      throw AuthFailure(message: 'Role check failed: ${e.toString()}');
    }
  }

  User? getCurrentUser() => _auth.currentUser;

  Future<void> signOut() async => await _auth.signOut();
}

class AuthFailure implements Exception {
  final String? code;
  final String message;
  AuthFailure({this.code, required this.message});

  @override
  String toString() => message;
}