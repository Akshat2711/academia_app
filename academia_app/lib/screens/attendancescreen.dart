import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

import '../widgets/attendance_predict.dart';
import '../widgets/attendance_course_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color _bgBlack = Color(0xFF0A0A0A);
  static const Color _navyBlue = Color(0xFF2C5F9E);
  static const Color _lightNavy = Color(0xFF4A7DC4);
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
        title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.w600, color: _white)),
        backgroundColor: _bgBlack,
        elevation: 0,
      ),
      floatingActionButton: _courses.isNotEmpty ? _buildFab() : null,
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: _navyBlue)) 
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOverallCard(),
                const SizedBox(height: 28),
                if (_courses.isNotEmpty) ...[
                  const Text('Course-wise Details', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _whiteSecondary)),
                  const SizedBox(height: 16),
                  ..._courses.map((course) => CourseAttendanceCard(course: course)),
                ] else 
                  _buildEmptyState(),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, CupertinoPageRoute(
          builder: (context) => AttendancePredictor(courses: _courses))),
        backgroundColor: _navyBlue,
        foregroundColor: _white,
        icon: const Icon(Icons.timeline, size: 20),
        label: const Text('Predict', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildOverallCard() {
    final present = (_totalConducted - _totalAbsent).toString();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_navyBlue, _lightNavy], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('Overall Attendance', style: TextStyle(color: _white.withOpacity(0.9), fontSize: 15)),
          const SizedBox(height: 16),
          Text('${_overallAttendance.toStringAsFixed(1)}%', 
            style: const TextStyle(color: _white, fontSize: 52, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('$_totalConducted', 'Conducted'),
                Container(width: 1, height: 32, color: _white.withOpacity(0.3)),
                _buildStat(present, 'Present'),
                Container(width: 1, height: 32, color: _white.withOpacity(0.3)),
                _buildStat('$_totalAbsent', 'Absent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(children: [
      Text(val, style: const TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: _white.withOpacity(0.7), fontSize: 12)),
    ]);
  }

  Widget _buildEmptyState() {
    return Column(children: [
      const SizedBox(height: 24),
      Icon(Icons.folder_off_rounded, color: _white.withOpacity(0.35), size: 40),
      const SizedBox(height: 10),
      Text('No attendance data available', style: TextStyle(color: _white.withOpacity(0.4))),
    ]);
  }
}