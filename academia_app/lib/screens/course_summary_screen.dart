import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

// Define the keys you use to store the JSON strings in SharedPreferences
const String USER_DATA_KEY = 'userData';
const String GRAPH_DATA_KEY = 'GRAPH_ATTENDANCE';

// --- UPDATED COLOR THEME: VIVID ORANGE (No Green/Blue) ---
const Color _pitchBlack = Color(0xFF000000);
const Color _white = Colors.white;
const Color _vividOrange = Color(0xFFFF9800); // Primary Orange Accent
const Color _lightOrange = Color(0xFFFFB74D); // Lighter shade for borders/subtle elements
// -------------------------------------------

// =================================================================
// 1. DATA MODELS
// =================================================================

class CourseAttendanceData {
  final String courseTitle;
  final String facultyName;
  final double attendancePercentage;
  final int hoursConducted;
  final int hoursAbsent;

  CourseAttendanceData({
    required this.courseTitle,
    required this.facultyName,
    required this.attendancePercentage,
    required this.hoursConducted,
    required this.hoursAbsent,
  });
}

class TestMarks {
  final String testName;
  final double obtainedMarks;
  final double maxMarks;
  final double percentage;

  TestMarks({
    required this.testName,
    required this.obtainedMarks,
    required this.maxMarks,
    required this.percentage,
  });
}

class GraphDataPoint {
  final String date;
  final double percentage;

  GraphDataPoint({required this.date, required this.percentage});
}

// =================================================================
// 2. ASYNCHRONOUS DATA SERVICE (Made Robust)
// =================================================================

class CourseDataService {
  late SharedPreferences _prefs;
  late Map<String, dynamic> _userData;
  late Map<String, dynamic> _graphAttendance;

  static final CourseDataService _instance = CourseDataService._internal();
  factory CourseDataService() => _instance;

  CourseDataService._internal();

  Future<void> loadData() async {
    _prefs = await SharedPreferences.getInstance();

    String? userDataString = _prefs.getString(USER_DATA_KEY);
    String? graphDataString = _prefs.getString(GRAPH_DATA_KEY);

    try {
      _userData = (userDataString != null) ? json.decode(userDataString) : {};
    } catch (e) {
      debugPrint("Error decoding userData: $e");
      _userData = {};
    }

    try {
      _graphAttendance = (graphDataString != null) ? json.decode(graphDataString) : {};
    } catch (e) {
      debugPrint("Error decoding graphData: $e");
      _graphAttendance = {};
    }
  }

  String _getCourseKey(String courseCode, Map<String, dynamic> dataMap) {
    try {
      return dataMap.keys.firstWhere(
        (key) => key.startsWith(courseCode),
        orElse: () => '',
      );
    } catch (e) {
      return '';
    }
  }

  CourseAttendanceData? getCourseAttendance(String courseCode) {
    try {
      final attendanceMap = _userData['attendance']?['attendance']?['courses'] as Map<String, dynamic>?;

      if (attendanceMap == null) return null;

      final key = _getCourseKey(courseCode, attendanceMap);
      if (key.isEmpty) return null;

      final data = attendanceMap[key];
      if (data == null) return null;

      // SAFE PARSING: Uses ?? to provide defaults if JSON fields are missing
      return CourseAttendanceData(
        courseTitle: (data['course_title'] ?? 'Unknown Course').toString(),
        facultyName: (data['faculty_name'] ?? 'N/A').toString(),
        attendancePercentage: ((data['attendance_percentage'] ?? 0) as num).toDouble(),
        hoursConducted: ((data['hours_conducted'] ?? 0) as num).toInt(),
        hoursAbsent: ((data['hours_absent'] ?? 0) as num).toInt(),
      );
    } catch (e) {
      debugPrint("Error parsing attendance for $courseCode: $e");
      return null;
    }
  }

