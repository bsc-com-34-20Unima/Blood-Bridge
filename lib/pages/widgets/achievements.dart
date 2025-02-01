import 'package:flutter/material.dart';

class Achievements extends StatelessWidget {
 const Achievements({super.key});

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: Padding(
       padding: EdgeInsets.all(16.0),
       child: Column(
         children: [
           Card(
             child: ListTile(
               leading: CircleAvatar(
                 backgroundColor: Color.fromARGB(255, 255, 243, 194), // Light yellow background
                 child: Icon(
                   Icons.emoji_events,
                   color: Colors.amber, // Trophy color
                 ),
               ),
               title: Text(
                 'Regular Donor',
                 style: TextStyle(
                   fontSize: 16.0,
                   fontWeight: FontWeight.w500,
                 ),
               ),
               subtitle: Text(
                 '5+ donations',
                 style: TextStyle(
                   color: Colors.grey,
                 ),
               ),
             ),
           ),
         ],
       ),
     ),
   );
 }
}