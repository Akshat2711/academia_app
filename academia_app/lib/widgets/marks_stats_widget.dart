import 'package:flutter/material.dart';
// Screens
import 'package:academia_app/screens/cgpa_calculator.dart';

//FOR IOS LIKE TRANSITION
import 'package:flutter/cupertino.dart'; 

// ============================================================================
// MARKS STATISTICS WIDGET - Overall performance summary
// ============================================================================
class MarksStatsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> marks;
  final Map<String, int>? courseCredits; // Map of course code to credits

  const MarksStatsWidget({
    super.key,
    required this.marks,
    this.courseCredits,
  });

  // Color palette matching the marks screen
  static const Color _pitchBlack = Color(0xFF000000);
  static const Color _neonGreen = Color.fromARGB(255, 31, 131, 13);
  static const Color _white = Colors.white;
  

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        // 👇 NEW: Solid Neon Green Background
        color: const Color.fromARGB(255, 75, 162, 59), 
        borderRadius: BorderRadius.circular(20),
        // Shadows REMOVED
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.analytics_rounded, color: _white, size: 28), // White icon
                const SizedBox(width: 12),
                Text(
                  'Performance Overview',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _white, // White text
                    // Shadows REMOVED
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Grid
            Row(
              children: [
                // Overall Marks
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.auto_graph_rounded,
                    label: 'Total Score',
                    value: '${stats['obtainedMarks'].toStringAsFixed(1)}',
                    subValue: '/ ${stats['maxMarks'].toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 12),
                // Percentage
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.percent_rounded,
                    label: 'Percentage',
                    value: '${stats['percentage'].toStringAsFixed(1)}%',
                    subValue: '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Expected CGPA
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.school_rounded,
                    label: 'Est. CGPA',
                    value: stats['cgpa'].toStringAsFixed(2),
                    subValue: '/ 10.0',
                  ),
                ),
                const SizedBox(width: 12),
                // Grade
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.grade_rounded,
                    label: 'Grade',
                    value: stats['grade'],
                    subValue: '',
                  ),
                ),
              ],
            ),

            // Note
            if (stats['totalTests'] > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Slightly transparent White for the note background
                  color: _white.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(12),
                  // Border REMOVED
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: _white), // White icon
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Based on ${stats['totalTests']} test(s) across ${stats['totalCourses']} course(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _pitchBlack.withOpacity(0.8), // Dark text on bright background for readability
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // CGPA Calculator Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                   Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const CGPACalculator()),
                );
                },
                icon: const Icon(Icons.calculate_rounded, size: 20),
                label: const Text(
                  'Open Calculator',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 171, 245, 166).withOpacity(0.1),
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Stat card background is a lighter shade of green or transparent
        color: const Color.fromARGB(255, 171, 245, 166).withOpacity(0.1), 
        borderRadius: BorderRadius.circular(16),
        // Shadows REMOVED
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _white, size: 20), // White icon
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _white.withOpacity(0.8), // Lighter label
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _white, // Main value in White
                  // Shadows REMOVED
                ),
              ),
              if (subValue.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    subValue,
                    style: TextStyle(
                      fontSize: 13,
                      color: _white.withOpacity(0.7), // Lighter sub-text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Calculation Methods ---

  Map<String, dynamic> _calculateStats() {
    double totalObtained = 0;
    double totalMax = 0;
    int totalTests = 0;
    double weightedGradePoints = 0;
    double totalCredits = 0;

    for (final course in marks) {
      final tests = course['tests'] as List<Map<String, dynamic>>;
      
      if (tests.isEmpty) continue;

      // Calculate course total (sum of all tests in the course)
      double courseObtained = 0;
      double courseMax = 0;
      
      for (final test in tests) {
        final obtained = (test['obtained'] as num).toDouble();
        final max = (test['max'] as num).toInt();
        courseObtained += obtained;
        courseMax += max;
        totalTests++;
      }

      totalObtained += courseObtained;
      totalMax += courseMax;

      // Calculate grade points for this course based on marks cut
      if (courseMax > 0) {
        final marksCut = courseMax - courseObtained;
        final gradePoint = _marksCutToGradePoint(marksCut);
        
        // Try to get credits for this course
        int credits = 3; // Default credits
        if (courseCredits != null) {
          final courseTitle = course['title'] as String;
          credits = courseCredits![courseTitle] ?? 3;
        }
        
        weightedGradePoints += gradePoint * credits;
        totalCredits += credits;
      }
    }

    final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
    final cgpa = totalCredits > 0 ? weightedGradePoints / totalCredits : 0.0;
    final grade = _percentageToGrade(percentage);

    return {
      'obtainedMarks': totalObtained,
      'maxMarks': totalMax,
      'percentage': percentage,
      'cgpa': cgpa,
      'grade': grade,
      'totalTests': totalTests,
      'totalCourses': marks.length,
    };
  }

  // New method: Calculate grade point based on marks cut in a subject
  double _marksCutToGradePoint(double marksCut) {
    if (marksCut < 10) return 10.0;  // O grade if less than 10 marks cut
    if (marksCut < 20) return 9.0;   // A+ if 10-19 marks cut
    if (marksCut < 30) return 8.0;   // A if 20-29 marks cut
    if (marksCut < 40) return 7.0;   // B+ if 30-39 marks cut
    if (marksCut < 45) return 6.0;   // B if 40-44 marks cut
    if (marksCut < 50) return 5.0;   // C if 45-49 marks cut
    return 0.0;                       // F if 50+ marks cut
  }

  String _percentageToGrade(double percentage) {
    if (percentage >= 90) return 'O';
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B+';
    if (percentage >= 55) return 'B';
    if (percentage >= 50) return 'C';
    return 'F';
  }
}