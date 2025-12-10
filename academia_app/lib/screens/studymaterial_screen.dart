import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for local storage

// service import
import '../services/study_material.dart';

// widgets
import '../widgets/subject_material_info_widget.dart'; // SubjectEntry & SubjectMaterialsScreen

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  bool _loading = true;
  String _query = '';

  Map<String, Map<String, dynamic>> _materials = {};
  List<SubjectEntry> _subjects = [];
  List<SubjectEntry> _filtered = [];

  // Changed to Set for efficient lookups, stored locally
  Set<String> _mySubjectIds = {};

  // Semester selection: null => All, otherwise sem key like 'sem1'
  String? _selectedSem;

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved subjects first
    _load(); // Load API/Service data
  }

  // --- LOCAL STORAGE LOGIC ---
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load list and convert to Set
      final List<String>? saved = prefs.getStringList('my_subjects');
      if (saved != null) {
        _mySubjectIds = saved.toSet();
      }
    });
  }

  Future<void> _toggleMySubject(String id) async {
    setState(() {
      if (_mySubjectIds.contains(id)) {
        _mySubjectIds.remove(id); // Remove if exists (Cross button logic)
      } else {
        _mySubjectIds.add(id); // Add if doesn't exist (Plus button logic)
      }
    });

    // Save to local storage immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('my_subjects', _mySubjectIds.toList());
  }
  // ---------------------------

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await getMaterialsData(); // your service
      _materials = data;
      _subjects = _flatten(data);
      _applyFilter();
    } catch (e) {
      debugPrint('Error loading materials: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<SubjectEntry> _flatten(Map<String, Map<String, dynamic>> map) {
    final list = <SubjectEntry>[];
    map.forEach((sem, subjects) {
      subjects.forEach((id, doc) {
        String display = id;
        final keys = ['Subject', 'subject', 'Title', 'title', 'Name', 'name'];
        for (final k in keys) {
          if (doc[k] != null && doc[k].toString().trim().isNotEmpty) {
            display = doc[k].toString();
            break;
          }
        }
        list.add(SubjectEntry(
          sem: sem,
          id: id,
          displayName: display,
          data: Map<String, dynamic>.from(doc),
        ));
      });
    });
    list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }

  void _applyFilter() {
    final q = _query.toLowerCase().trim();
    setState(() {
      _filtered = _subjects.where((s) {
        final matchesSem = _selectedSem == null ? true : s.sem == _selectedSem;
        final matchesQuery = q.isEmpty
            ? true
            : (s.displayName.toLowerCase().contains(q) || s.sem.toLowerCase().contains(q));
        return matchesSem && matchesQuery;
      }).toList();
    });
  }

  List<String> get _semesterKeys {
    final keys = _materials.keys.toList();
    keys.sort((a, b) {
      final aNum = int.tryParse(RegExp(r'\d+').stringMatch(a) ?? '') ?? 999;
      final bNum = int.tryParse(RegExp(r'\d+').stringMatch(b) ?? '') ?? 999;
      return aNum.compareTo(bNum);
    });
    return keys;
  }

  Color _getSemColor(String semKey) {
    final key = semKey.toLowerCase().replaceAll(' ', '');
    if (key.contains('sem1')) return const Color(0xFFFF5252);
    if (key.contains('sem2')) return const Color(0xFF448AFF);
    if (key.contains('sem3')) return const Color(0xFFE040FB);
    if (key.contains('sem4')) return const Color(0xFF69F0AE);
    if (key.contains('sem5')) return const Color(0xFFFFAB40);
    if (key.contains('sem6')) return const Color(0xFFFF4081);
    if (key.contains('sem7')) return const Color(0xFF18FFFF);
    if (key.contains('sem8')) return const Color(0xFF536DFE);
    return const Color(0xFF00C853);
  }

  @override
  Widget build(BuildContext context) {
    final defaultGreen = const Color(0xFF00C853);
    final cardRadius = 12.0;

    // Filter actual subject objects based on the stored IDs
    final mySubjectsList = _subjects.where((s) => _mySubjectIds.contains(s.id)).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Study Material", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            
            // --- SECTION 1: MY SUBJECTS (Only visible if not empty) ---
            if (mySubjectsList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                child: Row(
                  children: const [
                    Icon(Icons.bookmark, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text("My Subjects", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(
                height: 110, 
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: mySubjectsList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final s = mySubjectsList[i];
                    final color = _getSemColor(s.sem);
                    return GestureDetector(
                      onTap: () {
                         Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (_) => SubjectMaterialsScreen(entry: s)),
                          );
                      },
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 4, backgroundColor: color),
                                const SizedBox(width: 6),
                                Text(s.sem.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                // --- CROSS BUTTON (Deletes from storage) ---
                                InkWell(
                                  onTap: () => _toggleMySubject(s.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Icon(Icons.close, color: Colors.white38, size: 18),
                                )
                              ],
                            ),
                            Text(
                              s.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white10, height: 20),
            ],

            // --- SECTION 2: FILTERS & SEARCH ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All', style: TextStyle(color: Color.fromARGB(255, 7, 7, 7))),
                      selected: _selectedSem == null,
                      selectedColor: defaultGreen,
                      backgroundColor: Colors.grey[900],
                      onSelected: (_) {
                        _selectedSem = null;
                        _applyFilter();
                      },
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 8),
                    ..._semesterKeys.map((sem) {
                      final label = sem.toUpperCase();
                      final semColor = _getSemColor(sem);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label, style: TextStyle(color: _selectedSem == sem ? Colors.black : Colors.white)),
                          selected: _selectedSem == sem,
                          selectedColor: semColor,
                          backgroundColor: Colors.grey[900],
                          onSelected: (_) {
                            _selectedSem = sem;
                            _applyFilter();
                          },
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) {
                    _query = v;
                    _applyFilter();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search subjects...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Count info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _selectedSem == null ? 'Showing all subjects' : 'Showing ${_selectedSem!.toUpperCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  if (!_loading)
                    Text(
                      '${_filtered.length} subjects',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),

            // --- SECTION 3: MAIN LIST ---
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.folder_open, color: Colors.white24, size: 56),
                              SizedBox(height: 12),
                              Text('No subjects found', style: TextStyle(color: Colors.white24)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final s = _filtered[i];
                            final itemColor = _getSemColor(s.sem);
                            final isAdded = _mySubjectIds.contains(s.id);

                            return Material(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(cardRadius),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(cardRadius),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(builder: (_) => SubjectMaterialsScreen(entry: s)),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      // Left avatar
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: itemColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            s.displayName.isNotEmpty ? s.displayName[0].toUpperCase() : '?',
                                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Title + details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.displayName,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.white10),
                                                  ),
                                                  child: Text(
                                                    s.sem.toUpperCase(),
                                                    style: TextStyle(
                                                      color: itemColor.withOpacity(0.8),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    s.id,
                                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // --- ADD BUTTON (Toggles storage) ---
                                      IconButton(
                                        onPressed: () => _toggleMySubject(s.id),
                                        icon: Icon(
                                          isAdded ? Icons.check_circle : Icons.add_circle_outline,
                                          color: isAdded ? defaultGreen : Colors.white54,
                                        ),
                                      ),
                                      
                                      // Chevron
                                      const Icon(Icons.chevron_right, color: Colors.white54),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}