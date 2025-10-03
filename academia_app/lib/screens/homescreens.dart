import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';


// ============================================================================
// HOME SCREEN - Student profile and overview
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? studentInfo;
  double _overallAttendance = 0.0;
  int _courseCount = 0;
  int _totalCredits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('userData');
      if (dataString != null) {
        final parsedData = jsonDecode(dataString);

        final student = (parsedData['attendance'] is Map && parsedData['attendance']['student_info'] != null)
            ? Map<String, dynamic>.from(parsedData['attendance']['student_info'])
            : null;

        // overall attendance located at attendance -> attendance -> overall_attendance
        double overall = 0.0;
        try {
          final attendanceRoot = parsedData['attendance'];
          if (attendanceRoot != null && attendanceRoot['attendance'] != null) {
            final oa = attendanceRoot['attendance']['overall_attendance'];
            if (oa is num) overall = oa.toDouble();
            final courses = attendanceRoot['attendance']['courses'];
            if (courses is Map) _courseCount = courses.length;
          }
        } catch (_) {}

        // total credits from timetable if available
        try {
          final tt = parsedData['timetable'];
          if (tt != null && tt['total_credits'] != null) {
            final tc = tt['total_credits'];
            if (tc is num) _totalCredits = tc.toInt();
          } else if (tt != null && tt['courses'] is List) {
            // compute credits sum if total_credits not present
            int sum = 0;
            for (final e in tt['courses']) {
              if (e is Map && e['credit'] is num) sum += (e['credit'] as num).toInt();
            }
            if (sum > 0) _totalCredits = sum;
          }
        } catch (_) {}

        setState(() {
          studentInfo = student;
          _overallAttendance = overall;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = studentInfo?['name'] ?? 'AKSHAT SRIVASTAVA';
    final regno = studentInfo?['registration_number'] ?? 'RA2311056010161';
    final program = studentInfo?['program'] ?? 'B.Tech - Computer Science';
    final specialization = studentInfo?['specialization'] ?? 'CS Data Science';
    final semester = studentInfo?['semester'] ?? '5';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            title: const Text('Academia', style: TextStyle(fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
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
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
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
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
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
        Icon(icon, color: Colors.white70, size: 18),
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
          Expanded(child: _buildStatCard(attendance.toStringAsFixed(2), 'Attendance', Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(courses, 'Courses', Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(credits, 'Credits', Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(Icons.assignment, 'View Assignments', Colors.purple),
        const SizedBox(height: 8),
        _buildActionButton(Icons.payment, 'Fee Payment', Colors.teal),
        const SizedBox(height: 8),
        _buildActionButton(Icons.library_books, 'Library', Colors.indigo),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

}