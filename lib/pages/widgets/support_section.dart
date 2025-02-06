import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {'subject': 'Support Inquiry'},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email';
    }
  }

  void _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse("https://wa.me/1234567890");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  void _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '1234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not make a phone call';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Contact via Email'),
                trailing: Icon(Icons.email, color: Colors.red), // Gmail red color
                onTap: _launchEmail,
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Contact via WhatsApp'),
                trailing: Icon(Icons.message, color: Color(0xFF25D366)), // WhatsApp green
                onTap: _launchWhatsApp,
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Call Support'),
                trailing: Icon(Icons.phone),
                onTap: _makePhoneCall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
