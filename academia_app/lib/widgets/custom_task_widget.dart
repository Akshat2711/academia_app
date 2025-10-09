import 'package:flutter/material.dart';

/// A compact card widget to display custom tasks in a list
class CustomTaskCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final DateTime date;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const CustomTaskCard({
    Key? key,
    required this.event,
    required this.date,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  // Helper to determine the priority color
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'mid':
        return Colors.amberAccent;
      case 'low':
        return Colors.lightGreenAccent;
      default:
        return Colors.grey;
    }
  }

  // Helper to check if the task's full date and time have passed
  bool _isTaskPassed(DateTime taskDate, String timeString) {
    // If no time provided → just check if the date is today or earlier
    // If the date is earlier than today, it has passed.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final comparisonDate = DateTime(taskDate.year, taskDate.month, taskDate.day);

    if (comparisonDate.isBefore(today)) {
      return true;
    }
    
    // If it's today or in the future, time parsing is necessary
    if (timeString.isEmpty) {
      // If date is today and no time is set, assume it hasn't fully passed yet 
      // (or treat as an all-day event). We only mark it as passed if the date itself is past.
      return comparisonDate.isBefore(today); 
    }

    try {
      int hour = 0;
      int minute = 0;

      // Handle common 12-hour and 24-hour formats (e.g., "10:00 AM" or "14:30")
      final parts = timeString.trim().split(RegExp(r'\s+'));
      final timeParts = parts[0].split(':');
      hour = int.tryParse(timeParts[0]) ?? 0;
      minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

      if (parts.length == 2) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }

      // Combine date + time
      final taskDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        hour,
        minute,
      );

      // Compare full timestamp (date + time)
      return taskDateTime.isBefore(now);
    } catch (e) {
      // Fallback if parsing fails — check only the date
      return comparisonDate.isBefore(today);
    }
  }


  @override
  Widget build(BuildContext context) {
    final priority = (event['priority'] ?? 'mid').toString().toLowerCase();
    final timeString = event['time'] ?? '';

    // Determine the actual date of the task. 
    // It starts with the date passed to the widget, but can be overwritten if 
    // the event map contains a specific 'date' field (e.g., for multi-day views).
    DateTime taskDate = date; 
    if (event['date'] != null && event['date'] is String) {
      try {
        // Assume ISO format first (YYYY-MM-DD)
        taskDate = DateTime.parse(event['date']);
      } catch (_) {
        // Fallback for "DD_MM_YYYY" or similar formats
        final parts = event['date'].toString().split(RegExp(r'[_-]'));
        if (parts.length == 3) {
          try {
            taskDate = DateTime(
              int.parse(parts[2]), // Year
              int.parse(parts[1]), // Month
              int.parse(parts[0]), // Day
            );
          } catch (_) {
            // Ignore if custom parsing fails
          }
        }
      }
    }

    final isPassed = _isTaskPassed(taskDate, timeString);
    
    // --- Dynamic Theming based on Passed State ---
    const activeColor = Color(0xFF1E1E1E); // Default dark background
    const passedColor = Color.fromARGB(255, 230, 230, 230); // Light background for passed tasks

    final containerColor = isPassed ? passedColor : activeColor;
    final titleTextColor = isPassed ? Colors.black87 : Colors.white;
    final descTextColor = isPassed ? Colors.black54 : Colors.white70;
    
    // Colors for the Date/Time badge
    final badgeBgColor = isPassed 
      ? const Color.fromARGB(255, 204, 204, 204) 
      : const Color.fromARGB(255, 39, 39, 39); 
    final badgeTextColor = isPassed ? Colors.black87 : Colors.white;
    final badgeIconColor = isPassed ? Colors.black54 : Colors.white70;


    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isPassed
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Priority color bar
          Container(
            width: 5,
            height: 60,
            decoration: BoxDecoration(
              color: _getPriorityColor(priority),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Title and description (Expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title 
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event['title'] ?? 'Untitled Task',
                        style: TextStyle(
                          color: titleTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isPassed ? TextDecoration.lineThrough : null,
                          decorationColor: titleTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  event['desc'] ?? 'No description.',
                  style: TextStyle(
                    color: descTextColor,
                    fontSize: 13,
                    fontStyle: isPassed ? FontStyle.italic : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 3. Date & Time Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: badgeIconColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${taskDate.day}/${taskDate.month}/${taskDate.year}',
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell icon - positioned top right
                  if (!isPassed && event['notification'] == 'yes')
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 203, 210, 215),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Color.fromARGB(255, 57, 54, 54),
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              // Time display
              if (timeString.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: badgeIconColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        timeString,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // 4. Action Buttons (Edit/Delete)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edit Button
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(10),
                  child: Container( 
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: isPassed ? Colors.grey[300] : const Color.fromARGB(255, 60, 60, 60),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, size: 17, color: isPassed ? Colors.black54 : const Color.fromARGB(255, 226, 224, 224)),
                  ),
                ),
              const SizedBox(height: 4),
              // Delete Button
              if (onDelete != null)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: Container( // Changed Padding to Container
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration( // Added circular decoration
                      color: isPassed ? Colors.grey[300] : const Color.fromARGB(255, 234, 98, 98),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete, size: 17, color: isPassed ? Colors.red[300] : const Color.fromARGB(255, 62, 60, 60)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}