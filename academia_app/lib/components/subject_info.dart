import 'package:flutter/material.dart';
import '../screens/course_summary_screen.dart';
//FOR IOS LIKE TRANSITION
import 'package:flutter/cupertino.dart'; 
import 'package:flutter/services.dart';

// Define custom colors for the new minimalist dark theme
const Color accentOrange = Color.fromRGBO(255, 162, 22, 0.942); // Used for text/accents
const Color darkBackground = Color(0xFF121212); // Primary pitch black background
const Color cardBackground = Color(0xFF121212); // Subtle variant of black for the card

// A reusable course card used by TimetableScreen and other places.
class SubjectInfo extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback? onTap;

  const SubjectInfo({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (course['title'] ?? course['course_title'] ?? '').toString();
    final code = (course['code'] ?? course['course_code'] ?? '').toString();
    final credits = course['credits'] is num
        ? (course['credits'] as num).toString()
        : (course['credit'] ?? '').toString();
    final faculty = (course['faculty'] ?? course['faculty_name'] ?? '').toString();
    final room = (course['room'] ?? course['room_no'] ?? '').toString();
    final category = (course['category'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground, // Subtle dark grey background
        borderRadius: BorderRadius.circular(24), // Slightly softer corners
        // Removed border color and box shadow for a cleaner, flatter look
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to CourseDetailScreen
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => CourseDetailScreen(courseCode: code),
              ),
            );
            // Also call the custom onTap if provided
            onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP ROW: Title, Code, and Credits ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17, // Slightly larger title
                              fontWeight: FontWeight.w600, // Medium bold
                              color: Colors.white, // White for primary text
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 13,
                              color: accentOrange.withOpacity(0.8), // Muted orange for code
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Credits Chip (Right side)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reduced vertical padding
                      decoration: BoxDecoration(
                        color: accentOrange.withOpacity(0.1), // Very subtle orange background
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        '$credits Credits',
                        style: const TextStyle(
                          color: accentOrange, // Strong orange for accent text
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                // Subtle Divider
                const Divider(height: 1, color: Color(0xFF333333)),
                const SizedBox(height: 16),

                // --- DETAIL ROWS: Faculty, Slot, Room, Category ---
                
                // Faculty
                _buildCourseDetailRow(Icons.person_outline, 'Faculty:', faculty),
                const SizedBox(height: 10),

                // Slot and Room (side-by-side)
                Row(
                  children: [
                    if (room.isNotEmpty)
                      Expanded(child: _buildCourseDetailRow(Icons.room_outlined, 'Room:', room)),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Category
                _buildCourseDetailRow(Icons.category_outlined, 'Category:', category),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDetailRow(IconData icon, String label, String value) {
    // Check if the value is empty to avoid rendering unnecessary rows
    if (value.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, size: 16, color: accentOrange), // Orange icon
        const SizedBox(width: 8),
        // Label (White, secondary color)
        Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70, 
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(width: 4),
        // Value (Orange, accent color)
        Expanded(
          child: Text(
            value.trim(),
            style: const TextStyle(
              fontSize: 13,
              color: accentOrange,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}