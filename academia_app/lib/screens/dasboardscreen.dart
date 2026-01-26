import 'package:flutter/material.dart';
import 'attendancescreen.dart';
import 'homescreens.dart';
import 'marksscreen.dart';
import 'timetablescreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  Key _attendanceKey = UniqueKey();
  Key _marksKey = UniqueKey();
  Key _timetableKey = UniqueKey();

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        onDataRefreshed: () {
          setState(() {
            _attendanceKey = UniqueKey();
            _marksKey = UniqueKey();
            _timetableKey = UniqueKey();
          });
        },
      ),
      AttendanceScreen(key: _attendanceKey),
      MarksScreen(key: _marksKey),
      TimetableScreen(key: _timetableKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Content flows behind the nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
      ////////debug screen///////////////////////////////////////////////////////
/*       floatingActionButton: FloatingActionButton(
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
    ), */
/////////////////////////////////////////////////////////////////////////////
    );
  }

  Widget _buildFloatingNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 15), // Floating margins
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: const Color.fromARGB(220, 18, 18, 18), // Solid dark matte
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 0, Colors.orange),
              _navItem(Icons.how_to_reg_rounded, 1, const Color(0xFF61A5DD)),
              _navItem(Icons.bar_chart_rounded, 2, const Color(0xFF9DF8A0)),
              _navItem(Icons.schedule_rounded, 3, const Color(0xFFFD3974)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, Color activeColor) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          tween: ColorTween(
            begin: Colors.white24,
            end: isSelected ? activeColor : Colors.white24,
          ),
          builder: (context, color, child) {
            return Icon(
              icon,
              color: color,
              size: 26, // Size remains strictly identical
            );
          },
        ),
      ),
    );
  }
}