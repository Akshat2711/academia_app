import 'dart:convert';
import 'package:academia_app/screens/dasboardscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive_helper.dart';
import '../utils/day_order_backup.dart'; // Import the day order manager

class CLoginPage extends StatefulWidget {
  const CLoginPage({super.key});

  @override
  State<CLoginPage> createState() => _CLoginPageState();
}

class _CLoginPageState extends State<CLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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

        // ✅ Handle day order (from API or backup)
        int? dayOrder;
        if (data['attendance'] != null && data['attendance']['day_order'] != null) {
          // Day order present in API response
          dayOrder = data['attendance']['day_order'] as int;
          print('✅ Day order from API: $dayOrder');
          
          // Save day order with forecast
          await DayOrderManager.saveDayOrderData(
            currentDayOrder: dayOrder,
            currentDate: DateTime.now(),
          );
        } else {
          // Day order missing from API, use backup
          print('⚠️ Day order missing from API response');
          dayOrder = await DayOrderManager.getCurrentDayOrder();
          
          if (dayOrder != null) {
            print('✅ Using backup day order: $dayOrder');
            // Add day order to data for dashboard
            data['attendance'] = data['attendance'] ?? {};
            data['attendance']['day_order'] = dayOrder;
          } else {
            print('⚠️ No backup day order available');
          }
        }

        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', jsonEncode(data));
        await prefs.setString('userEmail', email);
        await prefs.setString('userPassword', password);
        await prefs.setString('lastRefreshTime', DateTime.now().toIso8601String());

        // Show success message with day order info
        if (mounted) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${response.body}'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(res.width(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Login Image at Top
              Image.asset("assets/login_img.png"),
              SizedBox(height: res.height(4)),

              // Welcome Text
              Text(
                'Welcome to Academia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: res.fontSize(7),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Console',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: res.fontSize(7),
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 30, 70, 162),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: res.height(1)),
              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: res.fontSize(3.8),
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: res.height(4)),

              // Email Field
              _buildTextField(
                controller: _emailController,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                res: res,
              ),
              SizedBox(height: res.height(2.5)),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: _obscurePassword,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                res: res,
              ),
              SizedBox(height: res.height(4)),

              // Login Button
              _buildLoginButton(res),
              SizedBox(height: res.height(3)),

              // Footer
              Center(
                child: Text(
                  'Secure authentication',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: res.fontSize(3.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ResponsiveHelper res,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.black,
          fontSize: res.fontSize(4),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: res.fontSize(4),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: res.width(5.5),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[600],
                    size: res.width(5.5),
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: res.width(4),
            vertical: res.height(2.2),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(ResponsiveHelper res) {
    return Container(
      height: res.height(7),
      decoration: BoxDecoration(
        color: _isLoading ? Colors.grey[300] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : loginUser,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: res.width(6),
                    height: res.width(6),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: res.fontSize(4.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}