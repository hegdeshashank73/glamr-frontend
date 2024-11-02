import 'package:flutter/material.dart';
import 'screens/SubscriptionScreen.dart'; // Import SubscriptionScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glamr',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SubscriptionScreen(), // Set SubscriptionScreen as the home page
    );
  }
}
