import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSummary extends StatelessWidget {
  const ProfileSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('donors').doc(user?.uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var donorData = snapshot.data!.data() as Map<String, dynamic>;
            String initials = _getInitials(donorData['name']);
            String bloodType = donorData['bloodType'];
            int donations = donorData['donations'] ?? 0;

            return Column(
              children: [
                // Profile Avatar + Welcome Message
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[400],
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Welcome! ${donorData['name']}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Profile Tab Message from Firestore
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('profile_tab').doc("Y1FkjCvHx4aVLf0DwcAx").get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var profileData = snapshot.data!.data() as Map<String, dynamic>;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileData['description'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profileData['description2'],
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Blood Type Card & Description from Firestore
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('blood_type').doc(bloodType).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var bloodTypeData = snapshot.data!.data() as Map<String, dynamic>;
                    String bloodTypeDescription = bloodTypeData['description'] ?? 'No description available';

                    return Column(
                      children: [
                        _buildInfoCard("Blood Type", bloodType, const Color.fromARGB(255, 223, 61, 74)),
                        const SizedBox(height: 16),
                        _buildDescriptionCard(bloodTypeDescription),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Total Donations Card
                _buildInfoCard("Total Donations", donations.toString(), const Color.fromARGB(255, 223, 61, 74)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        description,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = names.map((n) => n.isNotEmpty ? n[0] : "").join();
    return initials.toUpperCase();
  }
}
