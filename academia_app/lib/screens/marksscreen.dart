import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// MARKS SCREEN - Test scores and performance
// ============================================================================
class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _marks = [];

  @override
  void initState() {
    super.initState();
    _loadMarksFromPrefs();
  }

  Future<void> _loadMarksFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('userData')) {
        final raw = prefs.getString('userData');
        if (raw != null && raw.isNotEmpty) {
          final Map<String, dynamic> data = json.decode(raw);
          final marksRoot = data['marks'];
          if (marksRoot != null && marksRoot is Map) {
            final parsed = <Map<String, dynamic>>[];
            marksRoot.forEach((code, value) {
              if (value is Map) {
                final tests = <Map<String, dynamic>>[];
                final testsRaw = value['tests'];
                if (testsRaw is List) {
                  for (final t in testsRaw) {
                    if (t is Map) {
                      tests.add({
                        'name': t['test_name'] ?? '',
                        'obtained': (t['obtained_marks'] is num) ? (t['obtained_marks'] as num).toDouble() : (t['obtained_marks'] ?? 0),
                        'max': t['max_marks'] ?? 0,
                        'percentage': (t['percentage'] is num) ? (t['percentage'] as num).toDouble() : 0.0,
                      });
                    }
                  }
                }
                parsed.add({
                  'title': value['course_type'] == null ? code : (value['course_title'] ?? code),
                  'type': value['course_type'] ?? 'Theory',
                  'tests': tests,
                });
              }
            });
            if (parsed.isNotEmpty) {
              setState(() => _marks = parsed);
            }
          }
        }
      }
    } catch (e) {
      // ignore and fall back
    } finally {
      if (_marks.isEmpty) _marks = _getMarksData();
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Marks', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Marks', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._marks.map((course) => _buildCourseMarksCard(course)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCourseMarksCard(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            Text(
              course['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              course['type'],
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (course['tests'].isNotEmpty) ...[
              const SizedBox(height: 16),
              ...course['tests'].map<Widget>((test) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${test['obtained']} / ${test['max']}',
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
                          color: _getScoreColor(test['percentage'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${test['percentage'].toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getScoreColor(test['percentage']),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'No tests recorded',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  List<Map<String, dynamic>> _getMarksData() {
    return [
      {
        'title': 'Discrete Mathematics',
        'type': 'Theory',
        'tests': [
          {'name': 'FT-II', 'obtained': 11.1, 'max': 15, 'percentage': 74.0},
          {'name': 'FT-I', 'obtained': 5, 'max': 5, 'percentage': 100.0},
        ],
      },
      {
        'title': 'Formal Language and Automata',
        'type': 'Theory',
        'tests': [
          {'name': 'FT-II', 'obtained': 13.8, 'max': 15, 'percentage': 92.0},
          {'name': 'FT-I', 'obtained': 5, 'max': 5, 'percentage': 100.0},
        ],
      },
      {
        'title': 'Computer Networks',
        'type': 'Practical',
        'tests': [],
      },
      {
        'title': 'Machine Learning for Data Analytics',
        'type': 'Theory',
        'tests': [
          {'name': 'FP-I', 'obtained': 7.2, 'max': 10, 'percentage': 72.0},
          {'name': 'PBL-I', 'obtained': 18.8, 'max': 20, 'percentage': 94.0},
        ],
      },
      {
        'title': 'Linux and Container Technologies',
        'type': 'Theory',
        'tests': [
          {'name': 'FP-I', 'obtained': 7.1, 'max': 10, 'percentage': 71.0},
          {'name': 'PBL-I', 'obtained': 18, 'max': 20, 'percentage': 90.0},
        ],
      },
      {
        'title': 'Renewable Energy Sources',
        'type': 'Theory',
        'tests': [
          {'name': 'FT-II', 'obtained': 10.1, 'max': 15, 'percentage': 67.33},
          {'name': 'FT-I', 'obtained': 3.4, 'max': 5, 'percentage': 68.0},
        ],
      },
      {
        'title': 'Indian Art Form',
        'type': 'Practical',
        'tests': [
          {'name': 'FML-I', 'obtained': 25, 'max': 30, 'percentage': 83.33},
        ],
      },
    ];
  }
}
