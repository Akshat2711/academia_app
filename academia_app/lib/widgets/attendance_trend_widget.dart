import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ============================================================================
// ATTENDANCE TREND WIDGET - Shows last 5 days attendance with modern line graph
// ============================================================================

class AttendanceTrendData {
  final String courseId;
  final String date;
  final double percentage;
  final int conducted;
  final int absent;

  AttendanceTrendData({
    required this.courseId,
    required this.date,
    required this.percentage,
    required this.conducted,
    required this.absent,
  });

  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'date': date,
    'percentage': percentage,
    'conducted': conducted,
    'absent': absent,
  };

  factory AttendanceTrendData.fromJson(Map<String, dynamic> json) =>
      AttendanceTrendData(
        courseId: json['courseId'],
        date: json['date'],
        percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : 0.0,
        conducted: (json['conducted'] is num) ? (json['conducted'] as num).toInt() : 0,
        absent: (json['absent'] is num) ? (json['absent'] as num).toInt() : 0,
      );
}

class AttendanceTrendWidget extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final double currentPercentage;
  final int currentConducted;
  final int currentAbsent;

  const AttendanceTrendWidget({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.currentPercentage,
    required this.currentConducted,
    required this.currentAbsent,
  });

  @override
  State<AttendanceTrendWidget> createState() => _AttendanceTrendWidgetState();

  /// Static method to save attendance data for all courses (call from app initialization)
  static Future<void> saveAttendanceDataForAllCourses(
    List<Map<String, dynamic>> courses,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const mainKey = 'GRAPH_ATTENDANCE';

      // Load existing graph data
      Map<String, dynamic> allGraphData = {};
      if (prefs.containsKey(mainKey)) {
        final raw = prefs.getString(mainKey);
        if (raw != null && raw.isNotEmpty) {
          allGraphData = json.decode(raw) as Map<String, dynamic>;
        }
      }

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Process each course
      for (var course in courses) {
        final courseId = course['id'] ?? course['title'] ?? 'unknown';
        final percentage = (course['percentage'] is num)
            ? (course['percentage'] as num).toDouble()
            : 0.0;
        final conducted = (course['conducted'] is num)
            ? (course['conducted'] as num).toInt()
            : 0;
        final absent = (course['absent'] is num)
            ? (course['absent'] as num).toInt()
            : 0;

        // Initialize course data if not exists
        if (!allGraphData.containsKey(courseId)) {
          allGraphData[courseId] = [];
        }

        List<dynamic> courseData = allGraphData[courseId];
        List<AttendanceTrendData> trends = courseData
            .map((item) => AttendanceTrendData.fromJson(item as Map<String, dynamic>))
            .toList();

        // Clean old data
        final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
        trends.removeWhere((trend) {
          final trendDate = DateTime.parse(trend.date);
          return trendDate.isBefore(fiveDaysAgo);
        });

        // Check if today's data exists
        final todayExists = trends.any((t) => t.date == todayStr);

        if (!todayExists) {
          // Add today's data
          trends.add(AttendanceTrendData(
            courseId: courseId,
            date: todayStr,
            percentage: percentage,
            conducted: conducted,
            absent: absent,
          ));
        } else {
          // Update today's data if changed
          final todayIndex = trends.indexWhere((t) => t.date == todayStr);
          if (todayIndex != -1) {
            trends[todayIndex] = AttendanceTrendData(
              courseId: courseId,
              date: todayStr,
              percentage: percentage,
              conducted: conducted,
              absent: absent,
            );
          }
        }

        // Sort by date
        trends.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

        // Update main data
        allGraphData[courseId] = trends.map((e) => e.toJson()).toList();
      }

      // Save all data
      await prefs.setString(mainKey, json.encode(allGraphData));
    } catch (e) {
      // Silently fail
    }
  }
}

class _AttendanceTrendWidgetState extends State<AttendanceTrendWidget> {
  // --- BLUE SHADES ONLY COLOR PALETTE ---
  static const Color _navyBlue = Color(0xFF2C5F9E);
  static const Color _lightNavy = Color(0xFF4A7DC4);
  static const Color _skyBlue = Color(0xFF64B5F6);
  static const Color _deepBlue = Color(0xFF1565C0);
  static const Color _white = Color(0xFFFFFFFF);

  List<AttendanceTrendData> _trendData = [];
  bool _hasDeclined = false;

  @override
  void initState() {
    super.initState();
    _loadOrCreateTrendData();
  }

  Future<void> _loadOrCreateTrendData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const mainKey = 'GRAPH_ATTENDANCE';
      
      // Load all graph data
      Map<String, dynamic> allGraphData = {};
      if (prefs.containsKey(mainKey)) {
        final raw = prefs.getString(mainKey);
        if (raw != null && raw.isNotEmpty) {
          allGraphData = json.decode(raw) as Map<String, dynamic>;
        }
      }

