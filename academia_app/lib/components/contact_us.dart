import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  static const Color _primaryColor = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return _buildContactSupport(context);
  }

  Widget _buildContactSupport(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),

          // Contact button
          InkWell(
            onTap: () {
              _launchUrl('https://console-x-academia.vercel.app/contactus');
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent_rounded, color: _primaryColor, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'HAVE QUERIES? CONTACT US',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Version
          Text(
            'Version 1.28.26 • Built by Team Console',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, //Force open in browser
    )) {

      print('Could not launch $url');
    }
  }
}
