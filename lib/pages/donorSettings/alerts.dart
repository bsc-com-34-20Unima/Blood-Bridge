import 'package:flutter/material.dart';

class AlertItem {
  final String title;
  final String message;
  final String location;

  AlertItem({required this.title, required this.location, required this.message});
}

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  _AlertPageState createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final List<AlertItem> _alerts = [
    AlertItem(
      title: "Low Inventory", 
      location: "zomba central hospital", 
      message: "Blood group O- is low on inventory."
    ),
    AlertItem(
      title: "Critical Alert", 
      location: "chiradzulu", 
      message: "Critical shortage for blood group AB-."
    ),
    AlertItem(
      title: "Reminder", 
      location: "thyolo", 
      message: "Don't forget to update the inventory."
    ),
  ];

  void _removeAlert(int index) {
    setState(() {
      _alerts.removeAt(index);
    });
  }

  void _clearAllAlerts() {
    setState(() {
      _alerts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Alerts",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearAllAlerts,
            tooltip: "Clear All Alerts",
          ),
        ],
      ),
      body: _alerts.isEmpty
          ? Center(
              child: Text(
                "No alerts at the moment.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Dismissible(
                  key: Key(alert.title + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _removeAlert(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${alert.title} dismissed")),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.notification_important, color: Colors.red),
                      title: Text(alert.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert.message),
                          SizedBox(height: 4),
                          Text(
                            "Location: ${alert.location}",
                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
