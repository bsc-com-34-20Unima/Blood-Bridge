
class AlertItem {
  final String title;
  final String message;
  final String location;

  AlertItem({required this.title, required this.location, required this.message});
}

// Global alerts list shared between pages
List<AlertItem> globalAlerts = [
  AlertItem(
    title: "Low Inventory", 
    location: "Zomba Central Hospital", 
    message: "Blood group O- is low on inventory."
  ),
  AlertItem(
    title: "Critical Alert", 
    location: "Chiradzulu", 
    message: "Critical shortage for blood group AB-."
  ),
  AlertItem(
    title: "Reminder", 
    location: "Thyolo", 
    message: "Don't forget to update the inventory."
  ),
];
