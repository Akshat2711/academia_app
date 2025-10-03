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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                  if (_courses.isNotEmpty)
                    ..._courses.map((course) => _buildCourseCard(course))
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('No data found', style: TextStyle(color: Colors.grey[600])),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            '${_overallAttendance.toStringAsFixed(2)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverallStat('$_totalConducted', 'Conducted'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildOverallStat(present, 'Present'),
              Container(width: 1, height: 30, color: Colors.white24),
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
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final percentage = (course['percentage'] is num) ? (course['percentage'] as num).toDouble() : 0.0;
    Color color = Colors.red;
    if (percentage >= 85) color = Colors.green;
    else if (percentage >= 75) color = Colors.orange;

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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course['faculty'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
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
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
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
                    backgroundColor: Colors.grey[200],
                    color: color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.check_circle,
                      '${(course['conducted'] ?? 0) - (course['absent'] ?? 0)}',
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.cancel,
                      '${course['absent'] ?? 0}',
                      Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.book,
                      '${course['conducted'] ?? 0}',
                      Colors.blue,
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
  // No default attendance data: show 'No data found' when _courses is empty
