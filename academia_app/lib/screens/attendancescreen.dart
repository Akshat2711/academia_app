import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // For haptics

import '../widgets/attendance_predict.dart';
import '../widgets/attendance_course_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Theme Colors
  static const Color _bgBlack = Color(0xFF0A0A0A);
  static const Color _navyBlue = Color(0xFF2C5F9E);
  static const Color _darkNavy = Color(0xFF1E4271);
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
      final raw = prefs.getString('userData');
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(raw);
        final overall = data['attendance']?['attendance'];
        if (overall != null) {
          setState(() {
            _overallAttendance = (overall['overall_attendance'] ?? 0).toDouble();
            _totalConducted = (overall['total_hours_conducted'] ?? 0).toInt();
            _totalAbsent = (overall['total_hours_absent'] ?? 0).toInt();

            final coursesMap = overall['courses'];
            if (coursesMap is Map) {
              _courses = coursesMap.entries.map((entry) {
                final v = entry.value;
                return {
                  'unique_id': entry.key,
                  'title': v['course_title'] ?? entry.key,
                  'category': (v['category'] ?? '').toString().split('(').first.trim(),
                  'conducted': (v['hours_conducted'] ?? 0).toInt(),
                  'absent': (v['hours_absent'] ?? 0).toInt(),
                  'percentage': (v['attendance_percentage'] ?? 0.0).toDouble(),
                };
              }).toList();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading: $e");
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
          style: TextStyle(fontWeight: FontWeight.w700, color: _white, letterSpacing: -0.5)
        ),
        backgroundColor: _bgBlack,
        elevation: 0,
        centerTitle: false,
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: _navyBlue)) 
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildOverallCard(),
                const SizedBox(height: 32),
                if (_courses.isNotEmpty) ...[
                  ..._courses.map((course) => CourseAttendanceCard(course: course)),
                ] else 
                  _buildEmptyState(),
                const SizedBox(height: 100), // Extra space for FAB and Nav
              ],
            ),
    );
  }




  Widget _buildOverallCard() {
    final present = _totalConducted - _totalAbsent;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navyBlue, _darkNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _navyBlue.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PROGRESS',
                    style: TextStyle(
                      color: _white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _overallAttendance.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '%',
                        style: TextStyle(
                          color: _white.withOpacity(0.4),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Status Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Glass Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                _buildStat('$_totalConducted', 'Conducted'),
                _buildVerticalDivider(),
                _buildStat('$present', 'Present'),
                _buildVerticalDivider(),
                _buildStat('$_totalAbsent', 'Absent'),
              ],
            ),

          ),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => AttendancePredictor(courses: _courses),
                ),
              );
            },
              icon: const Icon(Icons.line_axis, size: 18, color: Colors.white),
              label: const Text(
                'Predict Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 195, 190, 190).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              color: _white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _white.withOpacity(0.35),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.cloud_off_rounded, color: _white.withOpacity(0.15), size: 50),
          const SizedBox(height: 16),
          Text(
            'No attendance records found', 
            style: TextStyle(color: _white.withOpacity(0.3), fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}