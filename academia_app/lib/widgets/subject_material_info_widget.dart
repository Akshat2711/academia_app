import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectEntry {
  final String sem;
  final String id;
  final String displayName;
  final Map<String, dynamic> data;

  SubjectEntry({
    required this.sem,
    required this.id,
    required this.displayName,
    required this.data,
  });
}

class SubjectMaterialsScreen extends StatelessWidget {
  final SubjectEntry entry;
  const SubjectMaterialsScreen({super.key, required this.entry});

  // Display order + key variants
  static const List<List<String>> fieldVariants = [
    ['Syllabus', 'syllabus', 'syllabi'],
    ['PPTs', 'ppt', 'ppts', 'presentation', 'ppt_links'],
    ['PYQs', 'pyq', 'pyqs', 'previous_year_questions', 'pyq_links'],
    ['Playlist', 'playlist', 'playlistlink', 'playlist_link', 'youtube_playlist', 'full playlist'],
  ];

  // Icon mapping for visual categories
  static const Map<String, IconData> _iconMap = {
    'Subject': Icons.book,
    'Semester': Icons.calendar_month,
    'Syllabus': Icons.menu_book,
    'PPTs': Icons.slideshow,
    'PYQs': Icons.question_answer,
    'Playlist': Icons.play_circle_filled_rounded,
  };

  // Base Colors
  static const Color bg = Colors.black;
  static const Color cardBg = Color(0xFF111111);
  static const Color textMuted = Colors.white70;
  
  // Fixed color for Playlist
  static const Color playlistRed = Color(0xFFFF1744); 

  // --- HELPER: Get Dynamic Color based on Semester ---
  Color _getSemColor(String sem) {
    final s = sem.toLowerCase().replaceAll(' ', '');
    if (s.contains('sem1')) return const Color(0xFFFF5252); // Red Accent
    if (s.contains('sem2')) return const Color(0xFF448AFF); // Blue Accent
    if (s.contains('sem3')) return const Color(0xFFE040FB); // Purple Accent
    if (s.contains('sem4')) return const Color(0xFF69F0AE); // Green Accent
    if (s.contains('sem5')) return const Color(0xFFFFAB40); // Orange Accent
    if (s.contains('sem6')) return const Color(0xFFFF4081); // Pink Accent
    if (s.contains('sem7')) return const Color(0xFF18FFFF); // Cyan Accent
    if (s.contains('sem8')) return const Color(0xFF536DFE); // Indigo Accent
    return const Color(0xFF00C853); // Default Green
  }

  Future<void> _openLink(BuildContext ctx, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  void _copyLink(BuildContext ctx, String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> doc = entry.data;
    
    // 1. Determine the Global Theme Color for this specific subject/semester
    final Color semThemeColor = _getSemColor(entry.sem);

    final Map<String, String> lowerKeyMap = {for (final k in doc.keys) k.toLowerCase(): k};

    final List<MapEntry<String, dynamic>> rows = [];
    for (final variant in fieldVariants) {
      final displayLabel = variant[0];
      final possibleKeys = variant.sublist(1).map((s) => s.toLowerCase()).toList();
      String? matched;
      for (final pk in possibleKeys) {
        if (lowerKeyMap.containsKey(pk)) {
          matched = lowerKeyMap[pk];
          break;
        }
      }
      if (matched != null) {
        final value = doc[matched];
        // Filter out empty values
        if (value != null && value.toString().isNotEmpty) {
           if (value is List && value.isEmpty) continue;
           rows.add(MapEntry(displayLabel, value));
        }
      }
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          entry.displayName,
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: rows.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_off_outlined, color: Colors.white12, size: 64),
                  const SizedBox(height: 16),
                  Text('No materials available', style: TextStyle(color: textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final label = rows[i].key;
                final value = rows[i].value;
                final bool isPlaylist = label.toLowerCase() == 'playlist';

                // 2. Logic: If it's a playlist, use Red. Otherwise, use the Semester Color.
                final Color sectionColor = isPlaylist ? playlistRed : semThemeColor;

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                
              
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER ROW ---
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: sectionColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _iconMap[label] ?? Icons.folder,
                                color: const Color.fromARGB(255, 228, 221, 221),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              label.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // --- CONTENT ---
                        // We pass the sectionColor down so links match the header
                        _buildValueWidget(context, value, sectionColor),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

Widget _buildValueWidget(BuildContext ctx, dynamic value, Color accentColor) {
    
    // Helper to build a clickable link row
    Widget buildLinkRow(String title, String link) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () => _openLink(ctx, link),
          borderRadius: BorderRadius.circular(12), // Slightly more rounded
          child: Container(
            padding: const EdgeInsets.all(12), // Increased padding slightly
            decoration: BoxDecoration(
              // CHANGE 1: BG is now the section color (accentColor) with opacity
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              // Optional: Add a subtle border to make the color pop nicely
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                // Icon keeps the accent color to maintain the theme, or use White if you prefer
                Icon(Icons.link, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      // CHANGE 2: Text is now White
                      color: Colors.white, 
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  // Copy icon is white to match text
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                  onPressed: () => _copyLink(ctx, link),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Handle Lists
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.map<Widget>((item) {
          if (item is Map) {
            final title = (item['title'] ?? item['name'] ?? item['label'] ?? '').toString();
            final link = (item['link'] ?? item['url'] ?? item['href'] ?? '').toString();
            if (link.isNotEmpty) {
              return buildLinkRow(title.isNotEmpty ? title : "View Resource", link);
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Colors.white38)),
                    Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, height: 1.4))),
                  ],
                ),
              );
            }
          } else {
            final s = item?.toString() ?? '';
            if (s.startsWith('http')) return buildLinkRow(s, s);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text("• $s", style: const TextStyle(color: Colors.white70, height: 1.4)),
            );
          }
        }).toList(),
      );
    }

    // Handle Maps
    if (value is Map) {
      final title = (value['title'] ?? value['name'] ?? '').toString();
      final link = (value['link'] ?? value['url'] ?? '').toString();
      if (link.isNotEmpty) return buildLinkRow(title.isNotEmpty ? title : link, link);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries.map<Widget>((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              children: [
                TextSpan(text: "${e.key}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white38)),
                TextSpan(text: "${e.value}"),
              ]
            ),
          ),
        )).toList(),
      );
    }

    // Handle Strings
    final s = value?.toString() ?? '';
    if (s.startsWith('http')) {
      return buildLinkRow(s, s);
    }

    return Text(
      s, 
      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)
    );
  }
}