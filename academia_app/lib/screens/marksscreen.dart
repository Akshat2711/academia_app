import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/marks_stats_widget.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  // --- UPDATED COLOR PALETTE (GREEN/WHITE/BLACK/GRAY ONLY) ---
  static const Color _pitchBlack = Color(0xFF000000);
  static const Color _darkGray = Color(0xFF0F0F0F);
  static const Color _cardBg = Color(0xFF1A1A1A);
  static const Color _neonGreen = Color.fromARGB(255, 70, 71, 73); // Primary Accent
  static const Color _white = Colors.white;
  static const Color _cautionGreen = Color(0xFF76FF03); // Lighter green for caution
  static const Color _declineGray = Color(0xFF505050); // Used in place of red/yellow for decline
  static const Color _textSecondary = Color(0xFFB0B0B0);

  Map<String, int> _courseCredits = {};
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
    final raw = prefs.getString('userData');
    if (raw == null || raw.isEmpty) return;

    final Map<String, dynamic> data = json.decode(raw);

    // --- Extract course credits and build course map from timetable ---
    final Map<String, dynamic> timetableCourseMap = {};
    _courseCredits.clear();
    if (data['timetable'] != null && data['timetable']['courses'] != null) {
      final timetableCourses = data['timetable']['courses'];
      if (timetableCourses is List) {
        for (final course in timetableCourses) {
          if (course is Map) {
            final title = course['course_title'];
            final credit = course['credit'];
            final codeRaw = course['course_code'] ?? '';

            // normalize keys for lookups: keep original code and base code (without Theory/Practical)
            final baseCode = codeRaw
                .toString()
                .replaceAll(RegExp(r'(Regular)?(Theory|Practical)$'), '');

            if (title != null) {
              timetableCourseMap[codeRaw.toString()] = course;
              timetableCourseMap[baseCode] = course;
            }

            if (title != null && credit != null) {
              _courseCredits[title.toString()] = (credit is int)
                  ? credit
                  : int.tryParse(credit.toString()) ?? 3;
            }
          }
        }
      }
    }

    // --- Find marks root (prefer top-level 'marks', else check attendance.marks like before) ---
    var marksRoot = data['marks'];
    if (marksRoot == null &&
        data['attendance'] != null &&
        data['attendance'] is Map) {
      final attendanceRoot = data['attendance'] as Map;
      if (attendanceRoot['marks'] != null) {
        var candidate = attendanceRoot['marks'];
        if (candidate is String && candidate.isNotEmpty) {
          try {
            candidate = json.decode(candidate);
          } catch (e) {
            // ignore: avoid_print
            print('Failed to decode attendance.marks string: $e');
          }
        }
        marksRoot = candidate;
      }
    }

    if (marksRoot != null && marksRoot is Map) {
      final parsed = <Map<String, dynamic>>[];

      // build fallback courseTitleMap from attendance (only if timetable mapping missing)
      final Map<String, String> attendanceTitleMap = {};
      if (data['attendance'] != null &&
          data['attendance']['attendance'] != null) {
        final courses = data['attendance']['attendance']['courses'];
        if (courses is Map) {
          courses.forEach((key, courseData) {
            if (courseData is Map && courseData['course_title'] != null) {
              final baseCode = key
                  .toString()
                  .replaceAll(RegExp(r'Regular(Theory|Practical)$'), '');
              attendanceTitleMap[baseCode] = courseData['course_title'];
            }
          });
        }
      }

      marksRoot.forEach((code, value) {
        if (value is Map) {
          final tests = <Map<String, dynamic>>[];
          final testsRaw = value['tests'];
          if (testsRaw is List) {
            for (final t in testsRaw) {
              if (t is Map) {
                tests.add({
                  'name': t['test_name'] ?? '',
                  'obtained': (t['obtained_marks'] is num)
                      ? (t['obtained_marks'] as num).toDouble()
                      : (t['obtained_marks'] != null
                          ? double.tryParse(t['obtained_marks'].toString()) ??
                              0.0
                          : 0.0),
                  'max': (t['max_marks'] is num)
                      ? (t['max_marks'] as num).toDouble()
                      : (t['max_marks'] != null
                          ? double.tryParse(t['max_marks'].toString()) ?? 0.0
                          : 0.0),
                  'percentage': (t['percentage'] is num)
                      ? (t['percentage'] as num).toDouble()
                      : (t['percentage'] != null
                          ? double.tryParse(t['percentage'].toString()) ?? 0.0
                          : 0.0),
                });
              }
            }
          }

          // normalize course code (remove Theory/Practical suffixes)
          final baseCode =
              code.toString().replaceAll(RegExp(r'(Theory|Practical)$'), '');

          // Try to get course title from timetable first, else attendance fallback, else use code
          String courseTitle = code;
          final courseFromTimetable = timetableCourseMap[code] ??
              timetableCourseMap[baseCode]; // check both keys
          if (courseFromTimetable is Map && courseFromTimetable['course_title'] != null) {
            courseTitle = courseFromTimetable['course_title'].toString();
          } else if (attendanceTitleMap.containsKey(baseCode)) {
            courseTitle = attendanceTitleMap[baseCode]!;
          }

          parsed.add({
            'title': courseTitle,
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
  } catch (e) {
    // ignore or log
    // ignore: avoid_print
    print('Error loading marks: $e');
  } finally {
    setState(() => _loading = false);
  }
}


  Map<String, dynamic> _calculateCourseTotals(
      List<Map<String, dynamic>> tests) {
    double totalObtained = 0.0;
    double totalMax = 0.0;

    for (final test in tests) {
      totalObtained += (test['obtained'] as num).toDouble();
      totalMax += (test['max'] as num).toDouble();
    }

    final overallPercentage =
        (totalMax > 0) ? (totalObtained / totalMax) * 100 : 0.0;

    return {
      'obtained': totalObtained,
      'max': totalMax,
      'percentage': overallPercentage,
    };
  }

  // Logic to use only shades of green and gray (NOT CHANGED)
  Color _getScoreColor(double percentage) {
    if (percentage >= 85) return const Color.fromARGB(255, 147, 229, 132);
    if (percentage >= 70) return const Color.fromARGB(255, 209, 242, 183);
    return const Color.fromARGB(255, 233, 205, 205); // Use dark gray for low scores
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _pitchBlack,
        appBar: AppBar(
          title: const Text('Marks',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _white,
                  fontSize: 20)),
          backgroundColor: _pitchBlack,
          foregroundColor: _neonGreen,
          elevation: 0,
        ),
        body: const Center(
            child: CircularProgressIndicator(color: _neonGreen)),
      );
    }

    return Scaffold(
      backgroundColor: _pitchBlack,
      appBar: AppBar(
        title: const Text('Marks',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: _white, fontSize: 20)),
        backgroundColor: _pitchBlack,
        foregroundColor: _neonGreen,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
            MarksStatsWidget(
              marks: _marks,
              courseCredits: _courseCredits,
            ),
          if (_marks.isNotEmpty) ...[
            // Assuming MarksStatsWidget uses the global color constants, 
            // no change is needed here, but its implementation should also 
            // adhere to the new palette.

            const SizedBox(height: 20),
            ..._marks.map((course) => _buildCourseMarksCard(course))
          ] else
                 Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off_rounded,
                          color: _white.withOpacity(0.35),
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No Marks data available',
                          style: TextStyle(
                            color: _white.withOpacity(0.4),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCourseMarksCard(Map<String, dynamic> course) {
    final tests = course['tests'] as List<Map<String, dynamic>>;
    final totals = _calculateCourseTotals(tests);

    final double totalObtained = totals['obtained'];
    final double totalMax = totals['max'];
    final double overallPercentage = totals['percentage'];

    List<double> percentages =
        tests.map((t) => (t['percentage'] as num).toDouble()).toList();
    percentages = percentages.reversed.toList();

    // Trend colors logic (NOT CHANGED)
    Color sparklineColor = const Color.fromARGB(255, 174, 214, 167); // Default: Improvement/Good
    Color lastPointColor = const Color.fromARGB(255, 241, 245, 240); // Default: Last score is good/improved

    if (percentages.length >= 2) {
      if (percentages.last < percentages[percentages.length - 2]) {
        // Decline: Use Dark Gray
        sparklineColor = _declineGray; 
        lastPointColor = _declineGray; 
      } else if (percentages.last == percentages[percentages.length - 2]) {
        // Steady: Use Caution Green
        lastPointColor = const Color.fromARGB(255, 220, 227, 215); 
        sparklineColor = const Color.fromARGB(255, 166, 206, 136);
      }
      // If percentages.last > percentages[percentages.length - 2], keep original colors
    }


    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Course Title and Score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2, // Retained wrapping logic
                        overflow: TextOverflow.ellipsis, // Retained overflow logic
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course['type'],
                        style: TextStyle(
                          fontSize: 12,
                          color: _neonGreen.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tests.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      // Uses the score color logic
                      color: _getScoreColor(overallPercentage)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          // **UPDATED**: total marks to display with one decimal place
                          '${totalObtained.toStringAsFixed(1)}/${totalMax.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            // Uses the score color logic
                            color: _getScoreColor(overallPercentage), 
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${overallPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            // Uses the score color logic
                            color: _getScoreColor(overallPercentage)
                                .withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Sparkline (NOT CHANGED)
            if (percentages.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: SizedBox(
                  height: 50,
                  child: _MarksTrendSparkline(
                    percentages: percentages,
                    // Uses the sparkline trend colors
                    lineColor: sparklineColor,
                    lastPointColor: lastPointColor,
                  ),
                ),
              )
            else if (percentages.length == 1)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  'Only one test score recorded',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary.withOpacity(0.7),
                  ),
                ),
              ),

            // Test Details
            if (tests.isNotEmpty) ...[
              Divider(color: _white.withOpacity(0.08), height: 14),
              const SizedBox(height: 8),
              ...tests.map<Widget>((test) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              // Individual test scores already use one decimal place
                              '${(test['obtained'] as num).toStringAsFixed(1)} / ${(test['max'] as num).toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          // Uses the score color logic
                          color: _getScoreColor(test['percentage'])
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(test['percentage'] as double).toStringAsFixed(0)}%',
                          style: TextStyle(
                            // Uses the score color logic
                            color: _getScoreColor(test['percentage']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'No tests recorded',
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// Marks Trend Sparkline (NO CHANGES)
// =======================================================================

class _MarksTrendSparkline extends StatelessWidget {
  final List<double> percentages;
  final Color lineColor;
  final Color lastPointColor;

  const _MarksTrendSparkline({
    required this.percentages,
    required this.lineColor,
    required this.lastPointColor,
  });

  @override
  Widget build(BuildContext context) {
    if (percentages.length < 2) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _MarksTrendPainter(
        percentages: percentages,
        lineColor: lineColor,
        lastPointColor: lastPointColor,
      ),
      child: Container(),
    );
  }
}

class _MarksTrendPainter extends CustomPainter {
  final List<double> percentages;
  final Color lineColor;
  final Color lastPointColor;

  _MarksTrendPainter({
    required this.percentages,
    required this.lineColor,
    required this.lastPointColor,
  }) : assert(percentages.length >= 2);

  @override
  void paint(Canvas canvas, Size size) {
    const double range = 100.0;
    const double verticalPaddingFactor = 0.12;
    final verticalPadding = size.height * verticalPaddingFactor;
    final drawingHeight = size.height - 2 * verticalPadding;

    // Calculate points
    final List<Offset> points = [];
    final double xStep = size.width / (percentages.length - 1);

    for (int i = 0; i < percentages.length; i++) {
      final percentage = percentages[i].clamp(0.0, 100.0);
      final x = i * xStep;
      final normalizedY = percentage / range;
      final y = size.height - verticalPadding - (normalizedY * drawingHeight);

      points.add(Offset(x, y.clamp(0, size.height)));
    }

    // Draw fill
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];

      fillPath.cubicTo(
        (p1.dx + p2.dx) / 2,
        p1.dy,
        (p1.dx + p2.dx) / 2,
        p2.dy,
        p2.dx,
        p2.dy,
      );
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.12),
          lineColor.withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];

      linePath.cubicTo(
        (p1.dx + p2.dx) / 2,
        p1.dy,
        (p1.dx + p2.dx) / 2,
        p2.dy,
        p2.dx,
        p2.dy,
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points
    final pointPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < points.length - 1; i++) {
      // Use the line color for internal points
      pointPaint.color = lineColor.withOpacity(0.6); 
      canvas.drawCircle(points[i], 2.5, pointPaint);
    }

    // Last point
    if (points.isNotEmpty) {
      pointPaint.color = lastPointColor;
      canvas.drawCircle(points.last, 3.5, pointPaint);

      final centerPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.last, 1.2, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarksTrendPainter oldDelegate) {
    if (percentages.length != oldDelegate.percentages.length ||
        lineColor != oldDelegate.lineColor ||
        lastPointColor != oldDelegate.lastPointColor) {
      return true;
    }
    for (int i = 0; i < percentages.length; i++) {
      if (percentages[i] != oldDelegate.percentages[i]) {
        return true;
      }
    }
    return false;
  }
}