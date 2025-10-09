import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AttendancePredictor extends StatefulWidget {
  final List<Map<String, dynamic>> courses;
  
  const AttendancePredictor({
    super.key,
    required this.courses,
  });

  @override
  State<AttendancePredictor> createState() => _AttendancePredictorState();
}

class _AttendancePredictorState extends State<AttendancePredictor> {
  static const Color _pitchBlack = Color(0xFF000000);
  static const Color _neonPink = Color(0xFFFF00FF);
  static const Color _white = Colors.white;

  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, Map<String, dynamic>> _calendarData = {};
  Map<String, dynamic>? _batchTimetable;
  String _studentBatch = '1';
  int _currentDayOrder = 1; // Current day order from storage
  List<Map<String, dynamic>> _predictions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCalendarData();
    await _loadTimetableData();
  }

  Future<void> _loadCalendarData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarJson = prefs.getString('calendarData');
      
      if (calendarJson != null && calendarJson.isNotEmpty) {
        final decoded = json.decode(calendarJson);
        setState(() {
          _calendarData = Map<String, Map<String, dynamic>>.from(
            decoded.map((key, value) => MapEntry(
              key.toString(),
              Map<String, dynamic>.from(value as Map),
            )),
          );
        });
      }
    } catch (e) {
      print('Error loading calendar data: $e');
    }
  }

  Future<void> _loadTimetableData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) return;
      
      final raw = prefs.getString('userData');
      if (raw == null || raw.isEmpty) return;
      
      final Map<String, dynamic> data = json.decode(raw);
      final studentBatch = data['timetable']?['student_info']?['batch'] ?? '1';
      
      final Map<String, dynamic> fullBatchTimetable = _hardcodedBatchTimetable();
      final batchKey = 'Batch$studentBatch';
      
      if (fullBatchTimetable.containsKey(batchKey)) {
        setState(() {
          _studentBatch = studentBatch;
          _batchTimetable = fullBatchTimetable[batchKey];
        });
      }
    } catch (e) {
      print('Error loading timetable data: $e');
    }
  }

  Map<String, dynamic> _hardcodedBatchTimetable() {
    return {
      "Batch1": {
        "schedule": {
          "Day 1": ["A", "A / X", "F / X", "F", "G", "P6", "P7", "P8", "P9", "P10", "L11", "L12"],
          "Day 2": ["P11", "P12/X", "P13/X", "P14", "P15", "B", "B", "G", "G", "A", "L21", "L22"],
          "Day 3": ["C", "C / X", "A / X", "D", "B", "P26", "P27", "P28", "P29", "P30", "L31", "L32"],
          "Day 4": ["P31", "P32/X", "P33/X", "P34", "P35", "D", "D", "B", "E", "C", "L41", "L42"],
          "Day 5": ["E", "E / X", "C / X", "F", "D", "P46", "P47", "P48", "P49", "P50", "L51", "L52"]
        }
      },
      "Batch2": {
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

  List<int> _getDayOrdersInRange(DateTime start, DateTime end) {
    List<int> dayOrders = [];
    DateTime current = start;
    int currentDayOrder = 1; // Start with Day 1
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Skip weekends
      if (current.weekday >= 6) {
        current = current.add(const Duration(days: 1));
        continue;
      }
      
      // Check if it's a holiday
      String dateKey = '${current.day}_${current.month}_${current.year}';
      bool isHoliday = false;
      
      if (_calendarData.containsKey(dateKey)) {
        final events = _calendarData[dateKey]?['event'] as List?;
        if (events != null) {
          for (var event in events) {
            if (event['type'] == 'holiday') {
              isHoliday = true;
              break;
            }
          }
        }
      }
      
      if (!isHoliday) {
        dayOrders.add(currentDayOrder);
        currentDayOrder = (currentDayOrder % 5) + 1; // Cycle through 1-5
      }
      
      current = current.add(const Duration(days: 1));
    }
    
    return dayOrders;
  }

  int _countClassesForCourse(List<int> dayOrders, String courseSlot) {
    if (_batchTimetable == null) return dayOrders.length;
    
    int classCount = 0;
    final schedule = _batchTimetable!['schedule'];
    
    for (int dayOrder in dayOrders) {
      final dayLabel = 'Day $dayOrder';
      if (schedule[dayLabel] != null) {
        final slots = List<String>.from(schedule[dayLabel]);
        
        // Check if course slot appears in this day's schedule
        for (String slot in slots) {
          if (_slotMatches(slot, courseSlot)) {
            classCount++;
            break; // Count once per day even if multiple slots
          }
        }
      }
    }
    
    return classCount;
  }

  bool _slotMatches(String scheduleSlot, String courseSlot) {
    // Handle multi-slot ranges like L41-L42
    if (courseSlot.contains('-')) {
      final parts = courseSlot.split('-');
      for (var part in parts) {
        if (part.trim().isEmpty) continue;
        if (scheduleSlot.contains(part.trim())) {
          return true;
        }
      }
    } else {
      if (scheduleSlot.contains(courseSlot)) {
        return true;
      }
    }
    return false;
  }

  void _calculatePredictions() {
    if (_startDate == null || _endDate == null) return;
    
    setState(() => _loading = true);
    
    // Get day orders in the date range
    final dayOrders = _getDayOrdersInRange(_startDate!, _endDate!);
    
    List<Map<String, dynamic>> predictions = [];
    
    for (var course in widget.courses) {
      final int currentConducted = course['conducted'] ?? 0;
      final int currentAbsent = course['absent'] ?? 0;
      final int currentPresent = currentConducted - currentAbsent;
      final double currentPercentage = course['percentage'] ?? 0.0;
      final String courseSlot = course['slot'] ?? '';
      
      // Count actual classes for this course in the date range
      final int additionalClasses = _countClassesForCourse(dayOrders, courseSlot);
      
      // Predict new values (assuming student misses all these classes)
      final int predictedConducted = currentConducted + additionalClasses;
      final int predictedAbsent = currentAbsent + additionalClasses;
      final double predictedPercentage = predictedConducted > 0
          ? (currentPresent / predictedConducted) * 100
          : 0.0;
      
      final double percentageDrop = currentPercentage - predictedPercentage;
      
      predictions.add({
        'title': course['title'],
        'currentPercentage': currentPercentage,
        'predictedPercentage': predictedPercentage,
        'percentageDrop': percentageDrop,
        'additionalClasses': additionalClasses,
        'currentConducted': currentConducted,
        'predictedConducted': predictedConducted,
        'dayOrders': dayOrders.length,
      });
    }
    
    setState(() {
      _predictions = predictions;
      _loading = false;
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _neonPink,
              surface: _pitchBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
        _predictions.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pitchBlack,
      appBar: AppBar(
        title: const Text(
          'Predict Attendance',
          style: TextStyle(fontWeight: FontWeight.w600, color: _white),
        ),
        backgroundColor: _pitchBlack,
        foregroundColor: _neonPink,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateSelector(),
            const SizedBox(height: 20),
            if (_startDate != null && _endDate != null) ...[
              _buildCalculateButton(),
              const SizedBox(height: 20),
            ],
            if (_loading)
              const Center(child: CircularProgressIndicator(color: _neonPink))
            else if (_predictions.isNotEmpty)
              _buildPredictionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _neonPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neonPink.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          _buildDateButton(
            label: 'Start Date',
            date: _startDate,
            onTap: () => _selectDate(true),
            dateFormat: dateFormat,
          ),
          const SizedBox(height: 16),
          _buildDateButton(
            label: 'End Date',
            date: _endDate,
            onTap: () => _selectDate(false),
            dateFormat: dateFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pitchBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _neonPink.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null ? dateFormat.format(date) : 'Select Date',
                  style: const TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(Icons.calendar_today, color: _neonPink, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _calculatePredictions,
      style: ElevatedButton.styleFrom(
        backgroundColor: _neonPink,
        foregroundColor: _pitchBlack,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Calculate Predictions',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPredictionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Predicted Attendance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _white,
          ),
        ),
        const SizedBox(height: 12),
        ..._predictions.map((prediction) => _buildPredictionCard(prediction)),
      ],
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final double percentageDrop = prediction['percentageDrop'];
    final int additionalClasses = prediction['additionalClasses'];
    final Color dropColor = percentageDrop > 0 ? Colors.redAccent : Colors.greenAccent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pitchBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neonPink.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prediction['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$additionalClasses class${additionalClasses != 1 ? 'es' : ''} in selected period',
            style: TextStyle(
              fontSize: 12,
              color: _white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                'Current',
                '${prediction['currentPercentage'].toStringAsFixed(1)}%',
                _white,
              ),
              Icon(Icons.arrow_forward, color: _neonPink, size: 20),
              _buildStatColumn(
                'Predicted',
                '${prediction['predictedPercentage'].toStringAsFixed(1)}%',
                dropColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dropColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dropColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  percentageDrop > 0 ? Icons.trending_down : Icons.check_circle,
                  color: dropColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    additionalClasses == 0
                        ? 'No classes scheduled'
                        : percentageDrop > 0
                            ? 'Will drop by ${percentageDrop.toStringAsFixed(1)}%'
                            : 'No drop',
                    style: TextStyle(
                      color: dropColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}