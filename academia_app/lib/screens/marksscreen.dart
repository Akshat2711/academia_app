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
  // No presence flag needed; show 'No data found' when _marks is empty

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
          // marks may be at top-level or nested under `attendance`
          var marksRoot = data['marks'];

          // Debug: print whether marks exist at top-level
          // ignore: avoid_print
          print('Marks at top-level present: ${data.containsKey('marks')}');

          // If not present at top-level, look under attendance
          if (marksRoot == null && data['attendance'] != null && data['attendance'] is Map) {
            final attendanceRoot = data['attendance'] as Map;
            // if marks is a Map
            if (attendanceRoot['marks'] != null) {
              var candidate = attendanceRoot['marks'];
              // If marks were stored as a JSON-encoded String, try to decode
              if (candidate is String && candidate.isNotEmpty) {
                try {
                  candidate = json.decode(candidate);
                  // ignore: avoid_print
                  print('Decoded string-encoded attendance.marks');
                } catch (e) {
                  // ignore: avoid_print
                  print('Failed to decode attendance.marks string: $e');
                }
              }
              marksRoot = candidate;
            }
          }

          // Debug: print what we found
          // ignore: avoid_print
          print('marksRoot runtimeType: ${marksRoot.runtimeType}');

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
              setState(() {
                _marks = parsed;
              });
            }
          }
        }
      }
    } catch (e) {
      // ignore and fall back
    } finally {
      // Do not populate with defaults; show 'No data found' when empty
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
          if (_marks.isNotEmpty)
            ..._marks.map((course) => _buildCourseMarksCard(course))
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

}