      // Get or initialize this course's data
      List<AttendanceTrendData> trends = [];
      if (allGraphData.containsKey(widget.courseId)) {
        final courseData = allGraphData[widget.courseId];
        if (courseData is List) {
          trends = courseData
              .map((item) => AttendanceTrendData.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      // Clean up old data (keep only last 5 days)
      final today = DateTime.now();
      final fiveDaysAgo = today.subtract(const Duration(days: 5));
      trends.removeWhere((trend) {
        final trendDate = DateTime.parse(trend.date);
        return trendDate.isBefore(fiveDaysAgo);
      });

      // Check if today's data exists
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      final todayExists = trends.any((t) => t.date == todayStr);

      if (!todayExists) {
        // Add today's data
        trends.add(AttendanceTrendData(
          courseId: widget.courseId,
          date: todayStr,
          percentage: widget.currentPercentage,
          conducted: widget.currentConducted,
          absent: widget.currentAbsent,
        ));
      } else {
        // Update today's data if attendance changed
        final todayIndex = trends.indexWhere((t) => t.date == todayStr);
        if (todayIndex != -1) {
          trends[todayIndex] = AttendanceTrendData(
            courseId: widget.courseId,
            date: todayStr,
            percentage: widget.currentPercentage,
            conducted: widget.currentConducted,
            absent: widget.currentAbsent,
          );
        }
      }

      // Sort by date
      trends.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

      // Detect if attendance declined (only relevant if there are 2 or more points)
      _hasDeclined = false;
      if (trends.length >= 2) {
        final currentPercentage = trends.last.percentage;
        final previousPercentage = trends[trends.length - 2].percentage;
        if (currentPercentage < previousPercentage) {
            _hasDeclined = true;
        }
      }

      // Update this course in the main graph data
      allGraphData[widget.courseId] = trends.map((e) => e.toJson()).toList();

      // Save back to prefs with clean structure
      await prefs.setString(mainKey, json.encode(allGraphData));

      setState(() {
        _trendData = trends;
      });
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the data to display (last 5 days)
    final displayData = _trendData.length > 5 
        ? _trendData.sublist(_trendData.length - 5)
        : _trendData;

    Widget content;
    
    // Condition 1: No data
    if (displayData.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No trend data yet',
            style: TextStyle(color: _white.withOpacity(0.4), fontSize: 12),
          ),
        ),
      );
    // Condition 2: Only one day of data
    } else if (displayData.length == 1) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Only one day data present: ${displayData.first.percentage.toStringAsFixed(1)}%',
            style: TextStyle(color: _white.withOpacity(0.6), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    // Condition 3: Two or more days of data (a trend)
    } else {
      content = _buildModernLineGraph(displayData);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and alert
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Last 5-Day Trend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _white.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Only show decline if there's a trend to compare
            if (_hasDeclined && displayData.length > 1) 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _deepBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _deepBlue.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_down, size: 12, color: _deepBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Declined',
                      style: TextStyle(
                        color: _deepBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // Graph area
        content,
      ],
    );
  }

  Widget _buildModernLineGraph(List<AttendanceTrendData> displayData) {
    // This function only runs if displayData.length >= 2

    return Column(
      children: [
        // Modern Line Graph
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _navyBlue.withOpacity(0.05),
                _lightNavy.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _navyBlue.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: CustomPaint(
            painter: _LineGraphPainter(
              data: displayData,
              lineColor: _skyBlue,
              dotColor: _lightNavy,
              gridColor: _white.withOpacity(0.05),
            ),
            child: Container(),
          ),
        ),

        const SizedBox(height: 12),

        // Date labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: displayData.map((data) {
              final date = DateTime.parse(data.date);
              final dateStr = DateFormat('MM/dd').format(date);
              final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == data.date;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _skyBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 8,
                          color: _skyBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday ? _skyBlue : _white.withOpacity(0.6),
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Text(
                    '${data.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: _white.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

     
      ],
    );
  }

}

// ============================================================================
// CUSTOM PAINTER FOR LINE GRAPH
// ============================================================================
class _LineGraphPainter extends CustomPainter {
  final List<AttendanceTrendData> data;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;

  _LineGraphPainter({
    required this.data,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return; // Only draw graph elements if there are 2 or more points

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate positions
    final maxPercentage = 100.0;
    final minPercentage = 0.0;
    final range = maxPercentage - minPercentage;

    final points = <Offset>[];
    // This logic assumes data.length >= 2, which is true when called from build.
    // If data.length is 1, the painter won't draw lines/fill, only points.
    // However, the calling widget handles data.length < 2, so we can assume
    // the list is for a trend (length >= 2) or contains points (length >= 1).
    // Let's modify the point calculation for robustness.
    final horizontalFactor = data.length > 1 ? (size.width / (data.length - 1)) : 0.0;

    for (int i = 0; i < data.length; i++) {
      final x = data.length > 1 ? horizontalFactor * i : size.width / 2; // Center if only one point
      final normalizedValue = (data[i].percentage - minPercentage) / range;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }


    // Draw gradient fill under line (only if a line can be drawn)
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height);
      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withOpacity(0.2),
            lineColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line with smooth curves (only if a line can be drawn)
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlPoint1 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          current.dy,
        );
        final controlPoint2 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          next.dy,
        );
        linePath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          next.dx,
          next.dy,
        );
      }

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw dots at data points
    for (int i = 0; i < points.length; i++) {
      // Outer glow
      final glowPaint = Paint()
        ..color = dotColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(points[i], 6, glowPaint);

      // Outer ring
      final outerPaint = Paint()
        ..color = dotColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(points[i], 5, outerPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}