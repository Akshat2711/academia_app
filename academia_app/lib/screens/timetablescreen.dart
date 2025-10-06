import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ============================================================================
// TIMETABLE SCREEN - Modern card-based timetable with horizontal scrolling
// ============================================================================
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
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
    _pageController.dispose();
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
      
      print('DEBUG: Day order from localStorage: $dayOrder');
      
      // Identify batch
      final studentBatch = data['timetable']?['student_info']?['batch'] ?? '1';
      final Map<String, dynamic> fullBatchTimetable = _hardcodedBatchTimetable();
      final batchKey = 'Batch$studentBatch';
      
      if (!fullBatchTimetable.containsKey(batchKey)) return;
      
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
    final slots = List<String>.from(_batchTimetable!['schedule'][dayLabel]);
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

  // Notification scheduling removed

  Widget _buildDayCard(int day, bool isCurrentDay) {
    final classes = _getClassesForDay(day);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isCurrentDay
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCurrentDay ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isCurrentDay 
                ? const Color(0xFF6366F1).withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: isCurrentDay ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $day',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isCurrentDay ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.class_,
                          size: 16,
                          color: isCurrentDay ? Colors.white70 : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${classes.length} ${classes.length == 1 ? 'Class' : 'Classes'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isCurrentDay ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isCurrentDay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.today, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Classes List
          if (classes.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: isCurrentDay ? Colors.white54 : Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No classes scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        color: isCurrentDay ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classInfo = classes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrentDay
                          ? Colors.white.withOpacity(0.15)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrentDay
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCurrentDay
                                    ? Colors.white.withOpacity(0.2)
                                    : const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                classInfo['slot']!,
                                style: TextStyle(
                                  color: isCurrentDay
                                      ? Colors.white
                                      : const Color(0xFF6366F1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCurrentDay
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: isCurrentDay ? Colors.white : Colors.amber[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    classInfo['time']!,
                                    style: TextStyle(
                                      color: isCurrentDay ? Colors.white : Colors.amber[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          classInfo['course']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentDay ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.room,
                              size: 16,
                              color: isCurrentDay ? Colors.white70 : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              classInfo['classroom']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isCurrentDay ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _batchTimetable == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No timetable found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                          final isCurrentDay = _currentDay == day;
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
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey[300],
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
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          // Only highlight if day is actually current AND valid (1-5)
                          final isCurrentDay = _currentDay == day && _currentDay >= 1 && _currentDay <= 5;
                          return _buildDayCard(day, isCurrentDay);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}