import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/components.dart';

class CompleteFreelancerProfileScreen extends StatefulWidget {
  const CompleteFreelancerProfileScreen({super.key});

  @override
  State<CompleteFreelancerProfileScreen> createState() => _CompleteFreelancerProfileScreenState();
}

class _CompleteFreelancerProfileScreenState extends State<CompleteFreelancerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _bio = TextEditingController();
  final _skillInput = TextEditingController();
  final _linkInput = TextEditingController();

  final List<String> _skills = [];
  final List<String> _links = [];

  bool _loading = false;

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  void dispose() {
    _title.dispose();
    _bio.dispose();
    _skillInput.dispose();
    _linkInput.dispose();
    super.dispose();
  }

  void _addSkill() {
    final s = _skillInput.text.trim();
    if (s.isEmpty) return;
    final normalized = s.toLowerCase();
    final exists = _skills.any((e) => e.toLowerCase() == normalized);
    if (exists) {
      AppComponents.showAppSnack(
        context,
        title: "Already added",
        message: "This skill is already in the list.",
        type: SnackType.info,
      );
      return;
    }
    setState(() {
      _skills.add(s);
      _skillInput.clear();
    });
  }

  void _addLink() {
    final s = _linkInput.text.trim();
    if (s.isEmpty) return;

    final ok = Uri.tryParse(s)?.hasAbsolutePath ?? false;
    if (!ok) {
      AppComponents.showAppSnack(
        context,
        title: "Invalid link",
        message: "Please enter a valid URL.",
        type: SnackType.warning,
      );
      return;
    }

    final exists = _links.any((e) => e.trim() == s);
    if (exists) {
      AppComponents.showAppSnack(
        context,
        title: "Already added",
        message: "This link is already in the list.",
        type: SnackType.info,
      );
      return;
    }

    setState(() {
      _links.add(s);
      _linkInput.clear();
    });
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppComponents.showAppSnack(
        context,
        title: "Session expired",
        message: "Please sign in again.",
        type: SnackType.error,
      );
      if (mounted) Navigator.pop(context);
      return;
    }

    if (_skills.isEmpty) {
      AppComponents.showAppSnack(
        context,
        title: "Missing skills",
        message: "Please add at least one skill.",
        type: SnackType.warning,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("profile")
          .doc("main");

      await docRef.set({
        "title": _title.text.trim(),
        "bio": _bio.text.trim(),
        "skills": _skills,
        "portfolioLinks": _links,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppComponents.showAppSnack(
        context,
        title: "Profile saved",
        message: "Your freelancer profile is now complete.",
        type: SnackType.success,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      AppComponents.showAppSnack(
        context,
        title: "Save failed",
        message: "Something went wrong. Please try again.",
        type: SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _bgSlate,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                height: size.height * 0.34,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_brandNavy, _slateBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              right: -70,
              child: _GlowCircle(size: 340, color: _slateBlue.withOpacity(0.08)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    _topBar(context),
                    const SizedBox(height: 16),
                    _titleBlock(),
                    const SizedBox(height: 18),
                    _glassCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Image.asset(
            "assets/images/appLogo.png",
            height: 34,
            width: 34,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _titleBlock() {
    return Column(
      children: [
        const Text(
          "Complete Profile",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add your professional info to start getting jobs",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.82),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _glassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Professional Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _textDark),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _title,
                  label: "Title",
                  hint: "e.g. Mobile Developer",
                  prefixIcon: const Icon(Icons.badge_outlined, color: _brandNavy, size: 20),
                  validator: (v) => (v ?? "").trim().isEmpty ? "Title is required" : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _bio,
                  label: "Bio",
                  hint: "Write a short description about you",
                  prefixIcon: const Icon(Icons.subject_rounded, color: _brandNavy, size: 20),
                  validator: (v) => (v ?? "").trim().length < 20 ? "Bio must be at least 20 characters" : null,
                ),

                const SizedBox(height: 18),
                const Text(
                  "Skills",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _textDark),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _skillInput,
                        label: "Add skill",
                        hint: "e.g. Flutter",
                        prefixIcon: const Icon(Icons.auto_awesome_rounded, color: _brandNavy, size: 20),
                        validator: (_) => null,
                        onFieldSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addSkill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_skills.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills
                        .map(
                          (s) => _ChipPill(
                        text: s,
                        onRemove: _loading
                            ? null
                            : () => setState(() => _skills.remove(s)),
                      ),
                    )
                        .toList(),
                  ),
                if (_skills.isEmpty)
                  Text(
                    "Add at least 1 skill",
                    style: TextStyle(color: _textMuted.withOpacity(.9), fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),

                const SizedBox(height: 18),
                const Text(
                  "Portfolio Links",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _textDark),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _linkInput,
                        label: "Add link",
                        hint: "https://github.com/...",
                        prefixIcon: const Icon(Icons.link_rounded, color: _brandNavy, size: 20),
                        validator: (_) => null,
                        onFieldSubmitted: (_) => _addLink(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slateBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_links.isNotEmpty)
                  Column(
                    children: _links
                        .map(
                          (l) => _LinkRow(
                        link: l,
                        onRemove: _loading ? null : () => setState(() => _links.remove(l)),
                      ),
                    )
                        .toList(),
                  ),
                if (_links.isEmpty)
                  Text(
                    "Optional: add GitHub / Behance / Portfolio website",
                    style: TextStyle(color: _textMuted.withOpacity(.9), fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),

                const SizedBox(height: 18),
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [_brandNavy, _slateBlue],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brandNavy.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    child: AppSecondaryButton(
                      text: "SAVE PROFILE",
                      loading: _loading,
                      onPressed: _loading ? null : _save,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String text;
  final VoidCallback? onRemove;

  const _ChipPill({required this.text, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF0A2A43)),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String link;
  final VoidCallback? onRemove;

  const _LinkRow({required this.link, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFF0C4A6E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFF0A2A43)),
          ),
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(size.width * 0.2, size.height, size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(size.width * 0.8, size.height - 80, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    );
  }
}
