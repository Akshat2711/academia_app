// File: calender_widgets.dart
import 'package:flutter/material.dart';

// Type definition for the utility function passed from the main screen
typedef GetEventColor = Color Function(String type);
// Type definition for the function to save the event
typedef SaveEventCallback = void Function(Map<String, dynamic> eventData);

// === New Widget for Creating Events (Bottom Sheet) ===

class CreateEventBottomSheet extends StatefulWidget {
  final SaveEventCallback onSave;
  final bool isEditing;
  final Map<String, dynamic>? initialData;

 const CreateEventBottomSheet({
  Key? key,
  required this.onSave,
  this.isEditing = false,
  this.initialData,
}) : super(key: key);

  @override
  State<CreateEventBottomSheet> createState() => _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState extends State<CreateEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  // Initialize to either initial date or today
  late DateTime _selectedDate; 
  late TimeOfDay _selectedTime;
  String _title = '';
  String _description = '';
  String _priority = 'mid'; // Default priority
  String _type = 'custom'; // Default type

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialData?['date'] ?? DateTime.now();
    _selectedTime = TimeOfDay.now();

    if (widget.isEditing && widget.initialData != null) {
      _title = widget.initialData!['title'] ?? '';
      _description = widget.initialData!['desc'] ?? '';
      _priority = widget.initialData!['priority'] ?? 'mid';
      
      // Safe parsing for TimeOfDay (Assuming standard TimeOfDay.format(context) output)
      if (widget.initialData!['time'] != null) {
        final timeString = widget.initialData!['time'] as String;
        // This simple check is often sufficient for common TimeOfDay formats like "10:00 AM"
        if (timeString.contains(':')) {
           // We can't reliably parse AM/PM without a dedicated utility, 
           // but we can at least set a default time or keep the one that was set.
           // Since we can't reliably reverse TimeOfDay.format(context) without
           // locale/context knowledge, we'll keep TimeOfDay.now() for simplicity 
           // and rely on the user to re-set it if needed.
        }
      }
    }
  }

  // Function to open date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to open time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final eventData = {
        'type': _type,
        'title': _title.trim(),
        'desc': _description.trim(),
        'priority': _priority,
        'time': _selectedTime.format(context),
        'date': _selectedDate,
      };
      widget.onSave(eventData);
      Navigator.pop(context);
    }
  }

@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(22),
    decoration: const BoxDecoration(
      color: Color.fromARGB(222, 20, 20, 20), // full pitch black background
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              widget.isEditing ? 'Edit Custom Event' : 'Create Custom Event',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 18),

            // Title Field
            _buildTextFormField(
              label: 'Title',
              initialValue: _title,
              validator: (value) =>
                  value!.isEmpty ? 'Title cannot be empty' : null,
              onSaved: (value) => _title = value!,
            ),
            const SizedBox(height: 20),

            // Description Field
            _buildTextFormField(
              label: 'Description',
              maxLines: 3,
              initialValue: _description,
              onSaved: (value) => _description = value!,
            ),
            const SizedBox(height: 26),

            // Date and Time Pickers
            Row(
              children: [
                Expanded(
                  child: _buildPickerButton(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value:
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    onPressed: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildPickerButton(
                    context,
                    icon: Icons.access_time,
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onPressed: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Priority Selector (Circular)
            const Text(
              'Priority:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['low', 'mid', 'high'].map((priority) {
                final isSelected = _priority == priority;
                final color = _getPriorityColor(priority);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _priority = priority;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? color.withOpacity(0.9)
                          : const Color(0xFF1A1A1A),
             
                    ),
                    child: Center(
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // Save / Update Button (flat black)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 90, 167, 244),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                   
                  ),
                ),
                child: Text(
                  widget.isEditing ? 'Update Event' : 'Save Event',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _buildTextFormField({
  required String label,
  int maxLines = 1,
  String? initialValue,
  String? Function(String?)? validator,
  void Function(String?)? onSaved,
}) {
  return TextFormField(
    initialValue: initialValue,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        fillColor: const Color(0xFF2A2A2A),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      maxLines: maxLines,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildPickerButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required VoidCallback onPressed,
      }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color.fromARGB(255, 242, 150, 144);
      case 'mid':
        return const Color.fromARGB(255, 255, 229, 152);
      case 'low':
        return const Color.fromARGB(255, 169, 245, 171);
      default:
        return Colors.grey;
    }
  }
}

// === Existing Widgets (DateCellWidget, EventItemWidget, LegendItemWidget) ===

/// A widget representing a single day cell in the calendar grid.
class DateCellWidget extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasEvents;
  final List<dynamic>? events;
  final GetEventColor getEventColor;

  const DateCellWidget({
    Key? key,
    required this.day,
    required this.isToday,
    required this.hasEvents,
    required this.events,
    required this.getEventColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!hasEvents && !isToday) {
      return Center(
        child: Text(
          '$day',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    // Get unique event types
    final eventTypes = hasEvents 
        ? events!.map((e) => e['type'] as String).toSet().toList()
        : <String>[];

    final mainColor = hasEvents ? getEventColor(eventTypes[0]) : Colors.white;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Main circle background
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hasEvents ? mainColor.withOpacity(0.2) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday ? Colors.white : (hasEvents ? mainColor : Colors.transparent),
              width: isToday ? 2.5 : (hasEvents ? 2 : 0),
            ),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: (hasEvents || isToday) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        // Multiple event indicators (subscript circles)
        if (hasEvents && eventTypes.length > 1)
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: eventTypes.skip(1).take(2).map((type) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: getEventColor(type),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// A widget to display the details of a single event in the bottom sheet.
class EventItemWidget extends StatelessWidget {
  final Map<String, dynamic> event;
  final GetEventColor getEventColor;

  const EventItemWidget({
    Key? key,
    required this.event,
    required this.getEventColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = getEventColor(event['type'] == 'custom' ? 'custom' : event['type']);
    final hasImage = event['img_link'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                event['img_link'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 150,
                  color: const Color(0xFF3A3A3A),
                  child: const Icon(Icons.image, color: Colors.white54, size: 50),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (event['type'] as String).toUpperCase() + 
                            (event['priority'] != null ? ' (${event['priority'].toUpperCase()})' : ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (event['time'] != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        event['time'],
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (event['title'] != null)
                  Text(
                    event['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  event['desc'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small widget for the color legend at the bottom of the screen.
class LegendItemWidget extends StatelessWidget {
  final String label;
  final Color color;

  const LegendItemWidget({
    Key? key,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Ensure it doesn't take full width
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
  
}


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

  @override
  Widget build(BuildContext context) {
    final priority = (event['priority'] ?? 'mid').toString().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Priority color bar
          Container(
            width: 5,
            height: 60,
            decoration: BoxDecoration(
              color: _getPriorityColor(priority),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),

          // Title and description
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event['desc'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Date + Time neatly stacked
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 220, 219, 219),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.black87, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        color: Color.fromARGB(221, 70, 70, 70),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (event['time'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white54, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      event['time'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Edit + Delete side by side
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 237, 239, 241).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.edit, color: Color.fromARGB(255, 255, 255, 255), size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
