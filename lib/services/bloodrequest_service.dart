import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:bloodbridge/services/brevo_email_service.dart';
import 'package:flutter/foundation.dart'; 



class BloodRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> requestDonorsByDistance({
    required String hospitalId,
    required String requestedBloodType,
    required double maxDistanceKm,
  }) async {
    // 1. Get hospital data
    final hospitalDoc = await _firestore.collection('hospitals').doc(hospitalId).get();
    final hospitalData = hospitalDoc.data()!;
    final hospitalLoc = hospitalData['location'] as GeoPoint;
    final hospitalEmail = hospitalData['email'] as String;

    // 2. Find compatible donors within distance
    final donors = await _findDonorsWithinRadius(
      center: hospitalLoc,
      radiusKm: maxDistanceKm,
      bloodType: requestedBloodType,
    );

    // 3. Create requests and notify donors
    for (final donor in donors) {
      await _createBloodRequest(
        hospitalId: hospitalId,
        hospitalEmail: hospitalEmail,
        donor: donor,
      );
    }
  }

  Future<List<QueryDocumentSnapshot>> _findDonorsWithinRadius({
    required GeoPoint center,
    required double radiusKm,
    required String bloodType,
  }) async {
    // Approximate 1 degree = 111km
    final lat = radiusKm / 111;
    final lng = radiusKm / (111 * cos(center.latitude * (pi / 180)));

    final query = _firestore.collection('donors')
      .where('bloodType', isEqualTo: bloodType)
      .where('location', 
        isGreaterThan: GeoPoint(center.latitude - lat, center.longitude - lng),
        isLessThan: GeoPoint(center.latitude + lat, center.longitude + lng),
      );

    final snapshot = await query.get();

    // Filter by exact distance
    return snapshot.docs.where((doc) {
      final donorLoc = doc['location'] as GeoPoint;
      final distance = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        donorLoc.latitude,
        donorLoc.longitude,
      ) / 1000;
      return distance <= radiusKm;
    }).toList();
  }

  Future<void> _createBloodRequest({
    required String hospitalId,
    required String hospitalEmail,
    required QueryDocumentSnapshot donor,
  }) async {
    // 1. Create request record
    await _firestore.collection('blood_requests').add({
      'hospitalId': hospitalId,
      'donorId': donor.id,
      'donorEmail': donor['email'],
      'bloodType': donor['bloodType'],
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'distanceKm': _calculateDistance(
        donor['location'] as GeoPoint,
        (await _firestore.collection('hospitals').doc(hospitalId).get())['location'],
      ),
    });

    // 2. Send email to donor
    await _sendRequestEmail(
      donorEmail: donor['email'],
      hospitalEmail: hospitalEmail,
      bloodType: donor['bloodType'],
    );
  }

  double _calculateDistance(GeoPoint donorLoc, GeoPoint hospitalLoc) {
    return Geolocator.distanceBetween(
      hospitalLoc.latitude,
      hospitalLoc.longitude,
      donorLoc.latitude,
      donorLoc.longitude,
    ) / 1000;
  }

  Future<void> _sendRequestEmail({
  required String donorEmail,
  required String hospitalEmail,
  required String bloodType,
}) async {
  try {
    await BrevoEmailService.sendBasicEmail(
      to: donorEmail,
      subject: 'Urgent Blood Donation Request',
      text: 'Dear Donor,\n\n'
          'Hospital ($hospitalEmail) urgently requires $bloodType blood. '
          'If you are available to donate, please contact the hospital as soon as possible.\n\n'
          'Thank you for your support!\n\n'
          'BloodBridge Team',
    );
  } catch (e) {
    debugPrint('Failed to send email to $donorEmail: $e');
    // Optionally, rethrow the error to handle it at a higher level
    throw Exception('Email sending failed: $e');
  }
}

}