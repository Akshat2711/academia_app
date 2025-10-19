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
  // --- COLOR PALETTE ---
  // Pitch Black Background
  static const Color _pitchBlack = Color(0xFF000000);
  // Neon Pink Accent
  static const Color _neonPink = Color(0xFFFF00FF);
  // White Foreground/Text
  static const Color _white = Colors.white;

  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];
  double _overallAttendance =0;
  int _totalConducted = 0;
  int _totalAbsent =0;
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
                    'unique_id':key,
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
    backgroundColor: _pitchBlack,
    appBar: AppBar(
      title: const Text(
        'Attendance',
        style: TextStyle(fontWeight: FontWeight.w600, color: _white),
      ),
      backgroundColor: _pitchBlack,
      foregroundColor: _neonPink,
      elevation: 0,
    ),
    // Add this FloatingActionButton
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
            backgroundColor: _neonPink,
            foregroundColor: _pitchBlack,
            icon: const Icon(Icons.timeline),
            label: const Text(
              'Predict',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        : null,
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _neonPink))
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
                  color: _white,
                ),
              ),
              const SizedBox(height: 12),
              if (_courses.isNotEmpty)
                ..._courses.map((course) => _buildCourseCard(course))
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No data found',
                    style: TextStyle(color: _white.withOpacity(0.6)),
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
      // 👇 Switched to Pink background color
      color: const Color.fromARGB(255, 254, 112, 254), // New Background for the card
      borderRadius: BorderRadius.circular(20),
      // 💡 Updated border to White
      border: Border.all(color: const Color.fromARGB(255, 255, 112, 226).withOpacity(0.7), width: 1.5), // White border
      
    ),
    child: Column(
      children: [
        Text(
          'Overall Attendance',
          // 💡 Text color changed to Black (or a dark color) for contrast on pink
          style: TextStyle(color: _pitchBlack.withOpacity(0.8), fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          '${_overallAttendance.toStringAsFixed(2)}%',
          // 👇 Switched to White text color for the main value
          style: const TextStyle(
            color: _white, // Main value color changed to White
            fontSize: 48,
            fontWeight: FontWeight.bold,

          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Note: _buildOverallStat needs to handle the new text color inside it,
            // or you'll have to show its implementation to change its text color.
            _buildOverallStat('$_totalConducted', 'Conducted'),
            // 💡 Divider color updated to White
            Container(width: 1.5, height: 30, color: _white.withOpacity(0.5)),
            _buildOverallStat(present, 'Present'),
            // 💡 Divider color updated to White
            Container(width: 1.5, height: 30, color: _white.withOpacity(0.5)),
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
  final percentage = (course['percentage'] is num)
      ? (course['percentage'] as num).toDouble()
      : 0.0;

  final int conducted = course['conducted'] is num ? (course['conducted'] as num).toInt() : 0;
  final int absent = course['absent'] is num ? (course['absent'] as num).toInt() : 0;
  final int attended = (conducted - absent).clamp(0, conducted);

  // Target tracker vars
  String targetText = '';
  Color targetColor = _neonPink;
  IconData targetIcon = Icons.info_outline;

  if (conducted == 0) {
    targetText = 'No classes recorded';
    targetColor = Colors.grey;
    targetIcon = Icons.info_outline;
  } else {
    final double currentPct = conducted > 0 ? (attended / conducted * 100) : 0.0;

    if (currentPct < 75.0) {
      // Need to attend x more classes (attend all of them) to reach 75%
      final double rawNeeded = (0.75 * conducted - attended) / 0.25; // can be large
      final int need = rawNeeded <= 0 ? 0 : rawNeeded.ceil();
      targetIcon = Icons.trending_up;
      targetColor = Colors.redAccent;
      targetText = need == 0
          ? 'Almost at 75%'
          : 'Attend $need more class${need > 1 ? 'es' : ''} to reach 75%';
    } else {
      // Can miss up to m classes (attended unchanged) and remain >= 75%
      final double rawMargin = (attended / 0.75) - conducted;
      final int margin = rawMargin < 0 ? 0 : rawMargin.floor();

      if (margin <= 0) {
        targetIcon = Icons.error_outline;
        targetColor = const Color.fromARGB(255, 255, 255, 255);
        targetText = 'At 75% threshold — avoid missing classes';
      } else {
        targetIcon = Icons.trending_down;
        targetColor = const Color.fromARGB(255, 251, 218, 255);
        targetText = 'Can miss $margin class${margin > 1 ? 'es' : ''} and stay ≥75%';
      }
    }
  }

  // --- Color logic for the card chip (keeps your previous theme) ---
  Color color = _neonPink;
  Color chipBackgroundColor = _neonPink.withOpacity(0.1);
  if (percentage >= 85) {
    color = const Color.fromARGB(255, 221, 54, 255);
  } else if (percentage >= 75) {
    color = const Color.fromARGB(255, 239, 197, 246);
  }
  chipBackgroundColor = color.withOpacity(0.1);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.5), width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.15),
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
              // Title & percent chip
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
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course['faculty'],
                          style: TextStyle(fontSize: 13, color: _white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: chipBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: _white.withOpacity(0.1),
                  color: color,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 12),

              // Info chips: Present / Absent / Conducted
              Row(
                children: [
                  _buildInfoChip(Icons.check_circle, '$attended', const Color.fromARGB(255, 243, 136, 255)),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.cancel, '$absent', const Color.fromARGB(255, 192, 150, 192)),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.book, '$conducted', const Color.fromARGB(255, 241, 242, 242)),
                ],
              ),

              const SizedBox(height: 10),

              // New: 75% tracker line
              Row(
                children: [
                  Icon(targetIcon, size: 16, color: targetColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      targetText,
                      style: TextStyle(color: targetColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
//graph widget trend:
              AttendanceTrendWidget(
                courseId: course['unique_id'], // Use unique ID if available
                courseTitle: course['title'],
                currentPercentage: percentage,
                currentConducted: conducted,
                currentAbsent: absent,
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