import 'package:flutter/material.dart';

class SupportSection extends StatelessWidget {
 const SupportSection({super.key});

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: Padding(
       padding: EdgeInsets.all(16.0),
       child: Column(
         children: [
           Card(
             child: ListTile(
               title: Text(
                 'View FAQs',
                 style: TextStyle(
                   fontSize: 16.0,
                 ),
               ),
               trailing: Icon(Icons.arrow_forward_ios, size: 16),
               onTap: () {
                 // Handle FAQ tap
               },
             ),
           ),
           SizedBox(height: 16.0),
           Card(
             child: ListTile(
               title: Text(
                 'Contact Support',
                 style: TextStyle(
                   fontSize: 16.0,
                 ),
               ),
               trailing: Icon(Icons.arrow_forward_ios, size: 16),
               onTap: () {
                 // Handle Contact Support tap
               },
             ),
           ),
         ],
       ),
     ),
   );
 }
}