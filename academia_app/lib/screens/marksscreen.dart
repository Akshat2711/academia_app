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
  // --- COLOR PALETTE ---
  // Pitch Black Background
  static const Color _pitchBlack = Color(0xFF000000);
  // Neon Green Accent
  static const Color _neonGreen = Color(0xFF39FF14);
  // White Foreground/Text
  static const Color _white = Colors.white;
  // Fallback/Warning colors using neon theme
  static const Color _neonYellow = Color(0xFFFFCC33);
  static const Color _neonRed = Color(0xFFFF4081);


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
        backgroundColor: _pitchBlack, // ⬅️ Pitch Black
        appBar: AppBar(
          title: const Text('Marks', style: TextStyle(fontWeight: FontWeight.w600, color: _white)), // ⬅️ White text
          backgroundColor: _pitchBlack, // ⬅️ Pitch Black
          foregroundColor: _neonGreen, // ⬅️ Neon Green icons/buttons
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: _neonGreen)), // ⬅️ Neon Green loading indicator
      );
    }

    return Scaffold(
      backgroundColor: _pitchBlack, // ⬅️ Pitch Black
      appBar: AppBar(
        title: const Text('Marks', style: TextStyle(fontWeight: FontWeight.w600, color: _white)), // ⬅️ White text
        backgroundColor: _pitchBlack, // ⬅️ Pitch Black
        foregroundColor: _neonGreen, // ⬅️ Neon Green icons/buttons
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
              child: Text(
                'No data found',
                style: TextStyle(color: _white.withOpacity(0.6)), // ⬅️ White text
              ),
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
        color: _pitchBlack, // ⬅️ Pitch Black Card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neonGreen.withOpacity(0.5), width: 1), // Neon Green Border
        boxShadow: [
          BoxShadow(
            color: _neonGreen.withOpacity(0.15), // Neon Green glow
            blurRadius: 10,
            offset: const Offset(0, 0),
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
                color: _white, // ⬅️ White text
              ),
            ),
            const SizedBox(height: 4),
            Text(
              course['type'],
              style: TextStyle(fontSize: 13, color: _neonGreen.withOpacity(0.8)), // ⬅️ Neon Green for type
            ),
            if (course['tests'].isNotEmpty) ...[
              const SizedBox(height: 16),
              // Separator for the list of tests
              Divider(color: _white.withOpacity(0.1), height: 1), 
              const SizedBox(height: 8),
              ...course['tests'].map<Widget>((test) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
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
                                color: _white, // ⬅️ White text
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${test['obtained']} / ${test['max']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: _white.withOpacity(0.7), // ⬅️ White score detail
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
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getScoreColor(test['percentage']).withOpacity(0.7), width: 1), // Border to enhance neon look
                        ),
                        child: Text(
                          '${test['percentage'].toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getScoreColor(test['percentage']), // Text color matches glow
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: _getScoreColor(test['percentage']).withOpacity(0.5),
                                offset: const Offset(0, 0),
                              ),
                            ]
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
                style: TextStyle(fontSize: 14, color: _white.withOpacity(0.5)), // ⬅️ White text
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 85) return _neonGreen; // ⬅️ Neon Green for High Score
    if (percentage >= 70) return _neonYellow; // ⬅️ Neon Yellow for Medium Score
    return _neonRed; // ⬅️ Neon Red for Low Score
  }

}