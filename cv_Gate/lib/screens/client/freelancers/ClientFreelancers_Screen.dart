import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/freelancers/client_freelancer_profile_details_screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:flutter/material.dart';

class ClientBrowseFreelancersScreen extends StatefulWidget {
  const ClientBrowseFreelancersScreen({super.key});

  @override
  State<ClientBrowseFreelancersScreen> createState() => _ClientBrowseFreelancersScreenState();
}

class _ClientBrowseFreelancersScreenState extends State<ClientBrowseFreelancersScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();

  String _cityFilter = '';
  String _skillFilter = '';
  String _ratingFilter = 'all';

  final Map<String, Map<String, dynamic>> _profileCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadProfile(String uid) async {
    if (_profileCache.containsKey(uid)) return _profileCache[uid]!;
    try {
      final snap = await _db.collection('users').doc(uid).collection('profile').doc('main').get();
      final data = snap.data() ?? {};
      _profileCache[uid] = data;
      return data;
    } catch (_) {
      return {};
    }
  }

  bool _matchesSearch({
    required String fullName,
    required String title,
    required String city,
    required List<String> skills,
  }) {
    final search = _searchController.text.trim().toLowerCase();
    if (search.isEmpty) return true;

    if (fullName.toLowerCase().contains(search)) return true;
    if (title.toLowerCase().contains(search)) return true;
    if (city.toLowerCase().contains(search)) return true;
    if (skills.any((e) => e.toLowerCase().contains(search))) return true;

    return false;
  }

  bool _matchesCity(String freelancerCity) {
    if (_cityFilter.trim().isEmpty) return true;
    return freelancerCity.toLowerCase().contains(_cityFilter.trim().toLowerCase());
  }

  bool _matchesSkill(List<String> skills) {
    if (_skillFilter.trim().isEmpty) return true;
    return skills.any((e) => e.toLowerCase().contains(_skillFilter.trim().toLowerCase()));
  }

  bool _matchesRating(double ratingAvg) {
    if (_ratingFilter == 'all') return true;
    if (_ratingFilter == '4+') return ratingAvg >= 4;
    if (_ratingFilter == '3+') return ratingAvg >= 3;
    if (_ratingFilter == '2+') return ratingAvg >= 2;
    return true;
  }

  Future<void> _openFreelancerDetails(String freelancerId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFreelancerProfileDetailsScreen(freelancerId: freelancerId),
      ),
    );
  }

  Future<void> _openAdvancedFilters() async {
    final cityController = TextEditingController(text: _cityFilter);
    final skillController = TextEditingController(text: _skillFilter);
    String tempRating = _ratingFilter;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Advanced Filters',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel(label: 'City'),
                      const SizedBox(height: 8),
                      _AppTextField(
                        controller: cityController,
                        hint: 'Enter city',
                      ),
                      const SizedBox(height: 12),
                      const _FieldLabel(label: 'Skill'),
                      const SizedBox(height: 8),
                      _AppTextField(
                        controller: skillController,
                        hint: 'Enter skill',
                      ),
                      const SizedBox(height: 12),
                      const _FieldLabel(label: 'Minimum Rating'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RatingFilterChip(
                            label: 'All',
                            value: 'all',
                            currentValue: tempRating,
                            onSelected: (v) => setModalState(() => tempRating = v),
                          ),
                          _RatingFilterChip(
                            label: '4+',
                            value: '4+',
                            currentValue: tempRating,
                            onSelected: (v) => setModalState(() => tempRating = v),
                          ),
                          _RatingFilterChip(
                            label: '3+',
                            value: '3+',
                            currentValue: tempRating,
                            onSelected: (v) => setModalState(() => tempRating = v),
                          ),
                          _RatingFilterChip(
                            label: '2+',
                            value: '2+',
                            currentValue: tempRating,
                            onSelected: (v) => setModalState(() => tempRating = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                cityController.clear();
                                skillController.clear();
                                setModalState(() {
                                  tempRating = 'all';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _cityFilter = cityController.text.trim();
                                  _skillFilter = skillController.text.trim();
                                  _ratingFilter = tempRating;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _activeFiltersCount() {
    int count = 0;
    if (_cityFilter.isNotEmpty) count++;
    if (_skillFilter.isNotEmpty) count++;
    if (_ratingFilter != 'all') count++;
    return count;
  }

  Future<List<_FreelancerCardData>> _buildFreelancers(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final List<_FreelancerCardData> items = [];

    for (final doc in docs) {
      final user = doc.data();
      final uid = doc.id;
      final profile = await _loadProfile(uid);

      final fullName = (user['fullName'] ?? '').toString().trim();
      final photoUrl = (user['photoUrl'] ?? '').toString().trim();
      final city = (user['city'] ?? '').toString().trim();
      final ratingAvg = _toDouble(user['ratingAvg']);
      final ratingCount = _toInt(user['ratingCount']);

      final title = (profile['title'] ?? '').toString().trim();
      final bio = (profile['bio'] ?? '').toString().trim();

      final skills = profile['skills'] is List
          ? List<String>.from(
        (profile['skills'] as List).map((e) => e.toString()),
      )
          : <String>[];

      final shortBio = bio.length > 110 ? '${bio.substring(0, 110)}...' : bio;

      if (!_matchesSearch(
        fullName: fullName,
        title: title,
        city: city,
        skills: skills,
      )) {
        continue;
      }

      if (!_matchesCity(city)) continue;
      if (!_matchesSkill(skills)) continue;
      if (!_matchesRating(ratingAvg)) continue;

      items.add(
        _FreelancerCardData(
          uid: uid,
          fullName: fullName,
          photoUrl: photoUrl,
          city: city,
          ratingAvg: ratingAvg,
          ratingCount: ratingCount,
          title: title,
          shortBio: shortBio,
          skills: skills,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db
        .collection('users')
        .where('role', isEqualTo: 'freelancer')
        .where('isActive', isEqualTo: true)
        .snapshots();

    final activeFilters = _activeFiltersCount();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Freelancers',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _GlassCard(
                child: Column(
                  children: [
                    _AppTextField(
                      controller: _searchController,
                      hint: 'Search by name, title, city, or skill',
                      onChanged: (_) => setState(() {}),
                      prefixIcon: Icons.search_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openAdvancedFilters,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.tune_rounded),
                            label: Text(
                              activeFilters > 0 ? 'Filters ($activeFilters)' : 'Advanced Filters',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty || activeFilters > 0) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 110,
                            child: OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _cityFilter = '';
                                  _skillFilter = '';
                                  _ratingFilter = 'all';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: _GlassCard(
                        child: _EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Failed to load freelancers',
                          subtitle: 'Please try again later.',
                        ),
                      ),
                    );
                  }

                  if (!snap.hasData) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, __) => const _GlassCard(
                        child: SizedBox(height: 150, child: _SoftLoadingBox()),
                      ),
                    );
                  }

                  final docs = snap.data!.docs;

                  return FutureBuilder<List<_FreelancerCardData>>(
                    future: _buildFreelancers(docs),
                    builder: (context, filteredSnap) {
                      if (!filteredSnap.hasData) {
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: 4,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, __) => const _GlassCard(
                            child: SizedBox(height: 150, child: _SoftLoadingBox()),
                          ),
                        );
                      }

                      final freelancers = filteredSnap.data!;

                      if (freelancers.isEmpty) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          children: const [
                            _GlassCard(
                              child: _EmptyState(
                                icon: Icons.people_outline_rounded,
                                title: 'No freelancers found',
                                subtitle: 'Try changing your search or advanced filters.',
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: freelancers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = freelancers[index];
                          return _FreelancerCard(
                            data: item,
                            onTap: () => _openFreelancerDetails(item.uid),
                          );
                        },
                      );
                    },
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

class _FreelancerCardData {
  final String uid;
  final String fullName;
  final String photoUrl;
  final String city;
  final double ratingAvg;
  final int ratingCount;
  final String title;
  final String shortBio;
  final List<String> skills;

  const _FreelancerCardData({
    required this.uid,
    required this.fullName,
    required this.photoUrl,
    required this.city,
    required this.ratingAvg,
    required this.ratingCount,
    required this.title,
    required this.shortBio,
    required this.skills,
  });
}

class _FreelancerCard extends StatelessWidget {
  final _FreelancerCardData data;
  final VoidCallback onTap;

  const _FreelancerCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.10),
                  backgroundImage: data.photoUrl.isNotEmpty ? NetworkImage(data.photoUrl) : null,
                  child: data.photoUrl.isEmpty
                      ? Text(
                    _initials(data.fullName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.fullName.isEmpty ? 'Freelancer' : data.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.title.isEmpty ? 'No title' : data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: 'City',
                            value: data.city.isEmpty ? 'Not specified' : data.city,
                          ),
                          _InfoChip(
                            label: 'Rating',
                            value: data.ratingCount > 0
                                ? '${data.ratingAvg.toStringAsFixed(1)} (${data.ratingCount})'
                                : 'No ratings',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LabeledBlock(
              label: 'Short Bio',
              value: data.shortBio.isEmpty ? 'No bio available.' : data.shortBio,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Open Profile',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentValue;
  final ValueChanged<String> onSelected;

  const _RatingFilterChip({
    required this.label,
    required this.value,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: AppColors.textSecondary),
        hintStyle: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LabeledBlock extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.8,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

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
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.2),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'F';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}