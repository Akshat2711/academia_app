import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//custom imports
import 'attendancescreen.dart';
import 'homescreens.dart';
import 'marksscreen.dart';
import 'timetablescreen.dart';

// ============================================================================
// DASHBOARD SCREEN - Main navigation container
// ============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AttendanceScreen(),
    const MarksScreen(),
    const TimetableScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _printStoredData();
  }

  // Function to check and print stored data
  Future<void> _printStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userData')) {
      final data = prefs.getString('userData');
      print("Stored user data: $data");
    } else {
      print("No user data found in storage.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF6366F1).withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.grade_outlined),
              selectedIcon: Icon(Icons.grade),
              label: 'Marks',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Timetable',
            ),
          ],
        ),
      ),
    );
  }
}
