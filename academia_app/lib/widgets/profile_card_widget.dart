import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

// IMPORTANT: Import your announcement service
// Update this path to match your project structure
import '../services/announcement_data.dart';

class SlidingProfileAnnouncementWidget extends StatefulWidget {
  final String name;
  final String regno;
  final String program;
  final String specialization;
  final String semester;

  const SlidingProfileAnnouncementWidget({
    super.key,
    required this.name,
    required this.regno,
    required this.program,
    required this.specialization,
    required this.semester,
  });

  @override
  State<SlidingProfileAnnouncementWidget> createState() =>
      _SlidingProfileAnnouncementWidgetState();
}

class _SlidingProfileAnnouncementWidgetState
    extends State<SlidingProfileAnnouncementWidget> {
  final PageController _pageController = PageController();
  Timer? _timer;
  Map<String, dynamic>? _announcementsData;
  bool _isLoading = true;
  int _currentAnnouncementIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    // Delay loading announcements to ensure Firebase is initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadAnnouncements();
      }
    });
  }

  Future<void> _loadAnnouncements() async {
    try {
      print('🔍 Starting to load announcements...');
      final data = await getEventsData();
      print('📦 Received data: ${data.length} announcements');
      print('📋 Data keys: ${data.keys.toList()}');
      
      if (mounted) {
        setState(() {
          _announcementsData = data;
          _isLoading = false;
        });
      }
      
      if (data.isEmpty) {
        print('⚠️ Warning: Data is empty!');
      } else {
        print('✅ Successfully loaded ${data.length} announcements');
      }
    } catch (e) {
      print('❌ Error loading announcements: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function to launch URLs
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, //Force open in browser
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link')),
        );
      }
      print('Could not launch $url');
    }
  }


  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_pageController.hasClients) {
        final currentPage = _pageController.page?.round() ?? 0;
        
        if (currentPage == 0) {
          // Move to announcement page
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else {
          // On announcement page, either cycle through announcements or go back to profile
          final announcements = _announcementsData?.entries.toList() ?? [];
          if (announcements.isNotEmpty) {
            setState(() {
              _currentAnnouncementIndex = 
                  (_currentAnnouncementIndex + 1) % announcements.length;
            });
            
            // Every 3rd cycle, go back to profile
            if (_currentAnnouncementIndex == 0) {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          } else {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    });
  }

  void _pauseAutoSlide() {
    _timer?.cancel();
  }

  void _resumeAutoSlide() {
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // Reset timer when user manually swipes
          _pauseAutoSlide();
          _resumeAutoSlide();
        },
        children: [
          _buildProfileCard(),
          _buildAnnouncementCard(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9900), Color(0xFFFF6F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6F00).withOpacity(0.3),
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
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.regno,
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
            _buildInfoRow(Icons.school, widget.program),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.analytics, widget.specialization),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.book, 'Semester ${widget.semester}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final announcements = _announcementsData?.entries.toList() ?? [];
    
    if (announcements.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No announcements available',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final announcement = announcements[_currentAnnouncementIndex].value;
    final String? title = announcement['title'];
    final String? para = announcement['para'];
    final String? img = announcement['img'];
    final String? link = announcement['link'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Gradient
            if (img != null && img.isNotEmpty)
              Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            
            // Dark Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.campaign,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Announcement',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Paragraph
                  if (para != null)
                    Text(
                      para,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Link button in bottom right
                  if (link != null && link.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          print('🔗 Opening link: $link');
                          _launchUrl(link);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Check Out',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}