  List<TestMarks> getCourseMarks(String courseCode) {
    try {
      final marksMap = _userData['attendance']?['marks'] as Map<String, dynamic>?;
      if (marksMap == null) return [];

      final relatedKeys = marksMap.keys.where((k) => k.startsWith(courseCode)).toList();
      List<TestMarks> allMarks = [];

      for (var k in relatedKeys) {
        final data = marksMap[k];
        if (data != null && data['tests'] != null && data['tests'] is List) {
          allMarks.addAll(_parseTestMarks(data['tests']));
        }
      }
      return allMarks;
    } catch (e) {
      debugPrint("Error parsing marks for $courseCode: $e");
      return [];
    }
  }

  List<TestMarks> _parseTestMarks(List<dynamic> tests) {
    List<TestMarks> parsed = [];
    for (var test in tests) {
      try {
        parsed.add(TestMarks(
          testName: (test['test_name'] ?? 'Unknown Test').toString(),
          obtainedMarks: ((test['obtained_marks'] ?? 0) as num).toDouble(),
          maxMarks: ((test['max_marks'] ?? 100) as num).toDouble(), // Avoid division by zero issues later
          percentage: ((test['percentage'] ?? 0) as num).toDouble(),
        ));
      } catch (e) {
        // Skip malformed test entry
        continue;
      }
    }
    return parsed;
  }

