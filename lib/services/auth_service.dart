import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Donor Registration
  Future<void> registerDonor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String bloodType,
  }) async {
    try {
      // Create donor in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store donor details in Firestore
      await _firestore.collection('donors').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'bloodType': bloodType,
        'role': 'donor',
      });
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }

  // ✅ Login Function (Returns UserCredential)
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }
}
