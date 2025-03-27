import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  final List<Map<String, String>> events = [
    {
      "title": "Community Blood Drive",
      "date": "2025-01-30",
      "location": "City Hall, Blantyre",
      "description": "Join us for a community blood drive and save lives.",
    },
    {
      "title": "Youth Awareness Campaign",
      "date": "2025-02-10",
      "location": "Lilongwe University",
      "description": "Raising awareness among youths about blood donation.",
    },
    {
      "title": "Health Fair Blood Drive",
      "date": "2025-02-20",
      "location": "Mzuzu Stadium",
      "description": "A health fair focused on blood donation and public health.",
    },
  ];

   EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Add Event"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _showAddEventDialog(context);
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Icon(Icons.event, color: Colors.red),
                      ),
                      title: Text(
                        event['title']!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text("Date: ${event['date']}"),
                          Text("Location: ${event['location']}"),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.info, color: Colors.grey),
                        onPressed: () {
                          _showEventDetailsDialog(context, event);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "City General Hospital",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.red),
              title: Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: Icon(Icons.bloodtype, color: Colors.red),
              title: Text("Blood Inventory"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/bloodInventory');
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.red),
              title: Text("Donors"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/donors');
              },
            ),
            ListTile(
              leading: Icon(Icons.list, color: Colors.red),
              title: Text("Requests"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/requests');
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.red),
              title: Text("Events"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetailsDialog(BuildContext context, Map<String, String> event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event['title']!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Date: ${event['date']}"),
              SizedBox(height: 4),
              Text("Location: ${event['location']}"),
              SizedBox(height: 8),
              Text(event['description']!),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Event"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: "Event Title"),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(labelText: "Event Date"),
                ),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: "Location"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: "Description"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text("Add"),
              onPressed: () {
                // Add functionality to save the event
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
