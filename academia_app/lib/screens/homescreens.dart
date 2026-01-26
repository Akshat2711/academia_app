import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../components/subject_info.dart';
import '../components/faculty_info.dart';
import '../screens/login_page.dart';
//user_data_refresh service
import '../services/user_data_refresh.dart';


//profile card
import '../widgets/profile_card_widget.dart';



//for loading animation
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

//stats bar component
import '../components/stats_bar.dart';
//quick actions component
import '../components/quick_actions.dart';
//for contacting support
import '../components/contact_us.dart';


// ============================================================================
// HOME SCREEN - Student profile and overview
// ============================================================================
class HomeScreen extends StatefulWidget {
  final VoidCallback? onDataRefreshed;
  
  const HomeScreen({super.key, this.onDataRefreshed});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Define the new primary colors
  static const Color _primaryColor = Colors.orange; // New primary accent color
  static const Color _backgroundColor = Colors.black; // New pitch black background

  Map<String, dynamic>? studentInfo;
  double _overallAttendance = 0.0;
  int _courseCount = 0;
  int _totalCredits = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];
  Map<String, dynamic> _advisors = {};
  String _lastRefreshText = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Format the last refresh time
  String _formatLastRefresh(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    
    try {
      final lastRefresh = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(lastRefresh);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${(difference.inDays / 7).floor()}w ago';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _refreshData() async {
    try {
      // CALL REFRESH SERVICE
      final success = await DataRefreshService.refreshData();

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to refresh')),
          );
        }
        return;
      }

      // 🔄 Reset state to force UI rebuild 
      setState(() {
        studentInfo = null;
        _overallAttendance = 0.0;
        _courseCount = 0;
        _totalCredits = 0;
        _courses = [];
        _advisors = {};
        _lastRefreshText = '';
        _loading = true;
      });

      // reload data from SharedPreferences
      await _loadUserData();
      widget.onDataRefreshed?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error refreshing data')),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('userData');
      final lastRefreshTime = prefs.getString('lastRefreshTime');
      
      // Update last refresh text
      setState(() {
        _lastRefreshText = _formatLastRefresh(lastRefreshTime);
      });
      
      if (dataString != null && dataString.isNotEmpty) {
        final parsedData = jsonDecode(dataString);

        // Load student info
        try {
          if (parsedData['attendance'] != null && parsedData['attendance'] is Map) {
            final attendanceData = parsedData['attendance'] as Map;
            if (attendanceData['student_info'] != null && attendanceData['student_info'] is Map) {
              studentInfo = Map<String, dynamic>.from(attendanceData['student_info']);
            }
          }
        } catch (e) {
          print('Error loading student info: $e');
        }

        // Load overall attendance
        try {
          if (parsedData['attendance'] != null && parsedData['attendance'] is Map) {
            final attendanceRoot = parsedData['attendance'] as Map;
            if (attendanceRoot['attendance'] != null && attendanceRoot['attendance'] is Map) {
              final attendanceInner = attendanceRoot['attendance'] as Map;
              final oa = attendanceInner['overall_attendance'];
              if (oa != null && oa is num) {
                _overallAttendance = oa.toDouble();
              }
              
              final courses = attendanceInner['courses'];
              if (courses != null && courses is Map) {
                _courseCount = courses.length;
              }
            }
          }
        } catch (e) {
          print('Error loading attendance: $e');
        }

        // Load timetable courses
        try {
          if (parsedData['timetable'] != null && parsedData['timetable'] is Map) {
            final timetableRoot = parsedData['timetable'] as Map;
                // Load advisors if present
                try {
                  if (timetableRoot['advisors'] != null && timetableRoot['advisors'] is Map) {
                    final advisors = timetableRoot['advisors'] as Map;
                    _advisors = Map<String, dynamic>.from(advisors.map((k, v) => MapEntry(k.toString(), v)));
                  }
                } catch (e) {
                  print('Error loading advisors: $e');
                }
            
            // Load courses list
            if (timetableRoot['courses'] != null && timetableRoot['courses'] is List) {
              final coursesList = timetableRoot['courses'] as List;
              final List<Map<String, dynamic>> parsed = [];
              
              for (final e in coursesList) {
                if (e != null && e is Map) {
                  final code = e['course_code']?.toString() ?? '';
                  final title = e['course_title']?.toString() ?? '';
                  final credits = e['credit'] is num ? (e['credit'] as num).toInt() : 0;
                  final faculty = e['faculty_name']?.toString() ?? '';
                  final slot = e['slot']?.toString() ?? '';
                  final room = e['room_no']?.toString() ?? e['room']?.toString() ?? '';
                  final category = e['category']?.toString() ?? '';
                  
                  // Only add if it has at least a code or title
                  if (code.isNotEmpty || title.isNotEmpty) {
                    final course = {
                      'code': code,
                      'title': title,
                      'credits': credits,
                      'faculty': faculty,
                      'slot': slot,
                      'room': room,
                      'category': category,
                    };
                    parsed.add(course);
                  }
                }
              }
              
              if (parsed.isNotEmpty) {
                _courses = parsed;
              }
            }
            
            // Load total credits
            if (timetableRoot['total_credits'] != null && timetableRoot['total_credits'] is num) {
              _totalCredits = (timetableRoot['total_credits'] as num).toInt();
            } else if (timetableRoot['courses'] != null && timetableRoot['courses'] is List) {
              // Compute credits sum if total_credits not present
              int sum = 0;
              final coursesList = timetableRoot['courses'] as List;
              for (final e in coursesList) {
                if (e != null && e is Map && e['credit'] != null && e['credit'] is num) {
                  sum += (e['credit'] as num).toInt();
                }
              }
              if (sum > 0) {
                _totalCredits = sum;
              }
            }
          }
        } catch (e) {
          print('Error loading timetable: $e');
        }

        setState(() {
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _backgroundColor, // Use black background for loading
        body: Center(child: CircularProgressIndicator(color: _primaryColor)), // Use orange for indicator
      );
    }

  final displayName = studentInfo?['name']?.toString() ?? 'No data found';
  final regno = studentInfo?['registration_number']?.toString() ?? 'No data found';
  final program = studentInfo?['program']?.toString() ?? 'No data found';
  final specialization = studentInfo?['specialization']?.toString() ?? 'No data found';
  final semester = studentInfo?['semester']?.toString() ?? 'No data found';

  return Scaffold(
    backgroundColor: _backgroundColor, // Pitch black background
    body: LiquidPullToRefresh(
      onRefresh: _refreshData,         
      color: _primaryColor,              // Orange liquid color
      backgroundColor: Colors.black,     // Behind the liquid
      showChildOpacityTransition: false, // Smooth fade of child
      springAnimationDurationInMilliseconds: 500,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Console', style: TextStyle(fontWeight: FontWeight.w600)),
                if (_lastRefreshText.isNotEmpty)
                  Text(
                    'Updated $_lastRefreshText',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                color: const Color.fromARGB(255, 255, 158, 67),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  // Remove all user stored data in local storage
                  await prefs.remove('userData');
                  await prefs.remove('customEvents');
                  await prefs.remove('GRAPH_ATTENDANCE');
                  await prefs.remove('userEmail');
                  await prefs.remove('userPassword');


                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CLoginPage()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
SliverPadding(
  padding: const EdgeInsets.all(16),
  sliver: SliverList(
    delegate: SliverChildListDelegate([
      // Info banner at the top
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(23, 107, 106, 106),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: const Color.fromARGB(255, 62, 62, 62), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tip: Pull down from the top to refresh data.',
                style: TextStyle(
                  color: const Color.fromARGB(255, 62, 62, 62),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // Profile Card
      SlidingProfileAnnouncementWidget(
        name: displayName,
        regno: regno,
        program: program,
        specialization:specialization,
        semester: semester,
      ),
      
      const SizedBox(height: 16),

      // Stats Grid
      StatsBar(
        overallAttendance: _overallAttendance,
        courseCount: _courseCount,
        totalCredits: _totalCredits,
        primaryColor: _primaryColor,
      ),
      const SizedBox(height: 16),

      // Quick Actions
      QuickActions(primaryColor: _primaryColor),

      // Courses Section
      if (_courses.isNotEmpty) ...[
        const SizedBox(height: 30),
        Text(
            '  Your Courses',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        const SizedBox(height: 22),
        ..._courses.map((course) => SubjectInfo(course: course)),
      ],

      // Faculty Info
      const SizedBox(height: 24),
      FacultyInfo(advisors: _advisors.isNotEmpty ? _advisors : null),
      // Contact Support Section
      ContactUs(),
      const SizedBox(height: 100),
    ]),
  ),
),

        ],
      ),
    ),
  );
  }


}