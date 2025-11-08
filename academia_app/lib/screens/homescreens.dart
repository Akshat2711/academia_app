import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../components/subject_info.dart';
import '../components/faculty_info.dart';
import '../screens/login_page.dart';
import 'calender_screen.dart';
import '../screens/annoucement_screen.dart';
import '../screens/imp_links_screen.dart';

//FOR IOS LIKE TRANSITION
import 'package:flutter/cupertino.dart'; 

//FOR BACKUP DAYORDER
import '../utils/day_order_backup.dart';

//for loading animation
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';


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
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail');
      final password = prefs.getString('userPassword');
      
      if (email == null || password == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to refresh: credentials not found')),
          );
        }
        return;
      }

      final url = Uri.parse('https://academia-scrapper-api-fast.onrender.com/scrape');
      final body = jsonEncode({
        "email": email,
        "password": password,
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        //FOR BACKUP HANDLING/////////////////////////

        // ✅ Handle day order (from API or backup)
        int? dayOrder;
        if (data['attendance'] != null && data['attendance']['day_order'] != null) {
          // Day order present in API response
          dayOrder = data['attendance']['day_order'] as int;
          print('✅ Day order from API: $dayOrder');
          
          // Save day order with forecast
          await DayOrderManager.saveDayOrderData(
            currentDayOrder: dayOrder,
            currentDate: DateTime.now(),
          );
        } else {
          // Day order missing from API, use backup
          print('⚠️ Day order missing from API response');
          dayOrder = await DayOrderManager.getCurrentDayOrder();
          
          if (dayOrder != null) {
            print('✅ Using backup day order: $dayOrder');
            // Add day order to data for dashboard
            data['attendance'] = data['attendance'] ?? {};
            data['attendance']['day_order'] = dayOrder;
          } else {
            print('⚠️ No backup day order available');
          }
        }

        /////////////////////////////////////

        
        // Save updated data
        await prefs.setString('userData', jsonEncode(data));
        
        // Update last refresh time
        final now = DateTime.now().toIso8601String();
        await prefs.setString('lastRefreshTime', now);
        
        // **KEY CHANGE: Reset all state variables to trigger complete rebuild**
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
        
        // Reload the data with complete UI rebuild
        await _loadUserData();
        
        // Notify dashboard that data was refreshed
        widget.onDataRefreshed?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data refreshed successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Refresh failed: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing: $e')),
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
                  final faculty = _extractFacultyName(e['faculty_name']);
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

  String _extractFacultyName(dynamic facultyName) {
    if (facultyName == null) return '';
    final str = facultyName.toString();
    if (str.isEmpty) return '';
    // Extract name before parenthesis if exists
    final parts = str.split('(');
    return parts.first.trim();
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
                _buildProfileCard(displayName, regno, program, specialization, semester),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 16),
                _buildQuickActions(),
                if (_courses.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Your Courses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._courses.map((course) => SubjectInfo(course: course)),
                ],
                FacultyInfo(advisors: _advisors.isNotEmpty ? _advisors : null),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
  }








  Widget _buildProfileCard(String name, String regno, String program, String specialization, String semester) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          // Use an orange gradient for the profile card
          gradient: LinearGradient(
            colors: [const Color.fromARGB(201, 255, 153, 0), _primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        regno,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.school, program),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.analytics, specialization),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.book, 'Semester $semester'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.white70, size: 18), // Used a standard icon for dark theme visibility
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final attendance = _overallAttendance;
    final courses = _courseCount > 0 ? _courseCount.toString() : '—';
    final credits = _totalCredits > 0 ? _totalCredits.toString() : '—';
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          // Keeping original colors for differentiation, but adjusting 'Credits' to primary color
          Expanded(child: _buildStatCard(attendance.toStringAsFixed(2), 'Attendance', Colors.greenAccent[400]!)), 
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(courses, 'Courses', Colors.cyanAccent[400]!)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(credits, 'Credits', _primaryColor)), // Orange for Credits
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C), // Dark grey for contrast on black background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color, // Use accent color
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70), // White/light text
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text for section title
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(Icons.announcement_outlined, 'Announcement', _primaryColor,
         onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const AnnouncementScreen()),
            );
          },
        ), // Orange
        const SizedBox(height: 8),
        _buildActionButton(
          Icons.calendar_month,
          'calender',
          _primaryColor,
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const CalendarScreen()),
            );
          },
        ), // orange
        const SizedBox(height: 8),
        _buildActionButton(
          Icons.link_sharp, 'Important Links', _primaryColor,
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const LinksScreen()),
            );
          },
        ), // Orange
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String text, Color color, {VoidCallback? onTap}) {
    // Choose a contrasting color for the icon container based on the action color
    final iconContainerColor = color == Colors.white ? _primaryColor.withOpacity(0.1) : _primaryColor.withOpacity(0.2);
    final iconColor = color == Colors.white ? Colors.white : color;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C), // Dark grey for contrast on black background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconContainerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}