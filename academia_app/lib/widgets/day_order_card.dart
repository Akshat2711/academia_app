import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DayOrderCard extends StatefulWidget {
  const DayOrderCard({
    super.key,
    required this.day,
    required this.isCurrentDay,
    required this.classes,
  });

  final int day;
  final bool isCurrentDay;
  final List<Map<String, String>> classes;

  @override
  State<DayOrderCard> createState() => _DayOrderCardState();
}

class _DayOrderCardState extends State<DayOrderCard> {
  static const Color _pitchBlack = Color(0xFF000000);
  static const Color _neonPink = Color(0xFFFF1493);
  static const Color _white = Colors.white;
  static const Color _cardBackground = Color(0xFF1A1A1A);

  Map<String, Map<String, dynamic>> _calendarData = {};

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarJson = prefs.getString('calendar_cache');

      if (calendarJson != null && calendarJson.isNotEmpty) {
        final decoded = json.decode(calendarJson) as Map<String, dynamic>;

        setState(() {
          _calendarData = decoded.map((key, value) => MapEntry(
                key,
                Map<String, dynamic>.from(value as Map),
              ));
        });

        print('📦 Loaded calendar data from SharedPreferences');

        // Check if today is holiday
        final today = DateTime.now();
        final todayKey = "${today.day}_${today.month}_${today.year}";
        if (_isHoliday(todayKey)) {
          print('🎉 Today is a HOLIDAY ($todayKey)!');
        } else {
          print('📅 Today is a regular working day ($todayKey).');
        }
      } else {
        print('⚠️ No cached calendar data in SharedPreferences');
      }
    } catch (e) {
      print('❌ Error loading calendar data from SharedPreferences: $e');
    }
  }

  bool _isHoliday(String dateKey) {
    if (!_calendarData.containsKey(dateKey)) return false;

    final events = _calendarData[dateKey]?['event'] as List?;
    if (events == null) return false;

    for (var event in events) {
      if (event is Map && event['type'] == 'holiday') {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _buildDayCard();
  }

  Widget _buildDayCard() {
    final localClasses = widget.classes;
    final isCurrentDay = widget.isCurrentDay;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isCurrentDay
            ? LinearGradient(
                colors: [_neonPink.withOpacity(0.8), _neonPink.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCurrentDay ? null : _cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isCurrentDay ? _neonPink.withOpacity(0.9) : _white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentDay ? _neonPink.withOpacity(0.4) : _pitchBlack,
            blurRadius: isCurrentDay ? 25 : 0,
            spreadRadius: isCurrentDay ? -5 : 0,
            offset: const Offset(0, 0),
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
                      'Day ${widget.day}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.class_,
                          size: 16,
                          color: isCurrentDay
                              ? _white.withOpacity(0.8)
                              : _neonPink.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${localClasses.length} ${localClasses.length == 1 ? 'Class' : 'Classes'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isCurrentDay
                                ? _white.withOpacity(0.8)
                                : _white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isCurrentDay)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.today, color: _white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'TODAY',
                          style: TextStyle(
                            color: _white,
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
          if (localClasses.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: _neonPink.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No classes scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        color: _white.withOpacity(0.7),
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
                itemCount: localClasses.length,
                itemBuilder: (context, index) {
                  final classInfo = localClasses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrentDay
                          ? _pitchBlack.withOpacity(0.3)
                          : _pitchBlack,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrentDay
                            ? _white.withOpacity(0.3)
                            : _neonPink.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _neonPink.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _neonPink.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                classInfo['slot'] ?? '',
                                style: const TextStyle(
                                  color: _neonPink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: _white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    classInfo['time'] ?? '',
                                    style: const TextStyle(
                                      color: _white,
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
                          classInfo['course'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.room,
                              size: 16,
                              color: _neonPink.withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              classInfo['classroom'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: _white.withOpacity(0.7),
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
}
