import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academia_app/club_events_social/services/club_main_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Premium Monochrome Palette
const Color kPureBlack = Color(0xFF000000);
const Color kCardGrey = Color(0xFF111111);
const Color kSoftGrey = Color(0xFF1C1C1E);
const Color kAccentWhite = Colors.white;
const Color kMutedWhite = Colors.white38;
const Color kGlassWhite = Colors.white10;

class CreatePostScreen extends StatefulWidget {
  final ApiService apiService;
  const CreatePostScreen({super.key, required this.apiService});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _clubIdController = TextEditingController();
  final TextEditingController _clubPassController = TextEditingController();
  
  bool _isIndividual = true;
  List<File> _selectedImages = [];
  double _expiryDays = 7; 
  bool _isUploading = false;
  String _truncatedUserEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    String rawEmail = prefs.getString('userEmail') ?? "user@edu.com";
    setState(() {
      _truncatedUserEmail = rawEmail.contains('@') ? rawEmail.split('@')[0] : rawEmail;
    });
  }

  String _calculateExpiryTimestamp() {
    final expiryDate = DateTime.now().add(Duration(days: _expiryDays.round(), hours: 1));
    return (expiryDate.millisecondsSinceEpoch ~/ 1000).toString();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images.map((img) => File(img.path))));
    }
  }

  Future<void> _handlePublish() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);
    try {
      await widget.apiService.createPost(
        ownerIndividual: _isIndividual,
        content: _contentController.text,
        idClub: _isIndividual ? null : _clubIdController.text,
        clubPass: _isIndividual ? "" : _clubPassController.text,
        individualEmail: _truncatedUserEmail,
        expiryTime: _calculateExpiryTimestamp(),
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPureBlack,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Post",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,         // match Mess Menu size
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : TextButton(
                    onPressed: _handlePublish,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      "POST",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- Identity Switcher ---
            _buildIdentitySelector(),

            const SizedBox(height: 20),

            // --- Club Admin Fields ---
            if (!_isIndividual) 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildModernInput(_clubIdController, "CLUB ID", Icons.alternate_email_rounded),
                    const SizedBox(height: 12),
                    _buildModernInput(_clubPassController, "CLUB PASS", Icons.lock_open_rounded, obscure: true),
                  ],
                ),
              ),

            // --- Editor ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                cursorColor: kAccentWhite,
                style: const TextStyle(color: kAccentWhite, fontSize: 17, height: 1.5),
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(color: kMutedWhite),
                  border: InputBorder.none,
                ),
              ),
            ),

            // --- Media Strip ---
            if (_selectedImages.isNotEmpty) _buildImageStrip(),

            const SizedBox(height: 10),
            _buildGhostButton(Icons.add_a_photo_outlined, "ATTACH MEDIA", _pickImages),

            // --- Expiry / Duration Bar ---
            _buildDurationControl(),

            // --- Disclaimer Section ---
            _buildDisclaimer(),

            // --- Register Club Prompt ---
            // --- Club Registration Link ---
            _buildRegisterClubPrompt(),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitySelector() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: kCardGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildPill("INDIVIDUAL", _isIndividual, () => setState(() => _isIndividual = true)),
          _buildPill("CLUB", !_isIndividual, () => setState(() => _isIndividual = false)),
        ],
      ),
    );
  }

  Widget _buildPill(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? kSoftGrey : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(label, 
              style: TextStyle(
                color: active ? kAccentWhite : kMutedWhite,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.5
              )),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      cursorColor: kAccentWhite,
      style: const TextStyle(color: kAccentWhite, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kMutedWhite, size: 18),
        hintText: label,
        hintStyle: const TextStyle(color: kMutedWhite, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
        filled: true,
        fillColor: kCardGrey,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildImageStrip() {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) => Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: kGlassWhite),
            image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => setState(() => _selectedImages.removeAt(index)),
              icon: const CircleAvatar(radius: 12, backgroundColor: kPureBlack, child: Icon(Icons.close, color: kAccentWhite, size: 14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: kAccentWhite, size: 18),
        label: Text(label, style: const TextStyle(color: kAccentWhite, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kGlassWhite),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildDurationControl() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("VISIBILITY DURATION", style: TextStyle(color: kMutedWhite, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5)),
              Text("${_expiryDays.round()} DAYS", style: const TextStyle(color: kAccentWhite, fontWeight: FontWeight.w900, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kAccentWhite,
              inactiveTrackColor: kGlassWhite,
              thumbColor: kAccentWhite,
              trackHeight: 2,
            ),
            child: Slider(
              value: _expiryDays,
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => _expiryDays = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          const Divider(color: kGlassWhite),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: kMutedWhite, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "By posting, you acknowledge that your user handle ($_truncatedUserEmail) will be logged. For security, only the original uploader or an official moderator can remove this post. Posts automatically expire and are deleted after the selected duration.",
                  style: const TextStyle(color: kMutedWhite, fontSize: 11, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


////for club registration prompt
Widget _buildRegisterClubPrompt() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: InkWell(
      onTap: () {
        _launchUrl("https://console-x-academia.vercel.app/contactus");
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: kGlassWhite, // Subtle lift from the background
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kGlassWhite),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "WANT TO POST AS A GROUP/CLUB?",
              style: TextStyle(
                color: kMutedWhite,
                fontWeight: FontWeight.w900,
                fontSize: 8,
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "APPLY FOR ACCESS",
              style: TextStyle(
                color: kAccentWhite,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.2,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
//////////////////////////////////////////////////////////////////////////
}