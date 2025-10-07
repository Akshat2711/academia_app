import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// ATTENDANCE SCREEN - Course-wise attendance details
// ============================================================================
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // --- COLOR PALETTE ---
  // Pitch Black Background
  static const Color _pitchBlack = Color(0xFF000000);
  // Neon Pink Accent
  static const Color _neonPink = Color(0xFFFF00FF);
  // White Foreground/Text
  static const Color _white = Colors.white;

  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];
  double _overallAttendance = 91.38;
  int _totalConducted = 232;
  int _totalAbsent = 20;
  // When attendance data is missing, leave values as-is but UI will show 'No data found'

  @override
  void initState() {
    super.initState();
    _loadAttendanceFromPrefs();
  }

  Future<void> _loadAttendanceFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('userData')) {
        final raw = prefs.getString('userData');
        if (raw != null && raw.isNotEmpty) {
          final Map<String, dynamic> data = json.decode(raw);
          final attendanceRoot = data['attendance'];
          if (attendanceRoot != null) {
            // overall
            final overall = attendanceRoot['attendance'] ?? {};
            setState(() {
              _overallAttendance = (overall['overall_attendance'] is num)
                  ? (overall['overall_attendance'] as num).toDouble()
                  : _overallAttendance;
              _totalConducted = (overall['total_hours_conducted'] is int)
                  ? overall['total_hours_conducted'] as int
                  : (overall['total_hours_conducted'] is num)
                      ? (overall['total_hours_conducted'] as num).toInt()
                      : _totalConducted;
        _totalAbsent = (overall['total_hours_absent'] is int)
          ? overall['total_hours_absent'] as int
          : (overall['total_hours_absent'] is num)
            ? (overall['total_hours_absent'] as num).toInt()
            : _totalAbsent;
            });

            final coursesMap = overall['courses'];
            final List<Map<String, dynamic>> parsed = [];
            if (coursesMap is Map) {
              coursesMap.forEach((key, value) {
                if (value is Map) {
                  parsed.add({
                    'title': value['course_title'] ?? key,
                    'faculty': (value['faculty_name'] ?? '').toString().split('(').first.trim(),
                    'conducted': value['hours_conducted'] is num ? (value['hours_conducted'] as num).toInt() : 0,
                    'absent': value['hours_absent'] is num ? (value['hours_absent'] as num).toInt() : 0,
                    'percentage': value['attendance_percentage'] is num ? (value['attendance_percentage'] as num).toDouble() : 0.0,
                  });
                }
              });
            }

            if (parsed.isNotEmpty) {
              setState(() {
                _courses = parsed;
              });
            }
          }
        }
      }
    } catch (e) {
      // ignore and fall back to defaults
    } finally {
      // Do not populate with default sample data; leave empty to indicate missing data
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pitchBlack, // ⬅️ Changed to pitch black
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.w600, color: _white), // ⬅️ White text
        ),
        backgroundColor: _pitchBlack, // ⬅️ Changed to pitch black
        foregroundColor: _neonPink, // ⬅️ Neon Pink for icons/buttons
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _neonPink)) // ⬅️ Neon Pink loading indicator
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverallCard(),
                const SizedBox(height: 20),
                Text(
                  'Course-wise Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _white, // ⬅️ White text
                  ),
                ),
                const SizedBox(height: 12),
                  if (_courses.isNotEmpty)
                    ..._courses.map((course) => _buildCourseCard(course))
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('No data found', style: TextStyle(color: _white.withOpacity(0.6))), // ⬅️ White text
                    ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildOverallCard() {
    final present = (_totalConducted - _totalAbsent).toString();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Neon Pink Glow Effect
        color: _pitchBlack, // Background for the card
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _neonPink.withOpacity(0.5), // ⬅️ Neon Pink shadow
            blurRadius: 25,
            spreadRadius: -5,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: _neonPink.withOpacity(0.3), // Secondary glow
            blurRadius: 50,
            spreadRadius: -10,
            offset: const Offset(0, 0),
          ),
        ],
        border: Border.all(color: _neonPink.withOpacity(0.7), width: 1.5), // Neon Pink border
      ),
      child: Column(
        children: [
          Text(
            'Overall Attendance',
            style: TextStyle(color: _white.withOpacity(0.8), fontSize: 16), // ⬅️ White text
          ),
          const SizedBox(height: 12),
          Text(
            '${_overallAttendance.toStringAsFixed(2)}%',
            style: const TextStyle(
              color: _neonPink, // ⬅️ Neon Pink for main value
              fontSize: 48,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: _neonPink,
                  offset: Offset(0, 0),
                ),
              ]
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverallStat('$_totalConducted', 'Conducted'),
              Container(width: 1.5, height: 30, color: _neonPink.withOpacity(0.5)), // ⬅️ Neon Pink divider
              _buildOverallStat(present, 'Present'),
              Container(width: 1.5, height: 30, color: _neonPink.withOpacity(0.5)), // ⬅️ Neon Pink divider
              _buildOverallStat('$_totalAbsent', 'Absent'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _white, // ⬅️ White for stat values
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: _white.withOpacity(0.7), fontSize: 12), // ⬅️ White for stat labels
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final percentage = (course['percentage'] is num) ? (course['percentage'] as num).toDouble() : 0.0;
    
    // --- Custom Neon-themed Color Logic ---
    Color color = _neonPink; // Default/Bad attendance color
    Color chipBackgroundColor = _neonPink.withOpacity(0.1);
    
    if (percentage >= 85) {
      color = const Color.fromARGB(255, 221, 54, 255); // Neon Green for Excellent (>= 85%)
    } else if (percentage >= 75) {
      color = const Color.fromARGB(255, 239, 197, 246); // Neon Yellow/Orange for OK (>= 75%)
    }
    chipBackgroundColor = color.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _pitchBlack, // ⬅️ Pitch Black Card Background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1), // Colored border based on percentage
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15), // Soft glow based on percentage
            blurRadius: 15,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
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
                            course['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _white, // ⬅️ White text
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course['faculty'],
                            style: TextStyle(
                              fontSize: 13,
                              color: _white.withOpacity(0.6), // ⬅️ White text
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: chipBackgroundColor, // Use color-specific background
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color, width: 1), // Solid border
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color, // Text color matches glow
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: _white.withOpacity(0.1), // ⬅️ Subtle white track
                    color: color, // Progress bar color based on percentage
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.check_circle,
                      '${(course['conducted'] ?? 0) - (course['absent'] ?? 0)}',
                      const Color(0xFF00FFC0), // Neon Green for Present
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.cancel,
                      '${course['absent'] ?? 0}',
                      _neonPink, // Neon Pink for Absent
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.book,
                      '${course['conducted'] ?? 0}',
                      const Color.fromARGB(255, 241, 242, 242), // Neon Blue for Conducted
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}