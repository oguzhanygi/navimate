import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NaviMateApp());
}

class NaviMateApp extends StatelessWidget {
  const NaviMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'NaviMate',
      home: HomeScreen(),
    );
  }
}
