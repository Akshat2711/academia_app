import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Custom imports
import 'attendancescreen.dart';
import 'homescreens.dart';
import 'marksscreen.dart';
import 'timetablescreen.dart';

//debug screen
import '../debug/debug_screen.dart';

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
////////debug screen///////////////////////////////////////////////////////
      floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.red,
      child: const Icon(Icons.bug_report),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SharedPrefsDebugScreen(),
          ),
        );
      },
    ),
/////////////////////////////////////////////////////////////////////////////
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          elevation: 0,
          backgroundColor: Colors.black, // 🖤 Black background
          indicatorColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2), 
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.home, color: Colors.orange),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.calendar_today, color: Color.fromARGB(255, 228, 159, 255)),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.grade_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.grade, color: Color.fromARGB(255, 157, 248, 160)),
              label: 'Marks',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.schedule, color: Color.fromARGB(255, 253, 57, 116)),
              label: 'Timetable',
            ),
          ],
        ),
      ),
    );
  }
}
