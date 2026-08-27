import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientFreelancerProfileDetailsScreen extends StatefulWidget {
  final String freelancerId;

  const ClientFreelancerProfileDetailsScreen({
    super.key,
    required this.freelancerId,
  });

  @override
  State<ClientFreelancerProfileDetailsScreen> createState() => _ClientFreelancerProfileDetailsScreenState();
}

class _ClientFreelancerProfileDetailsScreenState extends State<ClientFreelancerProfileDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _clientId = clientId;

  Future<Map<String, dynamic>> _loadUser() async {
    final snap = await _db.collection('users').doc(widget.freelancerId).get();
    return snap.data() ?? {};
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final snap = await _db.collection('users').doc(widget.freelancerId).collection('profile').doc('main').get();
    return snap.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> _loadVerifiedCertificates() async {
    final snap = await _db
        .collection('users')
        .doc(widget.freelancerId)
        .collection('certificates')
        .where('verifyStatus', isEqualTo: 'verified')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snap.docs.map((e) => e.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _loadReviews() async {
    final snap = await _db
        .collection('reviews')
        .where('toUserId', isEqualTo: widget.freelancerId)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snap.docs.map((e) => e.data()).toList();
  }

  Future<List<dynamic>> _loadAllData() async {
    return Future.wait([
      _loadUser(),
      _loadProfile(),
      _loadVerifiedCertificates(),
      _loadReviews(),
    ]);
  }

  List<String> _extractSkills(dynamic rawSkills) {
    if (rawSkills is List) {
      return rawSkills.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  List<Map<String, String>> _extractPortfolioLinks(dynamic rawPortfolio) {
    if (rawPortfolio is List) {
      return rawPortfolio.map((item) {
        if (item is Map) {
          return {
            'title': (item['title'] ?? '').toString(),
            'url': (item['url'] ?? '').toString(),
          };
        }
        return {
          'title': '',
          'url': item.toString(),
        };
      }).where((item) => (item['url'] ?? '').trim().isNotEmpty).toList();
    }

    if (rawPortfolio is Map) {
      return rawPortfolio.entries.map((entry) {
        return {
          'title': entry.key.toString(),
          'url': entry.value.toString(),
        };
      }).where((item) => (item['url'] ?? '').trim().isNotEmpty).toList();
    }

    return <Map<String, String>>[];
  }

  Future<void> _openSendJobRequestSheet({
    required String freelancerName,
    required String freelancerTitle,
  }) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final skillsController = TextEditingController();
    final budgetController = TextEditingController();
    final durationController = TextEditingController();

    String currency = 'SAR';
    bool saving = false;
    final currencies = ['SAR', 'USD', 'EUR'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (saving) return;

              final valid = formKey.currentState?.validate() ?? false;
              if (!valid) return;

              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final category = categoryController.text.trim();
              final budget = double.tryParse(budgetController.text.trim()) ?? 0;
              final durationDays = int.tryParse(durationController.text.trim()) ?? 0;
              final skillsRequired = skillsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              setModalState(() {
                saving = true;
              });

              try {
                final now = Timestamp.now();
                final jobRef = _db.collection('jobs').doc();
                final notifRef = _db.collection('notifications').doc();

                final batch = _db.batch();

                batch.set(jobRef, {
                  'jobId': jobRef.id,
                  'clientId': _clientId,
                  'title': title,
                  'description': description,
                  'category': category,
                  'skillsRequired': skillsRequired,
                  'budget': budget,
                  'currency': currency,
                  'durationDays': durationDays,
                  'status': 'open',
                  'createdAt': now,
                  'updatedAt': now,
                });

                batch.set(notifRef, {
                  'notifId': notifRef.id,
                  'recipientId': widget.freelancerId,
                  'type': 'direct_job_request',
                  'title': 'New Job Request',
                  'body': 'A client sent you a direct job request.',
                  'refType': 'job',
                  'refId': jobRef.id,
                  'isRead': false,
                  'createdAt': now,
                });

                await batch.commit();

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Job request sent successfully'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              } catch (_) {
                setModalState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to send job request'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              }
            }

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
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
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
                              'Send Job Request',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              freelancerTitle.isEmpty
                                  ? 'Create a direct job request for $freelancerName'
                                  : 'Create a direct job request for $freelancerName - $freelancerTitle',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel(label: 'Job Title'),
                          const SizedBox(height: 8),
                          _AppTextField(
                            controller: titleController,
                            hint: 'Enter job title',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Please enter the job title';
                              }
                              if ((value ?? '').trim().length < 4) {
                                return 'Title is too short';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel(label: 'Description'),
                          const SizedBox(height: 8),
                          _AppTextField(
                            controller: descriptionController,
                            hint: 'Enter job description',
                            maxLines: 5,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Please enter the description';
                              }
                              if ((value ?? '').trim().length < 10) {
                                return 'Description is too short';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel(label: 'Category'),
                          const SizedBox(height: 8),
                          _AppTextField(
                            controller: categoryController,
                            hint: 'Enter category',
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Please enter the category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel(label: 'Skills Required'),
                          const SizedBox(height: 8),
                          _AppTextField(
                            controller: skillsController,
                            hint: 'Example: Flutter, Firebase, UI Design',
                            maxLines: 3,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Please enter at least one skill';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel(label: 'Budget'),
                                    const SizedBox(height: 8),
                                    _AppTextField(
                                      controller: budgetController,
                                      hint: '0.00',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if ((value ?? '').trim().isEmpty) {
                                          return 'Required';
                                        }
                                        final parsed = double.tryParse(value!.trim());
                                        if (parsed == null || parsed <= 0) {
                                          return 'Invalid budget';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel(label: 'Currency'),
                                    const SizedBox(height: 8),
                                    _CurrencyDropdown(
                                      value: currency,
                                      items: currencies,
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setModalState(() {
                                          currency = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel(label: 'Duration Days'),
                          const SizedBox(height: 8),
                          _AppTextField(
                            controller: durationController,
                            hint: 'Enter duration in days',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Please enter duration';
                              }
                              final parsed = int.tryParse(value!.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Invalid duration';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: saving ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.send_rounded),
                              label: Text(
                                saving ? 'Sending...' : 'Send Job Request',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Freelancer Profile',
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
        child: FutureBuilder<List<dynamic>>(
          future: _loadAllData(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: SizedBox(height: 160, child: _SoftLoadingBox()),
                  ),
                  SizedBox(height: 14),
                  _GlassCard(
                    child: SizedBox(height: 240, child: _SoftLoadingBox()),
                  ),
                  SizedBox(height: 14),
                  _GlassCard(
                    child: SizedBox(height: 200, child: _SoftLoadingBox()),
                  ),
                ],
              );
            }

            final user = snap.data![0] as Map<String, dynamic>;
            final profile = snap.data![1] as Map<String, dynamic>;
            final certificates = snap.data![2] as List<Map<String, dynamic>>;
            final reviews = snap.data![3] as List<Map<String, dynamic>>;

            final fullName = (user['fullName'] ?? '').toString().trim();
            final photoUrl = (user['photoUrl'] ?? '').toString().trim();
            final city = (user['city'] ?? '').toString().trim();
            final ratingAvg = _toDouble(user['ratingAvg']);
            final ratingCount = _toInt(user['ratingCount']);

            final title = (profile['title'] ?? '').toString().trim();
            final bio = (profile['bio'] ?? '').toString().trim();

            final skills = _extractSkills(profile['skills']);
            final portfolioLinks = _extractPortfolioLinks(profile['portfolioLinks']);

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _GlassCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.primary.withOpacity(0.10),
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(
                          _initials(fullName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName.isEmpty ? 'Freelancer' : fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title.isEmpty ? 'No title' : title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _InfoChip(
                            label: 'City',
                            value: city.isEmpty ? 'Not specified' : city,
                          ),
                          _InfoChip(
                            label: 'Rating',
                            value: ratingCount > 0
                                ? '${ratingAvg.toStringAsFixed(1)} ($ratingCount reviews)'
                                : 'No ratings',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openSendJobRequestSheet(
                            freelancerName: fullName.isEmpty ? 'Freelancer' : fullName,
                            freelancerTitle: title,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded),
                          label: const Text(
                            'Send Job Request',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bio',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio.isEmpty ? 'No bio available.' : bio,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skills',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      skills.isEmpty
                          ? const Text(
                        'No skills listed.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((e) => _SkillChip(text: e)).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portfolio Links',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      portfolioLinks.isEmpty
                          ? const Text(
                        'No portfolio links available.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : Column(
                        children: portfolioLinks
                            .map(
                              (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PortfolioTile(
                              title: (item['title'] ?? '').trim(),
                              url: (item['url'] ?? '').trim(),
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Certificates',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      certificates.isEmpty
                          ? const Text(
                        'No verified certificates found.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : Column(
                        children: certificates
                            .map(
                              (cert) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CertificateTile(data: cert),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reviews Preview',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      reviews.isEmpty
                          ? const Text(
                        'No reviews available yet.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : Column(
                        children: reviews
                            .map(
                              (review) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ReviewTile(data: review),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  final String title;
  final String url;

  const _PortfolioTile({
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.isEmpty ? 'Portfolio Link' : title;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.link_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CertificateTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString().trim();
    final issuer = (data['issuer'] ?? '').toString().trim();
    final issueDate = (data['issueDate'] ?? '').toString().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Certificate' : name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issuer.isEmpty ? 'Issuer not specified' : issuer,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (issueDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Issue Date: $issueDate',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReviewTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final rating = _toDouble(data['rating']);
    final comment = (data['comment'] ?? '').toString().trim();
    final createdAt = data['createdAt'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Rating',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.isEmpty ? 'No comment provided.' : comment,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _dateLabel(createdAt),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({
    required this.label,
  });

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
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 13,
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CurrencyDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            ),
          )
              .toList(),
          onChanged: onChanged,
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
      constraints: const BoxConstraints(maxWidth: 210),
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

class _SkillChip extends StatelessWidget {
  final String text;

  const _SkillChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
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

String _dateLabel(dynamic value) {
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }
  return 'Recently';
}

String _two(int v) => v < 10 ? '0$v' : '$v';