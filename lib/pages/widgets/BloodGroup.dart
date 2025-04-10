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
}
