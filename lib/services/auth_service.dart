import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  donor,
  hospital,
  unknown
}

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
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }

  // Login Function (Returns UserCredential)
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  // New Function to Get User Role
  Future<UserRole> getUserRole(String uid) async {
    try {
      // Check if user is a donor
      DocumentSnapshot donorDoc = await _firestore.collection('donors').doc(uid).get();
      
      if (donorDoc.exists) {
        return UserRole.donor;
      }
      
      // Check if user is a hospital
      DocumentSnapshot hospitalDoc = await _firestore.collection('hospitals').doc(uid).get();
      
      if (hospitalDoc.exists) {
        return UserRole.hospital;
      }
      
      return UserRole.unknown;
    } catch (e) {
      throw Exception("Error determining user role: ${e.toString()}");
    }
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}