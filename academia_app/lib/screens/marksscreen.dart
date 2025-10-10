import 'dart:convert';
import 'dart:ui'; // Needed for Path and Canvas operations

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/marks_stats_widget.dart';

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
  // Neon Green Accent (UP/GOOD) - Will be used as a primary accent color
  static const Color _neonGreen = Color(0xFF39FF14);
  // White Foreground/Text
  static const Color _white = Colors.white;
  // Fallback/Warning colors using neon theme
  static const Color _neonYellow = Color(0xFFFFCC33);
  // Neon Red (DOWN/BAD)
  static const Color _neonRed = Color(0xFFFF4081);

  //used by stats widget to extract course credit
  Map<String, int> _courseCredits = {};

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


          // Extract course credits
          if (data['timetable'] != null && data['timetable']['courses'] != null) {
            final timetableCourses = data['timetable']['courses'];
            if (timetableCourses is List) {
              for (final course in timetableCourses) {
                if (course is Map) {
                  final title = course['course_title'];
                  final credit = course['credit'];
                  if (title != null && credit != null) {
                    _courseCredits[title.toString()] = (credit is int) ? credit : int.tryParse(credit.toString()) ?? 3;
                  }
                }
              }
            }
          }

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
            
            // Build a mapping from course codes to titles from attendance/timetable
            final Map<String, String> courseTitleMap = {};
            if (data['attendance'] != null && data['attendance']['attendance'] != null) {
              final courses = data['attendance']['attendance']['courses'];
              if (courses is Map) {
                courses.forEach((key, courseData) {
                  if (courseData is Map && courseData['course_title'] != null) {
                    // Extract base code (remove category suffix like 'RegularTheory')
                    final baseCode = key.toString().replaceAll(RegExp(r'Regular(Theory|Practical)$'), '');
                    courseTitleMap[baseCode] = courseData['course_title'];
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
                        'obtained': (t['obtained_marks'] is num) ? (t['obtained_marks'] as num).toDouble() : (t['obtained_marks'] ?? 0),
                        'max': t['max_marks'] ?? 0,
                        'percentage': (t['percentage'] is num) ? (t['percentage'] as num).toDouble() : 0.0,
                      });
                    }
                  }
                }
                
                // Extract base code from marks key (e.g., "21CSC302JTheory" -> "21CSC302J")
                final baseCode = code.toString().replaceAll(RegExp(r'(Theory|Practical)$'), '');
                final courseTitle = courseTitleMap[baseCode] ?? code;
                
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
        }
      }
    } catch (e) {
      // ignore and fall back
    } finally {
      // Do not populate with defaults; show 'No data found' when empty
      setState(() => _loading = false);
    }
    
  }

  // =======================================================================
  // Helper: Calculate course totals (Used for overall percentage display)
  // =======================================================================
  Map<String, dynamic> _calculateCourseTotals(List<Map<String, dynamic>> tests) {
    double totalObtained = 0.0;
    double totalMax = 0.0;
    
    for (final test in tests) {
      totalObtained += (test['obtained'] as num).toDouble();
      totalMax += (test['max'] as num).toDouble();
    }
    
    final overallPercentage = (totalMax > 0) ? (totalObtained / totalMax) * 100 : 0.0;
    
    return {
      'obtained': totalObtained,
      'max': totalMax,
      'percentage': overallPercentage,
    };
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
          if (_marks.isNotEmpty) ...[
            MarksStatsWidget(
              marks: _marks,
              courseCredits: _courseCredits,
            ),
            ..._marks.map((course) => _buildCourseMarksCard(course))
          ] else
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

  Widget _buildCourseMarksCard(Map<String, dynamic> course) {
    final tests = course['tests'] as List<Map<String, dynamic>>;
    final totals = _calculateCourseTotals(tests);

    final double totalObtained = totals['obtained'];
    final double totalMax = totals['max'];
    final double overallPercentage = totals['percentage'];
    
    // Extract percentages for the sparkline
    final List<double> percentages = tests.map((t) => (t['percentage'] as num).toDouble()).toList();

    // Determine the color for the sparkline trend
    // Using a slightly more saturated green and red for the line itself
    Color sparklineColor = const Color.fromARGB(255, 46, 123, 32); // _neonGreen
    if (percentages.length >= 2) {
      // Check if the last score is lower than the second to last score
      if (percentages.last < percentages[percentages.length - 2]) {
        sparklineColor = const Color.fromARGB(255, 229, 60, 116); // _neonRed
      }
    }
    
    // Determine last point color for the graph
    Color lastPointColor = _neonGreen;
    if (percentages.length >= 2) {
      if (percentages.last < percentages[percentages.length - 2]) {
        lastPointColor = _neonRed;
      } else if (percentages.last == percentages[percentages.length - 2]) {
        lastPointColor = _neonYellow;
      }
    }


    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _pitchBlack, // ⬅️ Pitch Black Card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neonGreen.withOpacity(0.5), width: 1), // Neon Green Border
        // GLOW EFFECT REMOVED: boxShadow is removed
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Title, Type, and Total Score
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
                          fontWeight: FontWeight.bold,
                          color: _white, // ⬅️ White text
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['type'],
                        style: TextStyle(fontSize: 13, color: _neonGreen.withOpacity(0.8)), // ⬅️ Neon Green for type
                      ),
                    ],
                  ),
                ),
                // Total Score Box
                if (tests.isNotEmpty) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getScoreColor(overallPercentage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16), // ⬅️ UPDATED: Border Radius 16
                      border: Border.all(color: _getScoreColor(overallPercentage).withOpacity(0.7), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${totalObtained.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(overallPercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Sparkline Graph (New Addition)
            if (percentages.length > 1) 
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: SizedBox(
                  height: 60, // ⬅️ UPDATED: Increased height for better clarity
                  child: _MarksTrendSparkline(
                    percentages: percentages, 
                    lineColor: sparklineColor,
                    lastPointColor: lastPointColor, // Pass the last point color
                  ),
                ),
              )
            else if (percentages.length == 1)
               Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Only one test score recorded.',
                  style: TextStyle(fontSize: 12, color: _white.withOpacity(0.5)),
                ),
              ),

            
            if (tests.isNotEmpty) ...[
              const SizedBox(height: 16),
              // Separator for the list of tests
              Divider(color: _white.withOpacity(0.1), height: 1), 
              const SizedBox(height: 8),
              ...tests.map<Widget>((test) {
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
                              '${(test['obtained'] as num).toStringAsFixed(1)} / ${(test['max'] as num).toStringAsFixed(1)}',
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
                          '${(test['percentage'] as double).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getScoreColor(test['percentage']), // Text color matches border
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            // GLOW EFFECT REMOVED: shadows list is removed
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

// =======================================================================
// NEW: Marks Trend Sparkline Widget and Painter
// =======================================================================

class _MarksTrendSparkline extends StatelessWidget {
  final List<double> percentages;
  final Color lineColor;
  final Color lastPointColor; // NEW: Color for the last point indicator

  const _MarksTrendSparkline({
    required this.percentages,
    required this.lineColor,
    required this.lastPointColor, // Required
  });

  @override
  Widget build(BuildContext context) {
    // Only paint if there are at least two points for a line
    if (percentages.length < 2) {
      return const SizedBox.shrink();
    }
    
    return CustomPaint(
      painter: _MarksTrendPainter(
        percentages: percentages,
        lineColor: lineColor,
        lastPointColor: lastPointColor, // Pass to painter
      ),
      child: Container(),
    );
  }
}

class _MarksTrendPainter extends CustomPainter {
  final List<double> percentages;
  final Color lineColor;
  final Color lastPointColor; // NEW: Color for the last point indicator

  _MarksTrendPainter({
    required this.percentages,
    required this.lineColor,
    required this.lastPointColor,
  }) : assert(percentages.length >= 2);

  @override
  void paint(Canvas canvas, Size size) {
    // Use 0-100% as the range for better stability unless all scores are very high/low
    final double range = 100.0;
    // We reverse the y-axis calculation since 0% is the bottom and 100% is the top
    final double yMax = size.height;
    final double yMin = 0;


    // --- 1. Calculate points ---
    final List<Offset> points = [];
    final double xStep = size.width / (percentages.length - 1);

    // Padding to prevent points from touching the top and bottom edge
    const double verticalPaddingFactor = 0.1; // 10% padding
    final verticalPadding = size.height * verticalPaddingFactor;
    final drawingHeight = size.height - 2 * verticalPadding;

    for (int i = 0; i < percentages.length; i++) {
      final percentage = percentages[i].clamp(0.0, 100.0); // Clamp to prevent overflow
      final x = i * xStep;
      
      // Normalize percentage (0 to 1) relative to 0-100 range
      final normalizedY = percentage / range; 
      
      // Map normalized Y to screen coordinates, flipping the axis (100% is y=0, 0% is y=height)
      final y = yMax - verticalPadding - (normalizedY * drawingHeight);
      
      points.add(Offset(x, y.clamp(yMin, yMax)));
    }
    
    // --- 2. Draw Faded Fill (Area Graph) ---
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height); // Start at bottom left
    fillPath.lineTo(points.first.dx, points.first.dy); // Move to first point
    
    for (int i = 1; i < points.length; i++) {
      // Use cubic Bezier curve for a smoother transition
      final p1 = points[i - 1];
      final p2 = points[i];
      
      fillPath.cubicTo(
        (p1.dx + p2.dx) / 2, p1.dy,
        (p1.dx + p2.dx) / 2, p2.dy,
        p2.dx, p2.dy,
      );
    }
    
    fillPath.lineTo(points.last.dx, size.height); // End at bottom right
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.15), // REDUCED OPACITY
          lineColor.withOpacity(0.01), // Almost transparent bottom
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);


    // --- 3. Draw Line Shadow (New Addition) ---
    // Offset the line slightly down to create the drop shadow effect
    const double shadowOffset = 2.0;
    final lineShadowPath = Path();
    lineShadowPath.moveTo(points.first.dx, points.first.dy + shadowOffset);
    
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      
      // Use cubic Bezier curve with offset
      lineShadowPath.cubicTo(
        (p1.dx + p2.dx) / 2, p1.dy + shadowOffset,
        (p1.dx + p2.dx) / 2, p2.dy + shadowOffset,
        p2.dx, p2.dy + shadowOffset,
      );
    }
    
    // Line Shadow Paint
    final lineShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4) // Soft dark shadow color
      ..strokeWidth = 4.0 // Slightly thicker than the main line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      // Apply blur/mask filter for the shadow effect
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0); 

    canvas.drawPath(lineShadowPath, lineShadowPaint);
    
    
    // --- 4. Draw Continuous Line (Thicker line) ---
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];
      
      // Use cubic Bezier curve for a smooth, neat line
      linePath.cubicTo(
        (p1.dx + p2.dx) / 2, p1.dy,
        (p1.dx + p2.dx) / 2, p2.dy,
        p2.dx, p2.dy,
      );
    }

    // Line Paint with NO GLOW
    final linePaint = Paint()
      ..color = lineColor // Trend color
      ..strokeWidth = 3.0 // Thicker line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      // GLOW EFFECT REMOVED: maskFilter is removed

    canvas.drawPath(linePath, linePaint);

    // --- 5. Draw Points (Last point indicator) - NO GLOW ---
    // Paint for the points (dots)
    final pointPaint = Paint()
      ..style = PaintingStyle.fill;
      // GLOW EFFECT REMOVED: maskFilter is removed

    // Draw all points except the last one (lighter color)
    for (int i = 0; i < points.length - 1; i++) {
      pointPaint.color = lineColor.withOpacity(0.7);
      canvas.drawCircle(points[i], 3.0, pointPaint);
    }

    // Draw the LAST point (with dynamic color and more prominence)
    if (points.isNotEmpty) {
      pointPaint.color = lastPointColor; // Use the dynamic color
      canvas.drawCircle(points.last, 4.0, pointPaint); // Larger dot for last point
      
      // Draw a white border/center for contrast
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.last, 1.5, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarksTrendPainter oldDelegate) {
    // Repaint if the data or colors change
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