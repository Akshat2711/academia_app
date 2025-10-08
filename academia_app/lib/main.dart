import 'package:academia_app/screens/login_page.dart';
import 'package:academia_app/screens/dasboardscreen.dart';
import 'package:academia_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
//for firestore->
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen visible until setup is done
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize notifications and local storage
  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();
  final String? userData = prefs.getString('userData');

  // Remove splash once setup completes
  FlutterNativeSplash.remove();

  //firestore initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 auto setup
  );

  // Run app
  runApp(MyApp(isLoggedIn: userData != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

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
      home: isLoggedIn ? const DashboardScreen() : const CLoginPage(),
    );
  }
}
