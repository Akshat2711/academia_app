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
// 1. DATA MODELS (Remain the same)
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
// 2. ASYNCHRONOUS DATA SERVICE (Defensive fixes retained)
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

    _userData = (userDataString != null) ? json.decode(userDataString) : {};
    _graphAttendance = (graphDataString != null) ? json.decode(graphDataString) : {};
    
    
    if (_userData.isEmpty || _graphAttendance.isEmpty) {
       debugPrint('WARNING: Course data or graph data not found in SharedPreferences.');
    }
  }

  String _getCourseKey(String courseCode, Map<String, dynamic> dataMap) {
    return dataMap.keys.firstWhere(
      (key) => key.startsWith(courseCode),
      orElse: () => '',
    );
  }

  CourseAttendanceData? getCourseAttendance(String courseCode) {
    // FIX: Using null-aware operators (?) for safe navigation
    final attendanceMap = _userData['attendance']?['attendance']?['courses'] as Map<String, dynamic>?;
    
    if (attendanceMap == null) return null;

    final key = _getCourseKey(courseCode, attendanceMap);
    if (key.isEmpty) return null;

    final data = attendanceMap[key];
    if (data == null) return null;

    return CourseAttendanceData(
      courseTitle: data['course_title'] as String,
      facultyName: data['faculty_name'] as String,
      attendancePercentage: (data['attendance_percentage'] as num).toDouble(),
      hoursConducted: data['hours_conducted'] as int,
      hoursAbsent: data['hours_absent'] as int,
    );
  }

  List<TestMarks> getCourseMarks(String courseCode) {
    // FIX: Using null-aware operators (?)
    final marksMap = _userData['attendance']?['marks'] as Map<String, dynamic>?;
    if (marksMap == null) return [];

    final relatedKeys = marksMap.keys.where((k) => k.startsWith(courseCode)).toList();
    List<TestMarks> allMarks = [];

    for (var k in relatedKeys) {
      final data = marksMap[k];
      if (data != null && data['tests'] != null) {
        allMarks.addAll(_parseTestMarks(data['tests']));
      }
    }
    return allMarks;
  }

  List<TestMarks> _parseTestMarks(List<dynamic> tests) {
    return tests.map((test) {
      return TestMarks(
        testName: test['test_name'] as String,
        obtainedMarks: (test['obtained_marks'] as num).toDouble(),
        maxMarks: (test['max_marks'] as num).toDouble(),
        percentage: (test['percentage'] as num).toDouble(),
      );
    }).toList();
  }

  List<GraphDataPoint> getCourseGraphData(String courseCode) {
    // FIX: Using null-aware operators (?)
    final attendanceMap = _userData['attendance']?['attendance']?['courses'] as Map<String, dynamic>?;
    if (attendanceMap == null) return [];
    
    final key = _getCourseKey(courseCode, attendanceMap);
    if (key.isEmpty || !_graphAttendance.containsKey(key)) {
      return [];
    }

    final singleDataList = _graphAttendance[key];
    if (singleDataList == null || singleDataList.isEmpty) return [];
    return singleDataList.map<GraphDataPoint>((item) {
      // Format date string to be shorter for graph labels (e.g., "01/15" instead of full date)
      String dateStr = item['date'].toString();
      String formattedDate = dateStr.length >= 7 ? dateStr.substring(5) : dateStr;
      
      return GraphDataPoint(
        date: formattedDate,
        percentage: (item['percentage'] as num).toDouble(),
      );
    }).toList();

  }
}

// =================================================================
// 3. COURSE DETAIL SCREEN (Orange Theme & Original Bar Graph)
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
            backgroundColor: _pitchBlack, // Pitch black background
            appBar: AppBar(
              backgroundColor: _pitchBlack, // Black app bar
              title: const Text('Loading Data...', style: TextStyle(color: _white)),
              iconTheme: const IconThemeData(color: _white), // White back icon
            ),
            body: const Center(child: CircularProgressIndicator(color: _vividOrange)),
          );
        }

        final CourseDataService dataService = CourseDataService();
        final attendanceData = dataService.getCourseAttendance(courseCode);
        final marksData = dataService.getCourseMarks(courseCode);
        final graphData = dataService.getCourseGraphData(courseCode);

        if (attendanceData == null) {
          return Scaffold(
            backgroundColor: _pitchBlack,
            appBar: AppBar(
              backgroundColor: _pitchBlack,
              title: const Text('Course Details', style: TextStyle(color: _white)),
              iconTheme: const IconThemeData(color: _white),
            ),
            body: Center(
              child: Text(
                'Error: No attendance data found for course code: $courseCode.',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _pitchBlack, // Pitch black background
          appBar: AppBar(
            backgroundColor: _pitchBlack, // Black app bar
            title: const Text("Course Overview", style: TextStyle(color: _white)),
            iconTheme: const IconThemeData(color: _white), // White back icon
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
                    CourseAttendanceGraph(graphData: graphData), // Reverting to Bar Chart
                    if (graphData.length < 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Note: Only ${graphData.length} historical data point(s) found.',
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
                      const Text(
                        'No internal assessment marks found.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
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
              color: isAccent ? _vividOrange : _white, // Use vividOrange for main percentage
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceIndicator(double percentage) {
    Color color = _vividOrange; 

    // Set color based on threshold for clear visual feedback (using only Orange/Red)
    if (percentage >= 75) {
      color = _vividOrange; // Use Orange for non-critical/safe zone
    } else {
      color = Colors.redAccent; // Use Red for critical zone (<75%)
    }

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
                value: percentage / 100,
                strokeWidth: 10, 
                backgroundColor: const Color(0xFF2C2C2E), // Dark circle background
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
    
    // Set color based on performance (using only Orange/Red)
    if (marks.percentage > 70) {
      markColor = _vividOrange; // Strong/Good performance
    } else {
      markColor = Colors.redAccent; // Low performance
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

// --- Bar Graph Widget (The Original Style, Re-colored) ---
class CourseAttendanceGraph extends StatelessWidget {
  final List<GraphDataPoint> graphData;

  const CourseAttendanceGraph({super.key, required this.graphData});

  @override
  Widget build(BuildContext context) {
    if (graphData.isEmpty) {
      return const Center(child: Text('No attendance data available for graphing.', style: TextStyle(color: Colors.white70)));
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
          // Apply color based on threshold using only Orange/Red
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
                  color: barColor, // Orange or Red
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