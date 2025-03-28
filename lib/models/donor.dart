// lib/models/donor.dart
class Donor {
  final String name;
  final String bloodType;
  final DateTime lastDonation;
  final DateTime nextEligible;
  final int totalDonations;

  Donor({
    required this.name,
    required this.bloodType,
    required this.lastDonation,
    required this.nextEligible,
    required this.totalDonations,
  });
}