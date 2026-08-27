import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FreelancerEditProfileScreen extends StatefulWidget {
  final freelancerId;
  const FreelancerEditProfileScreen({required this.freelancerId,super.key});

  @override
  State<FreelancerEditProfileScreen> createState() => _FreelancerEditProfileScreenState();
}

class _FreelancerEditProfileScreenState extends State<FreelancerEditProfileScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillInputController = TextEditingController();
  final TextEditingController _linkTitleController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();

  final List<String> _skills = [];
  final List<Map<String, String>> _portfolioLinks = [];

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;

  String _photoUrl = '';
  File? _selectedImageFile;

  // String? get freelancerId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _skillInputController.dispose();
    _linkTitleController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = widget.freelancerId;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _db.collection('users').doc(uid).get(),
        _db.collection('users').doc(uid).collection('profile').doc('main').get(),
      ]);

      final userSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final profileSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;

      final userData = userSnap.data() ?? {};
      final profileData = profileSnap.data() ?? {};

      _fullNameController.text = (userData['fullName'] ?? '').toString().trim();
      _phoneController.text = (userData['phone'] ?? '').toString().trim();
      _cityController.text = (userData['city'] ?? '').toString().trim();
      _photoUrl = (userData['photoUrl'] ?? '').toString().trim();

      _titleController.text = (profileData['title'] ?? '').toString().trim();
      _bioController.text = (profileData['bio'] ?? '').toString().trim();

      _skills
        ..clear()
        ..addAll(_extractSkills(profileData['skills']));

      _portfolioLinks
        ..clear()
        ..addAll(_extractPortfolioLinks(profileData['portfolioLinks']));
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await _loadProfile();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        _selectedImageFile = File(picked.path);
      });
    } catch (_) {
      _showSnack('Failed to pick image.', AppColors.error);
    }
  }

  void _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isEmpty) return;

    final exists = _skills.any((e) => e.toLowerCase() == skill.toLowerCase());
    if (exists) {
      _showSnack('This skill is already added.', AppColors.info);
      return;
    }

    setState(() {
      _skills.add(skill);
      _skillInputController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _addPortfolioLink() {
    final title = _linkTitleController.text.trim();
    final url = _linkUrlController.text.trim();

    if (title.isEmpty) {
      _showSnack('Please enter link title.', AppColors.warning);
      return;
    }

    if (url.isEmpty) {
      _showSnack('Please enter link URL.', AppColors.warning);
      return;
    }

    final uri = Uri.tryParse(url);
    final isValid = uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isValid) {
      _showSnack('Please enter a valid URL.', AppColors.warning);
      return;
    }

    final exists = _portfolioLinks.any(
          (e) =>
      (e['title'] ?? '').toLowerCase() == title.toLowerCase() &&
          (e['url'] ?? '').toLowerCase() == url.toLowerCase(),
    );

    if (exists) {
      _showSnack('This portfolio link is already added.', AppColors.info);
      return;
    }

    setState(() {
      _portfolioLinks.add({
        'title': title,
        'url': url,
      });
      _linkTitleController.clear();
      _linkUrlController.clear();
    });
  }

  void _removePortfolioLink(Map<String, String> item) {
    setState(() {
      _portfolioLinks.remove(item);
    });
  }

  Future<String> _uploadImageIfNeeded(String uid) async {
    if (_selectedImageFile == null) return _photoUrl;

    setState(() => _uploadingImage = true);

    try {
      final ref = _storage.ref().child(
        'users/$uid/profile/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putFile(_selectedImageFile!);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final uid = widget.freelancerId;
    if (uid == null) {
      _showSnack('You need to login again.', AppColors.error);
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_skills.isEmpty) {
      _showSnack('Please add at least one skill.', AppColors.warning);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      final uploadedPhotoUrl = await _uploadImageIfNeeded(uid);

      final userRef = _db.collection('users').doc(uid);
      final profileRef = userRef.collection('profile').doc('main');

      await Future.wait([
        userRef.set({
          'fullName': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'city': _cityController.text.trim(),
          'photoUrl': uploadedPhotoUrl,
        }, SetOptions(merge: true)),
        profileRef.set({
          'title': _titleController.text.trim(),
          'bio': _bioController.text.trim(),
          'skills': _skills,
          'portfolioLinks': _portfolioLinks,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      ]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      _showSnack('Failed to update profile. Please try again.', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<String> _extractSkills(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    if (value is Map) {
      final result = <String>[];
      value.forEach((key, val) {
        if (val == true) {
          final skill = key.toString().trim();
          if (skill.isNotEmpty) result.add(skill);
        }
      });
      return result;
    }

    return [];
  }

  List<Map<String, String>> _extractPortfolioLinks(dynamic value) {
    final result = <Map<String, String>>[];

    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final title = (item['title'] ?? '').toString().trim();
          final url = (item['url'] ?? '').toString().trim();
          if (title.isNotEmpty && url.isNotEmpty) {
            result.add({
              'title': title,
              'url': url,
            });
          } else if (url.isNotEmpty) {
            result.add({
              'title': 'Portfolio Link',
              'url': url,
            });
          }
        } else {
          final url = item.toString().trim();
          if (url.isNotEmpty) {
            result.add({
              'title': 'Portfolio Link',
              'url': url,
            });
          }
        }
      }
      return result;
    }

    if (value is Map) {
      value.forEach((key, val) {
        final title = key.toString().trim();
        final url = val.toString().trim();
        if (url.isNotEmpty) {
          result.add({
            'title': title.isEmpty ? 'Portfolio Link' : title,
            'url': url,
          });
        }
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.freelancerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _NotLoggedInState(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _saving ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A2A43),
                  Color(0xFF0C4A6E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const _LoadingView()
          : RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _GlassCard(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            _ProfileAvatar(
                              photoUrl: _photoUrl,
                              selectedImageFile: _selectedImageFile,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: (_saving || _uploadingImage) ? null : _pickImageFromGallery,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: _uploadingImage
                                      ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                      : const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Your Profile',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap the image to change your profile photo and update your information',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Personal Information',
                    subtitle: 'Basic information shown in your account',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _GlassCard(
                    child: Column(
                      children: [
                        _AppField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Full name is required';
                            if (value.length < 3) return 'Enter a valid full name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: _phoneController,
                          label: 'Phone',
                          hint: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Phone is required';
                            if (value.length < 7) return 'Enter a valid phone number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: _cityController,
                          label: 'City',
                          hint: 'Enter your city',
                          icon: Icons.location_on_outlined,
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return 'City is required';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Professional Information',
                    subtitle: 'Details that help clients know more about you',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _GlassCard(
                    child: Column(
                      children: [
                        _AppField(
                          controller: _titleController,
                          label: 'Title',
                          hint: 'e.g. Flutter Developer',
                          icon: Icons.badge_outlined,
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return 'Title is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _AppField(
                          controller: _bioController,
                          label: 'Bio',
                          hint: 'Write a short professional description',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Bio is required';
                            if (value.length < 20) return 'Bio must be at least 20 characters';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Skills',
                    subtitle: 'Add your main professional skills',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _AppField(
                                controller: _skillInputController,
                                label: 'Add skill',
                                hint: 'e.g. Flutter',
                                icon: Icons.auto_awesome_rounded,
                                validator: (_) => null,
                                onFieldSubmitted: (_) => _addSkill(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 54,
                              width: 54,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _addSkill,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A2A43),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Icon(Icons.add_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_skills.isEmpty)
                          const Text(
                            'Add at least 1 skill',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (_skills.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills
                                .map(
                                  (skill) => _ChipPill(
                                text: skill,
                                onRemove: _saving ? null : () => _removeSkill(skill),
                              ),
                            )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Portfolio Links',
                    subtitle: 'Add title and link for your previous work',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _GlassCard(
                        child: Column(
                          children: [
                            _AppField(
                              controller: _linkTitleController,
                              label: 'Link Title',
                              hint: 'e.g. GitHub Profile',
                              icon: Icons.title_rounded,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 14),
                            _AppField(
                              controller: _linkUrlController,
                              label: 'Link URL',
                              hint: 'https://github.com/yourname',
                              icon: Icons.link_rounded,
                              keyboardType: TextInputType.url,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _addPortfolioLink,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0C4A6E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text(
                                  'Add Portfolio Link',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_portfolioLinks.isEmpty)
                              const Text(
                                'Optional: add GitHub, Behance, LinkedIn, or portfolio website',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (_portfolioLinks.isNotEmpty)
                              Column(
                                children: _portfolioLinks
                                    .map(
                                      (item) => _PortfolioLinkRow(
                                    title: item['title'] ?? '',
                                    url: item['url'] ?? '',
                                    onRemove: _saving ? null : () => _removePortfolioLink(item),
                                  ),
                                )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: (_saving || _uploadingImage) ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _saving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
}

class _ProfileAvatar extends StatelessWidget {
  final String photoUrl;
  final File? selectedImageFile;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.selectedImageFile,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;

    if (selectedImageFile != null) {
      provider = FileImage(selectedImageFile!);
    } else if (photoUrl.isNotEmpty) {
      provider = NetworkImage(photoUrl);
    }

    return CircleAvatar(
      radius: 34,
      backgroundColor: AppColors.primary.withOpacity(0.10),
      backgroundImage: provider,
      child: provider == null
          ? const Icon(
        Icons.person_rounded,
        size: 34,
        color: AppColors.primary,
      )
          : null,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _AppField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF0A2A43),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String text;
  final VoidCallback? onRemove;

  const _ChipPill({
    required this.text,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF0A2A43),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioLinkRow extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback? onRemove;

  const _PortfolioLinkRow({
    required this.title,
    required this.url,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.link_rounded,
            color: Color(0xFF0C4A6E),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFF0A2A43),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        _GlassCard(
          child: SizedBox(height: 90, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 220, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 180, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 150, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 230, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: _SoftLoadingBox(),
        ),
      ],
    );
  }
}

class _SoftLoadingBox extends StatelessWidget {
  const _SoftLoadingBox();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.black.withOpacity(0.03),
      ),
    );
  }
}

class _NotLoggedInState extends StatelessWidget {
  const _NotLoggedInState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'You need to login first.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}