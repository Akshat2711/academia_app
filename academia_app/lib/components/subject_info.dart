import 'package:flutter/material.dart';

// A reusable course card used by TimetableScreen and other places.
class SubjectInfo extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback? onTap;

  const SubjectInfo({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (course['title'] ?? '').toString();
    final code = (course['code'] ?? '').toString();
    final credits = course['credits'] is num
        ? (course['credits'] as num).toString()
        : (course['credits'] ?? '').toString();
    final faculty = (course['faculty'] ?? '').toString();
    final slot = (course['slot'] ?? '').toString();
    final room = (course['room'] ?? '').toString();
    final category = (course['category'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black, // 🖤 Background changed to black
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2), // 🟠 Orange border
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255), // 🟠 Orange text
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange, // 🟠 Orange text
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Text(
                        '$credits Credits',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255), // 🟠 Orange text
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.orange), // 🟠 Orange divider
                const SizedBox(height: 12),
                _buildCourseDetailRow(Icons.person, faculty),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCourseDetailRow(Icons.schedule, slot)),
                    if (room.isNotEmpty)
                      Expanded(child: _buildCourseDetailRow(Icons.room, room)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCourseDetailRow(Icons.category, category),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color.fromARGB(255, 255, 255, 255)), // 🟠 Icon color
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.orange, // 🟠 Text color
            ),
          ),
        ),
      ],
    );
  }
}
