import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ============================================================================
// ATTENDANCE TREND WIDGET - Shows last 5 days attendance with trend graph
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
  static const Color _pitchBlack = Color(0xFF000000);
  static const Color _neonPink = Color(0xFFFF00FF);
  static const Color _white = Colors.white;
  static const Color _greenCheck = Color(0xFF00FFC0);
  static const Color _redAlert = Color(0xFFFF4444);

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

      // Detect if attendance declined
      _hasDeclined = false;
      if (trends.length >= 2) {
        for (int i = 1; i < trends.length; i++) {
          if (trends[i].percentage < trends[i - 1].percentage) {
            _hasDeclined = true;
            break;
          }
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _white,
                ),
              ),
            ),
            if (_hasDeclined)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _redAlert.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _redAlert, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_down, size: 12, color: _redAlert),
                    const SizedBox(width: 4),
                    const Text(
                      'Declined',
                      style: TextStyle(
                        color: _redAlert,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Graph area
        if (_trendData.isNotEmpty)
          _buildTrendGraph()
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No trend data yet',
                style: TextStyle(color: _white.withOpacity(0.5), fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendGraph() {
    final maxPercentage = 100.0;
    const graphHeight = 96.0;
    const barWidth = 35.0;

    // Display only available data points (no gaps, just consecutive available dates)
    final displayData = _trendData.length > 5 
        ? _trendData.sublist(_trendData.length - 5)
        : _trendData;

    return Column(
      children: [
        // Graph visualization
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: graphHeight,
            padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 0),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neonPink.withOpacity(0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: displayData.map((data) {
                final heightPercentage = data.percentage / maxPercentage;
                final barHeight = ((graphHeight - 8) * heightPercentage).clamp(2.0, graphHeight - 8);
                
                // Determine color based on percentage
                Color barColor = _neonPink;
                if (data.percentage >= 85) {
                  barColor = const Color.fromARGB(255, 221, 54, 255);
                } else if (data.percentage >= 75) {
                  barColor = const Color.fromARGB(255, 239, 197, 246);
                }

                return Tooltip(
                  message: '${data.percentage.toStringAsFixed(1)}%',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: barWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Date labels with attendance percentage below
        SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayData.map((data) {
              final date = DateTime.parse(data.date);
              final dateStr = DateFormat('MM/dd').format(date);
              final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == data.date;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Today indicator
                  if (isToday)
                    const Icon(Icons.today, size: 11, color: Color.fromARGB(255, 183, 237, 223))
                  else
                    const SizedBox(height: 11),
                  
                  // Date
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? Color.fromARGB(255, 183, 237, 223) : _white.withOpacity(0.6),
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Attendance percentage
                  Text(
                    '${data.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 9,
                      color: _white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 6),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatChip(
              'Peak',
              '${displayData.map((e) => e.percentage).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%',
              const Color.fromARGB(255, 255, 140, 211),
            ),
            _buildStatChip(
              'Low',
              '${displayData.map((e) => e.percentage).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}%',
              const Color.fromARGB(255, 237, 182, 239),
            ),
            _buildStatChip(
              'Avg',
              '${(displayData.map((e) => e.percentage).reduce((a, b) => a + b) / displayData.length).toStringAsFixed(1)}%',
              const Color.fromARGB(255, 236, 236, 236),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}