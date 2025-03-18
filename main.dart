import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    String userRole = "admin";

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        userRole: userRole,
      ),
    );
  }
}
