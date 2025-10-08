import 'package:flutter/material.dart';

/// FacultyInfo widget
///
/// Renders the faculty advisor and academic advisor cards. Accepts an
/// optional `advisors` map with keys `faculty_advisor` and
/// `academic_advisor` (each a map with `name`, `email`, `phone`). If
/// not provided, it falls back to sensible defaults.
class FacultyInfo extends StatelessWidget {
  final Map<String, dynamic>? advisors;

  const FacultyInfo({Key? key, this.advisors}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fa = advisors != null ? advisors!['faculty_advisor'] : null;
    final aa = advisors != null ? advisors!['academic_advisor'] : null;

    // If advisors or specific fields are missing, show 'No data found'
    final faName = fa != null && fa is Map ? (fa['name']?.toString() ?? 'No data found') : 'No data found';
    final faEmail = fa != null && fa is Map ? (fa['email']?.toString() ?? 'No data found') : 'No data found';
    final faPhone = fa != null && fa is Map ? (fa['phone']?.toString() ?? 'No data found') : 'No data found';

    final aaName = aa != null && aa is Map ? (aa['name']?.toString() ?? 'No data found') : 'No data found';
    final aaEmail = aa != null && aa is Map ? (aa['email']?.toString() ?? 'No data found') : 'No data found';
    final aaPhone = aa != null && aa is Map ? (aa['phone']?.toString() ?? 'No data found') : 'No data found';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 0, 0, 0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Faculty Advisors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _advisorInfo('Faculty Advisor', faName, faEmail, faPhone),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _advisorInfo('Academic Advisor', aaName, aaEmail, aaPhone),
        ],
      ),
    );
  }

  Widget _advisorInfo(String role, String name, String email, String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.email, color: Colors.white70, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.phone, color: Colors.white70, size: 14),
            const SizedBox(width: 8),
            Text(
              phone,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
