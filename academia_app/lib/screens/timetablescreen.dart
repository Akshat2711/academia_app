// File: timetable_screen.dart
import 'package:flutter/material.dart';
import '../services/timetable_service.dart';
import '../widgets/day_order_card.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// TIMETABLE SCREEN - Modern card-based timetable with horizontal scrolling
// ============================================================================
class TimetableScreen extends StatefulWidget {
  final int? view_dayorder;

  const TimetableScreen({super.key, this.view_dayorder});
  
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // --- COLOR PALETTE ---
  static const Color _pitchBlack = Color(0xFF000000);
  static const Color _neonPink = Color(0xFFFF1493);
  static const Color _white = Colors.white;
  static const Color _holidayGold = Color.fromARGB(255, 223, 223, 219);
  static const Color _holidayOrange = Color.fromARGB(255, 169, 164, 162);

  bool _loading = true;
  late PageController _pageController; 
  final TimetableService _timetableService = TimetableService();
  
  // Holiday state
  bool _isTodayHoliday = false;
  String _holidayName = '';

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
    setState(() => _loading = true);
    
    final success = await _timetableService.loadTimetable();
    
    if (success && _timetableService.batchTimetable != null) {
      // Check if today is a holiday
      await _checkTodayHoliday();
      
      final int? passedDayOrder = widget.view_dayorder;
      final int currentDay = _timetableService.currentDayOrder;
      
      int targetDay = 1;
      if (passedDayOrder != null && passedDayOrder >= 1 && passedDayOrder <= 5) {
        targetDay = passedDayOrder;
      } else if (currentDay >= 1 && currentDay <= 5) {
        targetDay = currentDay;
      }

      final initialPage = targetDay - 1; 
      _pageController = PageController(initialPage: initialPage);
    }
    
    setState(() => _loading = false);
  }

  Future<void> _checkTodayHoliday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarJson = prefs.getString('calendar_cache');

      if (calendarJson != null && calendarJson.isNotEmpty) {
        final decoded = json.decode(calendarJson) as Map<String, dynamic>;
        final calendarData = decoded.map((key, value) => MapEntry(
          key,
          Map<String, dynamic>.from(value as Map),
        ));

        final today = DateTime.now();
        final todayKey = "${today.day}_${today.month}_${today.year}";

        if (calendarData.containsKey(todayKey)) {
          final events = calendarData[todayKey]?['event'] as List?;
          if (events != null) {
            for (var event in events) {
              if (event is Map && event['type'] == 'holiday') {
                setState(() {
                  _isTodayHoliday = true;
                  _holidayName = event['name'] ?? 'Holiday';
                });
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error checking holiday: $e');
    }
  }

  Widget _buildHolidayBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _holidayOrange.withOpacity(0.9),
            _holidayGold.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _holidayGold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _holidayGold.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.celebration,
                color: _white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _holidayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.celebration,
                color: _white,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available,
                  color: _white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'No Classes Today',
                  style: TextStyle(
                    color: _white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Swipe to view timetable for other days',
            style: TextStyle(
              color: _white.withOpacity(0.9),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pitchBlack,
      appBar: AppBar(
        title: const Text(
          'Timetable',
          style: TextStyle(fontWeight: FontWeight.w600, color: _white),
        ),
        backgroundColor: _pitchBlack,
        foregroundColor: _neonPink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimetable,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _neonPink),
            )
          : _timetableService.batchTimetable == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: _neonPink.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No timetable found',
                        style: TextStyle(
                          fontSize: 18,
                          color: _white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Show holiday banner if today is a holiday
                    if (_isTodayHoliday) _buildHolidayBanner(),
                    
                    // Day indicator dots
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final day = index + 1;
                          final currentDay = _timetableService.currentDayOrder;
                          final isCurrentDay = currentDay == day && 
                                               currentDay >= 1 && 
                                               currentDay <= 5;
                          
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
                                    ? _neonPink
                                    : _white.withOpacity(0.3),
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
                          setState(() {});
                        },
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final currentDay = _timetableService.currentDayOrder;
                          final isCurrentDay = currentDay == day && 
                                               currentDay >= 1 && 
                                               currentDay <= 5;
                          final classes = _timetableService.getClassesForDay(day);
                          
                          return DayOrderCard(
                            day: day,
                            isCurrentDay: isCurrentDay,
                            classes: classes,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}