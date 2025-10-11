import 'package:academia_app/screens/login_page.dart';
import 'package:academia_app/screens/dasboardscreen.dart';
import 'package:academia_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
//for firestore->
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Add timezone imports
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen visible until setup is done
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize timezones BEFORE initializing notifications
  tz.initializeTimeZones();
  // Set to India timezone (Kallakurichi, Tamil Nadu)
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  
  // Verify timezone is set correctly
  print('Timezone set to: ${tz.local.name}');
  print('Current time in local timezone: ${tz.TZDateTime.now(tz.local)}');

  // Initialize notifications and local storage
  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();
  final String? userData = prefs.getString('userData');

  //firestore initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 auto setup
  );

  // Remove splash once setup completes
  FlutterNativeSplash.remove();

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
      title: 'Console',
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