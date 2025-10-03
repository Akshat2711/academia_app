import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// TIMETABLE SCREEN - Dynamic student timetable
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
  int _currentDay = 5; // Hardcoded as requested

  // Time slots
  List<String> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) return;

      final raw = prefs.getString('userData');
      if (raw == null || raw.isEmpty) return;

      final Map<String, dynamic> data = json.decode(raw);

      // 1️⃣ Identify batch
      final studentBatch = data['timetable']?['student_info']?['batch'] ?? '1';
      final Map<String, dynamic> fullBatchTimetable = _hardcodedBatchTimetable();
      final batchKey = 'Batch$studentBatch';

      if (!fullBatchTimetable.containsKey(batchKey)) return;

      setState(() {
        _batchTimetable = fullBatchTimetable[batchKey];
        _timeSlots = List<String>.from(_batchTimetable!['time_slots']);
      });

      // 2️⃣ Load student courses
      final List<dynamic>? courseList = data['timetable']?['courses'];
      if (courseList != null) {
        final parsedCourses = courseList.map((e) {
          final slot = e['slot']?.toString() ?? '';
          final code = e['course_code']?.toString() ?? '';
          final title = e['course_title']?.toString() ?? '';
          return {
            'slot': slot,
            'display': '$code — $title',
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

  String _getCourseForSlot(String slot) {
    for (var course in _courses) {
      final courseSlot = course['slot'] as String;
      // Handle multi-slot ranges like L41-L42
      if (courseSlot.contains('-')) {
        final parts = courseSlot.split('-');
        for (var p in parts) {
          if (p.trim().isEmpty) continue;
          if (slot.contains(p.trim())) return course['display'];
        }
      } else if (slot.contains(courseSlot)) {
        return course['display'];
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _batchTimetable == null
              ? Center(child: Text('No timetable found', style: TextStyle(color: Colors.grey[600])))
              : SingleChildScrollView(
              scrollDirection: Axis.horizontal, 
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical, 
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Top row: Days
                      Row(
                        children: [
                          const SizedBox(width: 80), // empty corner for time column
                          ...List.generate(5, (index) {
                            final dayLabel = 'Day ${index + 1}';
                            final isToday = _currentDay == (index + 1);
                            return Container(
                              width: 120,
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isToday ? Colors.indigo[200] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Time slots + day columns (VERTICAL scrollable now)
                      ...List.generate(_timeSlots.length, (tIndex) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time slot column
                            Container(
                              width: 80,
                              height: 60,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  _timeSlots[tIndex],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            // Day columns
                            ...List.generate(5, (dIndex) {
                              final dayLabel = 'Day ${dIndex + 1}';
                              final slots = List<String>.from(_batchTimetable!['schedule'][dayLabel]);
                              final slotCode = slots[tIndex];
                              final courseName = _getCourseForSlot(slotCode);
                              final isToday = _currentDay == (dIndex + 1);

                              return Container(
                                width: 120,
                                height: 60,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: courseName.isNotEmpty
                                      ? Colors.indigo[100]
                                      : isToday
                                          ? Colors.indigo[50]
                                          : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    courseName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: courseName.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                      color: courseName.isNotEmpty ? Colors.indigo[900] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            )
    );
  }
}
