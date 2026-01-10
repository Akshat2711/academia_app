import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Your Actual Screen Imports
import '../screens/cgpa_calculator.dart';
import '../screens/calender_screen.dart'; 
import '../screens/annoucement_screen.dart';
import '../screens/imp_links_screen.dart';
import '../screens/studymaterial_screen.dart';
import '../screens/mess_menu_screen.dart';

class QuickActions extends StatelessWidget {
  final Color primaryColor;

  const QuickActions({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Constrain the column size
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        GridView.count(
          padding: EdgeInsets.zero, // Remove default grid padding
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6, // Slightly wider to reduce vertical dead space
          children: [
            _buildActionTile(
              context,
              Icons.menu_book_rounded,
              'Study\nMaterial',
              Colors.orange,
              const MaterialsScreen(),
            ),
            _buildActionTile(
              context,
              Icons.link_rounded,
              'Important\nLinks',
              const Color(0xFF61A5DD),
              const LinksScreen(),
            ),
            _buildActionTile(
              context,
              Icons.calendar_today_rounded,
              'Event\nCalendar',
              const Color(0xFF9DF8A0),
              const CalendarScreen(),
            ),
            _buildActionTile(
              context,
              Icons.calculate_rounded,
              'CGPA\nCalculator',
              const Color(0xFFFD3974),
              const CGPACalculator(),
            ),
          ],
        ),
        const SizedBox(height: 12), // Controlled small gap
        _buildActionTile(
          context,
          Icons.announcement_rounded,
          'Announcements',
          primaryColor,
          const AnnouncementScreen(),
          isFullWidth: true,
        ),
        const SizedBox(height: 12), // Controlled small gap
        _buildActionTile(
          context,
          Icons.restaurant_menu_rounded,
          'Mess Menu',
          const Color.fromARGB(255, 233, 107, 174),
          const MessMenuScreen(),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    Color accentColor,
    Widget targetScreen, {
    bool isFullWidth = false,
  }) {
    return Container(
      // If full width, we ensure it doesn't try to expand to an aspect ratio
      height: isFullWidth ? 70 : null, 
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => targetScreen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: isFullWidth 
                ? Row(
                    children: [
                      _iconBox(icon, accentColor),
                      const SizedBox(width: 16),
                      Expanded( // Added expanded to prevent overflow
                        child: Text(
                          title,
                          style: _textStyle(),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Center items vertically
                    children: [
                      _iconBox(icon, accentColor),
                      const Spacer(), // Pushes text to the bottom
                      Text(
                        title,
                        style: _textStyle(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  TextStyle _textStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.1,
    );
  }
}