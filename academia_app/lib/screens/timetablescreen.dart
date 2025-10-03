import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// TIMETABLE SCREEN - Course schedule and faculty details
// ============================================================================
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];
  Map<String, dynamic> _advisors = {
    'faculty_advisor': {'name': 'Dr.S.Praveenkumar', 'email': 'praveens11@srmist.edu.in', 'phone': '9444022268'},
    'academic_advisor': {'name': 'Dr.T.Karthick', 'email': 'karthict@srmist.edu.in', 'phone': '9444417220'},
  };

  @override
  void initState() {
    super.initState();
    _loadTimetableFromPrefs();
  }

  Future<void> _loadTimetableFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('userData')) {
        final raw = prefs.getString('userData');
        if (raw != null && raw.isNotEmpty) {
          final Map<String, dynamic> data = json.decode(raw);
          final timetableRoot = data['timetable'];
          if (timetableRoot != null) {
            final coursesList = timetableRoot['courses'];
            final advisors = timetableRoot['advisors'];
            if (advisors != null && advisors is Map) {
              setState(() {
                _advisors = Map<String, dynamic>.from(advisors.map((k, v) => MapEntry(k.toString(), v)));
              });
            }
            if (coursesList is List) {
              final parsed = coursesList.map<Map<String, dynamic>>((e) {
                return {
                  'code': e['course_code'] ?? '',
                  'title': e['course_title'] ?? '',
                  'credits': e['credit'] is num ? (e['credit'] as num).toInt() : 0,
                  'faculty': (e['faculty_name'] ?? '').toString().split('(').first.trim(),
                  'slot': e['slot'] ?? '',
                  'room': e['room_no'] ?? e['room'] ?? '',
                  'category': e['category'] ?? '',
                };
              }).toList();
              if (parsed.isNotEmpty) {
                setState(() => _courses = parsed);
              }
            }
          }
        }
      }
    } catch (e) {
      // fall back
    } finally {
      if (_courses.isEmpty) _courses = _defaultTimetableData();
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAdvisorCard(),
                const SizedBox(height: 20),
                Text(
                  'Registered Courses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ..._courses.map((course) => _buildCourseCard(course)),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildAdvisorCard() {
    final fa = _advisors['faculty_advisor'] ?? {};
    final aa = _advisors['academic_advisor'] ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
          _buildAdvisorInfo(
            'Faculty Advisor',
            fa['name'] ?? 'Dr.S.Praveenkumar',
            fa['email'] ?? 'praveens11@srmist.edu.in',
            fa['phone'] ?? '9444022268',
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _buildAdvisorInfo(
            'Academic Advisor',
            aa['name'] ?? 'Dr.T.Karthick',
            aa['email'] ?? 'karthict@srmist.edu.in',
            aa['phone'] ?? '9444417220',
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorInfo(String role, String name, String email, String phone) {
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

  Widget _buildCourseCard(Map<String, dynamic> course) {
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
                        course['code'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${course['credits']} Credits',
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
            _buildCourseDetailRow(Icons.person, course['faculty']),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCourseDetailRow(Icons.schedule, course['slot']),
                ),
                if ((course['room'] ?? '').toString().isNotEmpty)
                  Expanded(
                    child: _buildCourseDetailRow(Icons.room, course['room']),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCourseDetailRow(Icons.category, course['category']),
          ],
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

  List<Map<String, dynamic>> _defaultTimetableData() {
    return [
      {
        'code': '21CSE216P',
        'title': 'Linux and Container Technologies',
        'credits': 3,
        'faculty': 'Dr.M.Vimala Devi',
        'slot': 'Slot B',
        'room': 'TP 202',
        'category': 'Professional Elective',
      },
      {
        'code': '21MAB302T',
        'title': 'Discrete Mathematics',
        'credits': 4,
        'faculty': 'Dr. Abhishek Banerjee',
        'slot': 'Slot C',
        'room': 'TP 1304',
        'category': 'Basic Science',
      },
      {
        'code': '21CSC301T',
        'title': 'Formal Language and Automata',
        'credits': 3,
        'faculty': 'Ms.K.Sornalakshmi',
        'slot': 'Slot D',
        'room': 'TP 1304',
        'category': 'Professional Core',
      },
      {
        'code': '21CSC307P',
        'title': 'Machine Learning for Data Analytics',
        'credits': 3,
        'faculty': 'Dr D Hemavathi',
        'slot': 'Slot F',
        'room': 'TP 1304',
        'category': 'Professional Core',
      },
      {
        'code': '21MEO112T',
        'title': 'Renewable Energy Sources and Application',
        'credits': 3,
        'faculty': 'Dr.D.Premnath',
        'slot': 'Slot G',
        'room': 'B501',
        'category': 'Open Elective',
      },
      {
        'code': '21GNP301L',
        'title': 'Community Connect',
        'credits': 1,
        'faculty': 'Dr.S.Praveenkumar',
        'slot': 'L41-L42',
        'room': '',
        'category': 'Professional Core',
      },
      {
        'code': '21LEM301T',
        'title': 'Indian Art Form',
        'credits': 0,
        'faculty': 'Dr.S.Praveenkumar',
        'slot': 'L51-L52',
        'room': '',
        'category': 'Mandatory',
      },
      {
        'code': '21CSC302J',
        'title': 'Computer Networks',
        'credits': 4,
        'faculty': 'Dr. Arthy M',
        'slot': 'P29-P30',
        'room': 'TP2CLS414',
        'category': 'Professional Core',
      },
    ];
  }
}