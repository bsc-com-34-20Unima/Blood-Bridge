class AlertItem {
  final String title;
  final String message;
  final String location;
  final DateTime timestamp;

  AlertItem({
    required this.title,
    required this.location,
    required this.message,
    required this.timestamp,
  });
}

// Global alerts list shared between pages
List<AlertItem> globalAlerts = [
  AlertItem(
    title: "Low Inventory",
    location: "Zomba Central Hospital",
    message: "Blood group O- is low on inventory.",
    timestamp: DateTime.now(),
  ),
  AlertItem(
    title: "Critical Alert",
    location: "Chiradzulu",
    message: "Critical shortage for blood group AB-.",
    timestamp: DateTime.now(),
  ),
  AlertItem(
    title: "Reminder",
    location: "Thyolo",
    message: "Don't forget to update the inventory.",
    timestamp: DateTime.now(),
  ),
];

// Function to add new alert
void addAlert(AlertItem alert) {
  globalAlerts.add(alert);
}

// Function to remove alert by title
void removeAlert(String title) {
  globalAlerts.removeWhere((alert) => alert.title == title);
}

// Function to get recent alerts (optional filter by time)
List<AlertItem> getRecentAlerts({int hoursAgo = 24}) {
  final cutoff = DateTime.now().subtract(Duration(hours: hoursAgo));
  return globalAlerts.where((alert) => alert.timestamp.isAfter(cutoff)).toList();
}
