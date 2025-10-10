import 'package:flutter/material.dart';
import '../services/timetable_service.dart';
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

  bool _loading = true;
  late PageController _pageController;
  final TimetableService _timetableService = TimetableService();

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  @override
  void dispose() {
    // Check if _pageController has been initialized before disposing
    if (mounted && _timetableService.batchTimetable != null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTimetable() async {
    setState(() => _loading = true);
    
    final success = await _timetableService.loadTimetable();
    
    if (success && _timetableService.batchTimetable != null) {
      // Initialize page controller to start at current day or first day if invalid
      final currentDay = _timetableService.currentDayOrder;
      final initialPage = (currentDay >= 1 && currentDay <= 5) ? currentDay - 1 : 0;
      _pageController = PageController(initialPage: initialPage);
    }
    
    setState(() => _loading = false);
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
                          // Optional: track which page user is viewing
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