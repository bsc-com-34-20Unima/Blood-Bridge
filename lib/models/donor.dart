class Donor {
  final String id;
  final String name;
  final BloodGroup bloodGroup;
  final String email;
  final String phone;
  final String address;
  final dynamic status;
  final double latitude;  // Changed to double
  final double longitude;  // Changed to double

  Donor({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.email,
    required this.phone,
    required this.address,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'],
      name: json['name'],
      bloodGroup: BloodGroup.fromJson(json['bloodGroup']),
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      status: json['status'],
      latitude: json['latitude']?.toDouble(),  // Parsing to double
      longitude: json['longitude']?.toDouble(),  // Parsing to double
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bloodGroup': bloodGroup.toJson(),
      'email': email,
      'phone': phone,
      'address': address,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class BloodGroup {
  final String id;
  final String bloodGroup;
  final String description;
  final String canDonateTo;
  final String canReceiveFrom;

  BloodGroup({
    required this.id,
    required this.bloodGroup,
    required this.description,
    required this.canDonateTo,
    required this.canReceiveFrom,
  });

  factory BloodGroup.fromJson(Map<String, dynamic> json) {
    return BloodGroup(
      id: json['id'],
      bloodGroup: json['blood_group'],
      description: json['description'],
      canDonateTo: json['canDonateTo'],
      canReceiveFrom: json['canReceiveFrom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blood_group': bloodGroup,
      'description': description,
      'canDonateTo': canDonateTo,
      'canReceiveFrom': canReceiveFrom,
    };
  }
}
