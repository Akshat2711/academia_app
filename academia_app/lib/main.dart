import 'package:academia_app/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

//custom imports
import 'screens/dasboardscreen.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academia',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      /* home: const DashboardScreen(), */
      home: const CLoginPage(),
    );
  }
}

