import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// --- Your Actual Screen Imports ---
import '../screens/cgpa_calculator.dart';
import '../screens/calender_screen.dart'; 
import '../screens/annoucement_screen.dart';
import '../screens/imp_links_screen.dart';
import '../screens/studymaterial_screen.dart';
import '../screens/mess_menu_screen.dart';
import '../screens/nearby_chat_screen.dart';

class QuickActions extends StatelessWidget {
  final Color primaryColor;
  const QuickActions({super.key, required this.primaryColor});

  // Minimalist Theme Constants
  static const Color cardBg = Color(0xFF121212); // Deep Charcoal (Cleaner than pure black)
  static const Color borderCol = Color(0xFF252525); // Subtle elevation stroke
  static const double radius = 24.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 20, top: 10),
          child: Text(
            ' Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),

        // --- SECTION 1: BENTO GRID (Flexible Heights) ---
        IntrinsicHeight( // Ensures both columns match height automatically
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildActionCard(
                  context,
                  icon: Icons.menu_book_rounded,
                  title: 'Study\nMaterial',
                  subtitle: 'Notes & PYQs',
                  color: Colors.orange,
                  target: const MaterialsScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildSmallCard(
                      context,
                      icon: Icons.calendar_today_rounded,
                      title: 'Calendar',
                      color: const Color(0xFFE96BAE),
                      target: const CalendarScreen(),
                    ),
                    const SizedBox(height: 12),
                    _buildSmallCard(
                      context,
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Nearby',
                      color: Colors.white,
                      target: const NearbyChatScreen(),
                     
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // --- SECTION 2: ANNOUNCEMENT BANNER ---
        _buildBanner(
          context,
          icon: Icons.announcement_rounded,
          title: 'Campus Announcements',
          subtitle: 'Latest news and official updates',
          color: const Color(0xFF4ACDF5),
          target: const AnnouncementScreen(),
        ),

        const SizedBox(height: 12),

        // --- SECTION 3: UTILITY ROW ---
        Row(
          children: [
            _buildUtilityTile(context, Icons.calculate_rounded, 'CGPA', const Color(0xFFFD3974), const CGPACalculator()),
            const SizedBox(width: 12),
            _buildUtilityTile(context, Icons.restaurant_rounded, 'Mess', const Color(0xFF9DF8A0), const MessMenuScreen()),
            const SizedBox(width: 12),
            _buildUtilityTile(context, Icons.link_rounded, 'Links', const Color(0xFF61A5DD), const LinksScreen()),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Large Bento Item
  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required Widget target}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => target)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, height: 1.2)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Small Bento Item
  Widget _buildSmallCard(BuildContext context, {required IconData icon, required String title, required Color color, required Widget target, bool isGlass = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => target)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isGlass ? Colors.white.withOpacity(0.05) : cardBg,
            borderRadius: BorderRadius.circular(radius - 4),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // Wide Banner
  Widget _buildBanner(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required Widget target}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => target)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color.fromARGB(237, 66, 68, 68).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  // Compact Bottom Row
  Widget _buildUtilityTile(BuildContext context, IconData icon, String title, Color color, Widget target) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => target)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}