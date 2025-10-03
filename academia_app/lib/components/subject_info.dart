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
    final credits = course['credits'] is num ? (course['credits'] as num).toString() : (course['credits'] ?? '').toString();
    final faculty = (course['faculty'] ?? '').toString();
    final slot = (course['slot'] ?? '').toString();
    final room = (course['room'] ?? '').toString();
    final category = (course['category'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$credits Credits',
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
