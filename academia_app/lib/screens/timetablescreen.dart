import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/day_order_card.dart';


// ============================================================================
// TIMETABLE SCREEN - Modern card-based timetable with horizontal scrolling
// ============================================================================
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // --- COLOR PALETTE ---
  static const Color _pitchBlack = Color(0xFF000000); // Pitch Black Background
  static const Color _neonPink = Color(0xFFFF1493);  // Neon Reddish-Pink (Deep Pink)
  static const Color _white = Colors.white;          // White Foreground/Text
  static const Color _cardBackground = Color(0xFF1A1A1A); // Slightly lighter black for card base

  bool _loading = true;
  Map<String, dynamic>? _batchTimetable;
  List<Map<String, dynamic>> _courses = [];
  int _currentDay = 0;
  late PageController _pageController;
  
  // Time slots
  List<String> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  @override
  void dispose() {
    // Check if _pageController has been initialized before disposing
    if (mounted && _batchTimetable != null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) return;
      
      final raw = prefs.getString('userData');
      if (raw == null || raw.isEmpty) return;
      
      final Map<String, dynamic> data = json.decode(raw);
      
      // Load day order from localStorage
      var dayOrder = data['attendance']?['day_order'];
      if (dayOrder is String) {
        dayOrder = int.tryParse(dayOrder) ?? 0;
      } else if (dayOrder is! int) {
        dayOrder = 0;
      }
      
      // ignore: avoid_print
      print('DEBUG: Day order from localStorage: $dayOrder');
      
      // Identify batch
      final studentBatch = data['timetable']?['student_info']?['batch'] ?? '1';
      final Map<String, dynamic> fullBatchTimetable = _hardcodedBatchTimetable();
      final batchKey = 'Batch$studentBatch';
      
      if (!fullBatchTimetable.containsKey(batchKey)) {
        setState(() => _loading = false);
        return;
      }
      
      setState(() {
        _currentDay = dayOrder as int;
        _batchTimetable = fullBatchTimetable[batchKey];
        _timeSlots = List<String>.from(_batchTimetable!['time_slots']);
      });
      
      // Initialize page controller to start at current day or first day if invalid
      final initialPage = (_currentDay >= 1 && _currentDay <= 5) ? _currentDay - 1 : 0;
      _pageController = PageController(initialPage: initialPage);
      
      // Load student courses
      final List<dynamic>? courseList = data['timetable']?['courses'];
      if (courseList != null) {
        final parsedCourses = courseList.map((e) {
          final slot = e['slot']?.toString() ?? '';
          final code = e['course_code']?.toString() ?? '';
          final title = e['course_title']?.toString() ?? '';
          final venue = e['room_no']?.toString() ?? 'TBA';
          return {
            'slot': slot,
            'display': '$code — $title',
            'venue': venue,
          };
        }).toList();
        
        setState(() {
          _courses = List<Map<String, dynamic>>.from(parsedCourses);
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading timetable: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _hardcodedBatchTimetable() {
    return {
      "Batch1": {
        "time_slots": [
          "08:00 - 08:50",
          "08:50 - 09:40",
          "09:45 - 10:35",
          "10:40 - 11:30",
          "11:35 - 12:25",
          "12:30 - 01:20",
          "01:25 - 02:15",
          "02:20 - 03:10",
          "03:10 - 04:00",
          "04:00 - 04:50",
          "04:50 - 05:30",
          "05:30 - 06:10"
        ],
        "schedule": {
          "Day 1": ["A", "A / X", "F / X", "F", "G", "P6", "P7", "P8", "P9", "P10", "L11", "L12"],
          "Day 2": ["P11", "P12/X", "P13/X", "P14", "P15", "B", "B", "G", "G", "A", "L21", "L22"],
          "Day 3": ["C", "C / X", "A / X", "D", "B", "P26", "P27", "P28", "P29", "P30", "L31", "L32"],
          "Day 4": ["P31", "P32/X", "P33/X", "P34", "P35", "D", "D", "B", "E", "C", "L41", "L42"],
          "Day 5": ["E", "E / X", "C / X", "F", "D", "P46", "P47", "P48", "P49", "P50", "L51", "L52"]
        }
      },
      "Batch2": {
        "time_slots": [
          "08:00 - 08:50",
          "08:50 - 09:40",
          "09:45 - 10:35",
          "10:40 - 11:30",
          "11:35 - 12:25",
          "12:30 - 01:20",
          "01:25 - 02:15",
          "02:20 - 03:10",
          "03:10 - 04:00",
          "04:00 - 04:50",
          "04:50 - 05:30",
          "05:30 - 06:10"
        ],
        "schedule": {
          "Day 1": ["P1", "P2/X", "P3/X", "P4", "P5", "A", "A", "F", "F", "G", "L11", "L12"],
          "Day 2": ["B", "B / X", "G / X", "G", "A", "P16", "P17", "P18", "P19", "P20", "L21", "L22"],
          "Day 3": ["P21", "P22/X", "P23/X", "P24", "P25", "C", "C", "A", "D", "B", "L31", "L32"],
          "Day 4": ["D", "D / X", "B / X", "E", "C", "P36", "P37", "P38", "P39", "P40", "L41", "L42"],
          "Day 5": ["P41", "P42/X", "P43/X", "P44", "P45", "E", "E", "C", "F", "D", "L51", "L52"]
        }
      }
    };
  }

  Map<String, String> _getCourseForSlot(String slot) {
    for (var course in _courses) {
      final courseSlot = course['slot'] as String;
      // Handle multi-slot ranges like L41-L42
      if (courseSlot.contains('-')) {
        final parts = courseSlot.split('-');
        for (var p in parts) {
          if (p.trim().isEmpty) continue;
          if (slot.contains(p.trim())) {
            return {
              'display': course['display'],
              'venue': course['venue'] ?? 'TBA',
            };
          }
        }
      } else if (slot.contains(courseSlot)) {
        return {
          'display': course['display'],
          'venue': course['venue'] ?? 'TBA',
        };
      }
    }
    return {'display': '', 'venue': ''};
  }

  List<Map<String, String>> _getClassesForDay(int day) {
    if (day < 1 || day > 5 || _batchTimetable == null) {
      return [];
    }
    
    final dayLabel = 'Day $day';
    final schedule = _batchTimetable!['schedule'];
    if (schedule == null || schedule[dayLabel] == null) {
      return [];
    }

    final slots = List<String>.from(schedule[dayLabel]);
    final List<Map<String, String>> dayClasses = [];
    
    for (int i = 0; i < slots.length && i < _timeSlots.length; i++) {
      final slotCode = slots[i];
      final courseInfo = _getCourseForSlot(slotCode);
      
      if (courseInfo['display']!.isNotEmpty) {
        dayClasses.add({
          'time': _timeSlots[i],
          'course': courseInfo['display']!,
          'classroom': courseInfo['venue']!,
          'slot': slotCode,
        });
      }
    }
    
    return dayClasses;
  }

 

 
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pitchBlack, // ⬅️ Pitch Black
      appBar: AppBar(
        title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.w600, color: _white)), // ⬅️ White Text
        backgroundColor: _pitchBlack, // ⬅️ Pitch Black
        foregroundColor: _neonPink, // ⬅️ Neon Pink Icon
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Changed to refresh icon for more appropriate action
            onPressed: () {
              // Reload functionality goes here
              setState(() => _loading = true);
              _loadTimetable();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _neonPink)) // ⬅️ Neon Pink Loading Indicator
          : _batchTimetable == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: _neonPink.withOpacity(0.5)), // ⬅️ Neon Pink Icon
                      const SizedBox(height: 16),
                      Text(
                        'No timetable found',
                        style: TextStyle(fontSize: 18, color: _white.withOpacity(0.7)), // ⬅️ White Text
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Day indicator dots
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final day = index + 1;
                          // Only check if it's the valid current day
                          final isCurrentDay = _currentDay == day && _currentDay >= 1 && _currentDay <= 5;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isCurrentDay ? 32 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isCurrentDay
                                    ? _neonPink // ⬅️ Neon Pink Active Dot
                                    : _white.withOpacity(0.3), // ⬅️ White Inactive Dot
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    // Page view with day cards
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: 5,
                        onPageChanged: (index) {
                          // Keep the Day Order highlighting separate
                          setState(() {
                            // Can track which page the user is viewing, if needed for complex logic
                            // _currentViewedDay = index + 1; 
                          });
                        },
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final isCurrentDay = _currentDay == day && _currentDay >= 1 && _currentDay <= 5;
                          final classes = _getClassesForDay(day);
                          return DayOrderCard(day: day, isCurrentDay: isCurrentDay, classes: classes);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}