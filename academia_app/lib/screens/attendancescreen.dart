import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/attendance_predict.dart';

//for attendance graph 
import '../widgets/attendance_trend_widget.dart';

//FOR IOS LIKE TRANSITION
import 'package:flutter/cupertino.dart'; 

// ============================================================================
// ATTENDANCE SCREEN - Course-wise attendance details
// ============================================================================
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // --- BLUE SHADES ONLY COLOR PALETTE ---
  static const Color _bgBlack = Color(0xFF0A0A0A);
  static const Color _cardDarkGray = Color(0xFF1A1A1A);
  static const Color _navyBlue = Color(0xFF2C5F9E);
  static const Color _lightNavy = Color(0xFF4A7DC4);
  static const Color _skyBlue = Color(0xFF64B5F6);
  static const Color _deepBlue = Color(0xFF1565C0);
  static const Color _paleBlue = Color(0xFF90CAF9);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _whiteSecondary = Color(0xFFE8E8E8);

  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];
  double _overallAttendance = 0;
  int _totalConducted = 0;
  int _totalAbsent = 0;

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
                    'unique_id': key,
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
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _white,
            fontSize: 20,
          ),
        ),
        backgroundColor: _bgBlack,
        foregroundColor: _navyBlue,
        elevation: 0,
      ),
      floatingActionButton: _courses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => AttendancePredictor(courses: _courses),
                  ),
                );
              },
              backgroundColor: _navyBlue,
              foregroundColor: _white,
              icon: const Icon(Icons.timeline, size: 20),
              label: const Text(
                'Predict',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              elevation: 4,
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _navyBlue,
                strokeWidth: 3,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOverallCard(),
                const SizedBox(height: 28),
                Text(
                  'Course-wise Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _whiteSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (_courses.isNotEmpty)
                  ..._courses.map((course) => _buildCourseCard(course))
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No attendance data available',
                        style: TextStyle(
                          color: _white.withOpacity(0.4),
                          fontSize: 15,
                        ),
                      ),
                    ),
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
        gradient: LinearGradient(
          colors: [_navyBlue, _lightNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navyBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Attendance',
            style: TextStyle(
              color: _white.withOpacity(0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_overallAttendance.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: _white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverallStat('$_totalConducted', 'Conducted'),
                Container(width: 1, height: 32, color: _white.withOpacity(0.3)),
                _buildOverallStat(present, 'Present'),
                Container(width: 1, height: 32, color: _white.withOpacity(0.3)),
                _buildOverallStat('$_totalAbsent', 'Absent'),
              ],
            ),
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
            color: _white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final percentage = (course['percentage'] is num)
        ? (course['percentage'] as num).toDouble()
        : 0.0;

    final int conducted = course['conducted'] is num ? (course['conducted'] as num).toInt() : 0;
    final int absent = course['absent'] is num ? (course['absent'] as num).toInt() : 0;
    final int attended = (conducted - absent).clamp(0, conducted);

    // 75% Tracker logic - BLUE SHADES ONLY
    String targetText = '';
    Color targetColor = _navyBlue;
    IconData targetIcon = Icons.info_outline;

    if (conducted == 0) {
      targetText = 'No classes recorded';
      targetColor = _whiteSecondary.withOpacity(0.5);
    } else {
      final currentPct = (attended / conducted * 100);
      if (currentPct < 75.0) {
        final need = ((0.75 * conducted - attended) / 0.25).ceil().clamp(0, 999);
        targetText = need == 0
            ? 'Almost at 75%'
            : 'Attend $need more class${need > 1 ? 'es' : ''} to reach 75%';
        targetColor = const Color.fromARGB(255, 246, 100, 100); // Dark blue for warning
        targetIcon = Icons.trending_up;
      } else {
        final margin = ((attended / 0.75) - conducted).floor().clamp(0, 999);
        if (margin <= 0) {
          targetText = 'At 75% threshold — stay consistent';
          targetColor = const Color.fromARGB(255, 246, 180, 100); // Light navy for caution
          targetIcon = Icons.warning_amber_rounded;
        } else {
          targetText = 'Can miss $margin class${margin > 1 ? 'es' : ''} safely';
          targetColor = const Color.fromARGB(255, 222, 235, 246); // Sky blue for good
          targetIcon = Icons.trending_down;
        }
      }
    }

    // Color logic for progress bar - BLUE SHADES ONLY
    Color progressColor = _navyBlue;
    if (percentage >= 85) {
      progressColor = _skyBlue; // Light blue for excellent
    } else if (percentage >= 75) {
      progressColor = _lightNavy; // Medium blue for good
    } else {
      progressColor = _deepBlue; // Deep blue for low
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardDarkGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Percentage Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'],
                        style: const TextStyle(
                          color: _white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course['faculty'],
                        style: TextStyle(
                          color: _whiteSecondary.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: progressColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  widthFactor: (percentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [progressColor, progressColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info chips - BLUE SHADES ONLY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildModernChip(Icons.check_circle_outline, '$attended', 'Present', _skyBlue),
                _buildModernChip(Icons.cancel_outlined, '$absent', 'Absent', _deepBlue),
                _buildModernChip(Icons.library_books_outlined, '$conducted', 'Total', _navyBlue),
              ],
            ),

            const SizedBox(height: 16),

            // 75% tracker
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: targetColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: targetColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(targetIcon, color: targetColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      targetText,
                      style: TextStyle(
                        color: targetColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Attendance trend graph
            AttendanceTrendWidget(
              courseId: course['unique_id'],
              courseTitle: course['title'],
              currentPercentage: percentage,
              currentConducted: conducted,
              currentAbsent: absent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: _white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}