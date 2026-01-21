import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// --- SHARED DESIGN CONSTANTS ---
const Color kPitchBlack = Color(0xFF000000);
const Color kCardBlack = Color(0xFF111111);
const Color kAccentOrange = Color(0xFFFF9800);
const Color kSurfaceGrey = Color(0xFF1E1E1E);
const Color kMutedText = Colors.white54;

class FacultyInfo extends StatelessWidget {
  final Map<String, dynamic>? advisors;

  const FacultyInfo({super.key, this.advisors});

  // --- FUNCTIONAL LOGIC ---

  Future<void> _makeCall(String phoneNumber) async {
    // Strips spaces and special characters for the dialer
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri uri = Uri.parse('tel:$cleanPhone');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fa = advisors?['faculty_advisor'];
    final aa = advisors?['academic_advisor'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            ' Advisors',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        _buildAdvisorCard(
          role: 'Faculty Advisor',
          name: fa?['name'] ?? 'Not Assigned',
          email: fa?['email'] ?? 'No email provided',
          phone: fa?['phone'] ?? 'No phone provided',
        ),
        const SizedBox(height: 12),
        _buildAdvisorCard(
          role: 'Academic Advisor',
          name: aa?['name'] ?? 'Not Assigned',
          email: aa?['email'] ?? 'No email provided',
          phone: aa?['phone'] ?? 'No phone provided',
        ),
      ],
    );
  }

  // --- SUBTLE UI COMPONENTS ---

  Widget _buildAdvisorCard({
    required String role,
    required String name,
    required String email,
    required String phone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role Label
          Text(
            role.toUpperCase(),
            style: const TextStyle(
              color: kAccentOrange, 
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 17, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 16),
          
          // Static Info Rows (Visible but not clickable)
          _buildInfoRow(Icons.alternate_email_rounded, email),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone_iphone_rounded, phone),
          
          const SizedBox(height: 20),
          
          // Action Button (Only Call)
          if (phone != 'No phone provided' && phone.isNotEmpty)
            _buildCallButton(onTap: () => _makeCall(phone)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70, 
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kSurfaceGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_in_talk_rounded, color: kAccentOrange, size: 16),
              const SizedBox(width: 10),
              Text(
                'Call Advisor',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}