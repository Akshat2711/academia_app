import 'dart:convert';
import 'package:academia_app/screens/dasboardscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive_helper.dart';
import "../components/c_button.dart";
import "../components/c_text_field.dart";

import '../services/notification_service.dart';

class CLoginPage extends StatefulWidget {
  const CLoginPage({super.key});

  @override
  State<CLoginPage> createState() => _CLoginPageState();
}

class _CLoginPageState extends State<CLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://academia-scrapper-api-fast.onrender.com/scrape');
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    final body = jsonEncode({
      "email": email,
      "password": password,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', jsonEncode(data));
        
        // Save credentials for refresh functionality
        await prefs.setString('userEmail', email);
        await prefs.setString('userPassword', password);
        
        // Save last refresh time
        await prefs.setString('lastRefreshTime', DateTime.now().toIso8601String());

        // Navigate to next page (replace NextPage with your page)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(res.width(6)),
          child: ListView(
            children: [
              Image.asset("assets/login_img.png"),
              SizedBox(height: res.height(2)),
              Center(
                child: Text(
                  'Welcome to Console',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: res.fontSize(7),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              SizedBox(height: res.height(3)),

              // Email
              CTextField(controller: _emailController, hintTxt: "Email", ispass: false),
              SizedBox(height: res.height(2)),

              // Password
              CTextField(controller: _passwordController, hintTxt: "Password", ispass: true),
              SizedBox(height: res.height(4)),

              // Login Button
              CButton(
                text: _isLoading ? 'Logging in...' : 'Log In',
                onPressed: _isLoading ? null : loginUser,
              ),
              SizedBox(height: res.height(2)),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                    // Send a local notification
                            NotificationService.showNotification(
                              id: 0,
                              title: "Hello!",
                              body: "You clicked the notification icon.",
                            );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}