  List<GraphDataPoint> getCourseGraphData(String courseCode) {
    try {
      final attendanceMap = _userData['attendance']?['attendance']?['courses'] as Map<String, dynamic>?;
      if (attendanceMap == null) return [];

      final key = _getCourseKey(courseCode, attendanceMap);
      if (key.isEmpty || !_graphAttendance.containsKey(key)) {
        return [];
      }

      final singleDataList = _graphAttendance[key];
      if (singleDataList == null || singleDataList is! List || singleDataList.isEmpty) return [];
      
      return singleDataList.map<GraphDataPoint>((item) {
        // Safe parsing for graph points
        String dateStr = (item['date'] ?? '00-00').toString();
        String formattedDate = dateStr.length >= 7 ? dateStr.substring(5) : dateStr;

        return GraphDataPoint(
          date: formattedDate,
          percentage: ((item['percentage'] ?? 0) as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint("Error parsing graph data: $e");
      return [];
    }
  }
}

// =================================================================
// 3. COURSE DETAIL SCREEN
// =================================================================

class CourseDetailScreen extends StatelessWidget {
  final String courseCode;

  CourseDetailScreen({super.key, required this.courseCode});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CourseDataService().loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _pitchBlack,
            appBar: AppBar(
              backgroundColor: _pitchBlack,
              title: const Text('Loading Data...', style: TextStyle(color: _white)),
              iconTheme: const IconThemeData(color: _white),
            ),
            body: const Center(child: CircularProgressIndicator(color: _vividOrange)),
          );
        }

        final CourseDataService dataService = CourseDataService();
        
        // Fetch data
        CourseAttendanceData? fetchedAttendance = dataService.getCourseAttendance(courseCode);
        final marksData = dataService.getCourseMarks(courseCode);
        final graphData = dataService.getCourseGraphData(courseCode);

        // FALLBACK: If attendance is completely missing, create a dummy object so the page works.
        // This ensures users can still see Marks or other info even if Attendance is null.
        final CourseAttendanceData attendanceData = fetchedAttendance ?? CourseAttendanceData(
          courseTitle: 'Course: $courseCode',
          facultyName: 'Data Not Available',
          attendancePercentage: 0.0,
          hoursConducted: 0,
          hoursAbsent: 0,
        );

        return Scaffold(
          backgroundColor: _pitchBlack,
          appBar: AppBar(
            backgroundColor: _pitchBlack,
            title: const Text("Course Overview", style: TextStyle(color: _white)),
            iconTheme: const IconThemeData(color: _white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendanceData.courseTitle,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _white),
                ),
                Text(
                  'Course Code: $courseCode',
                  style: TextStyle(fontSize: 16, color: _vividOrange.withOpacity(0.8)),
                ),
                const SizedBox(height: 20),

                // Only show Faculty info if we actually have data, otherwise simple N/A
                _buildInfoCard(
                  title: 'Faculty & Type',
                  icon: Icons.info_outline,
                  children: [
                    _buildDetailRow(
                      label: 'Faculty Name',
                      value: attendanceData.facultyName.split('(').first.trim(),
                    ),
                    _buildDetailRow(
                      label: 'Course Type',
                      value: attendanceData.courseTitle.contains('Practical') ? 'Practical' : 'Theory',
                    ),
                  ],
                ),

                _buildInfoCard(
                  title: 'Attendance Status',
                  icon: Icons.check_circle_outline,
                  children: [
                    _buildAttendanceIndicator(attendanceData.attendancePercentage),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      label: 'Current Percentage',
                      value: '${attendanceData.attendancePercentage.toStringAsFixed(2)}%',
                      isAccent: true,
                    ),
                    _buildDetailRow(
                      label: 'Hours Absent',
                      value: attendanceData.hoursAbsent.toString(),
                    ),
                    _buildDetailRow(
                      label: 'Total Hours Conducted',
                      value: attendanceData.hoursConducted.toString(),
                    ),
                  ],
                ),

                _buildInfoCard(
                  title: 'Attendance Trend',
                  icon: Icons.trending_up,
                  children: [
                    CourseAttendanceGraph(graphData: graphData),
                    if (graphData.length < 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          graphData.isEmpty 
                              ? 'No historical trend data available.' 
                              : 'Note: Only ${graphData.length} historical data point(s) found.',
                          style: TextStyle(color: _vividOrange.withOpacity(0.6), fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                      ),
                  ],
                ),

                _buildInfoCard(
                  title: 'Assessment Marks',
                  icon: Icons.assignment_turned_in_outlined,
                  children: [
                    if (marksData.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No internal assessment marks found.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
                        ),
                      ),
                    ...marksData.map((marks) => _buildMarkEntry(marks)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI Helper Methods (Orange/Black/White) ---

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(0.0),
      decoration: const BoxDecoration(
        color: _pitchBlack,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _vividOrange, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _white),
              ),
            ],
          ),
          const Divider(color: Color(0xFF333333), height: 30, thickness: 0.8), // Dark grey divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value, bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isAccent ? _vividOrange : _white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceIndicator(double percentage) {
    Color color = _vividOrange;

    if (percentage >= 75) {
      color = _vividOrange;
    } else {
      color = Colors.redAccent;
    }
    
    // Safety check for NaN or Infinity
    double safePercent = percentage.clamp(0.0, 100.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: safePercent / 100,
                strokeWidth: 10,
                backgroundColor: const Color(0xFF2C2C2E),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkEntry(TestMarks marks) {
    Color markColor = _vividOrange;

    if (marks.percentage > 70) {
      markColor = _vividOrange;
    } else {
      markColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  marks.testName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: _white),
                ),
              ),
              Text(
                '${marks.obtainedMarks.toStringAsFixed(1)} / ${marks.maxMarks.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: markColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Percentage: ${marks.percentage.toStringAsFixed(2)}%',
            style: TextStyle(color: markColor.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// --- Bar Graph Widget ---
class CourseAttendanceGraph extends StatelessWidget {
  final List<GraphDataPoint> graphData;

  const CourseAttendanceGraph({super.key, required this.graphData});

  @override
  Widget build(BuildContext context) {
    if (graphData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No attendance data available for graphing.', style: TextStyle(color: Colors.white70)),
        )
      );
    }

    // Graph display for multiple points
    final minPercent = graphData.map((p) => p.percentage).reduce(min);
    final maxPercent = graphData.map((p) => p.percentage).reduce(max);
    final baseLine = max(70.0, minPercent - 5.0);
    final range = maxPercent - baseLine;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: graphData.map((point) {
          double normalizedHeight = 0.5;
          if (range > 0) {
            normalizedHeight = ((point.percentage - baseLine) / range).clamp(0.0, 1.0);
          }
          final barHeight = normalizedHeight * 120 + 20;

          Color barColor = _vividOrange.withOpacity(0.8);
          if (point.percentage < 75) {
            barColor = Colors.redAccent.withOpacity(0.8);
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                  '${point.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _vividOrange)
              ),
              const SizedBox(height: 4),
              Container(
                width: 25,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
              const SizedBox(height: 4),
              Text(point.date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70)),
            ],
          );
        }).toList(),
      ),
    );
  }
}