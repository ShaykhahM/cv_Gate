import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:flutter/material.dart';



class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  final String freelancerId;

  const JobDetailsScreen({
    super.key,
    required this.jobId,
    required this.freelancerId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _submitting = false;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _hasAppliedBefore() async {
    try {
      final snap = await _db
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .where('freelancerId', isEqualTo: widget.freelancerId)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('JobDetailsScreen _hasAppliedBefore error: $e');
      return false;
    }
  }

  Future<void> _showApplyDialog(Map<String, dynamic> jobData) async {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final messageController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Proposal',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fill your proposed price, duration, and short message.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'Proposed Price',
                            icon: Icons.payments_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter proposed price';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'Proposed Duration (days)',
                            icon: Icons.schedule_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter proposed duration';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter valid duration';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: messageController,
                          maxLines: 4,
                          decoration: _inputDecoration(
                            label: 'Cover Message',
                            icon: Icons.message_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter cover message';
                            }
                            if (value.trim().length < 10) {
                              return 'Message is too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (!formKey.currentState!.validate()) return;
                                    Navigator.pop(context, true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Send',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final proposedPrice = double.parse(priceController.text.trim());
    final proposedDuration = int.parse(durationController.text.trim());
    final message = messageController.text.trim();

    await _submitApplication(
      jobData: jobData,
      proposedPrice: proposedPrice,
      proposedDuration: proposedDuration,
      message: message,
    );
  }

  Future<void> _submitApplication({
    required Map<String, dynamic> jobData,
    required double proposedPrice,
    required int proposedDuration,
    required String message,
  }) async {
    if (_submitting) return;

    try {
      setState(() {
        _submitting = true;
      });

      final alreadyApplied = await _hasAppliedBefore();
      if (alreadyApplied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already applied to this job.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _submitting = false;
        });
        return;
      }

      final applicationRef = _db.collection('applications').doc();
      final notifRef = _db.collection('notifications').doc();

      final clientId = (jobData['clientId'] ?? '').toString().trim();

      await applicationRef.set({
        'applicationId': applicationRef.id,
        'jobId': widget.jobId,
        'clientId': clientId,
        'freelancerId': widget.freelancerId,
        'message': message,
        'proposedPrice': proposedPrice,
        'proposedDurationDays': proposedDuration,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (clientId.isNotEmpty) {
        await notifRef.set({
          'notifId': notifRef.id,
          'recipientId': clientId,
          'type': 'job_application',
          'title': 'New job application',
          'body': 'A freelancer has sent a proposal for your job.',
          'refType': 'applications',
          'refId': applicationRef.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proposal sent successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {});
    } catch (e) {
      debugPrint('JobDetailsScreen _submitApplication error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send proposal.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
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
          centerTitle: false,
          title: const Text(
            'Job Details',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _db.collection('jobs').doc(widget.jobId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('JobDetailsScreen load job error: ${snapshot.error}');
            return _ErrorState(onRetry: _refresh);
          }

          if (!snapshot.hasData) {
            return const _LoadingView();
          }

          if (!snapshot.data!.exists) {
            return const _NotFoundState();
          }

          final jobData = snapshot.data!.data() ?? {};
          final title = (jobData['title'] ?? 'Untitled Job').toString().trim();
          final description = (jobData['description'] ?? '').toString().trim();
          final category = (jobData['category'] ?? 'General').toString().trim();
          final currency = (jobData['currency'] ?? 'SAR').toString().trim();
          final budget = jobData['budget'];
          final duration = (jobData['durationDays'] ?? '-').toString();
          final skills = _extractSkills(jobData['skillsRequired']);
          final status = (jobData['status'] ?? 'open').toString().trim();

          return FutureBuilder<bool>(
            future: _hasAppliedBefore(),
            builder: (context, appliedSnapshot) {
              final hasApplied = appliedSnapshot.data == true;
              final canApply = status.toLowerCase() == 'open' && !hasApplied;

              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _HeaderCard(
                          title: title,
                          category: category,
                          budget: '$budget $currency',
                          duration: '$duration days',
                          status: status,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Job Description',
                          subtitle: 'Full details about this job post',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Text(
                            description.isEmpty
                                ? 'No description available.'
                                : description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Required Skills',
                          subtitle: 'Skills requested by the client',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: skills.isEmpty
                              ? const Text(
                            'No specific skills added.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                              : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills
                                .map((e) => _SkillChip(label: e))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Budget & Duration',
                          subtitle: 'Main job offer information',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: _MiniInfoBox(
                                  icon: Icons.payments_outlined,
                                  label: 'Budget',
                                  value: '$budget $currency',
                                  tint: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MiniInfoBox(
                                  icon: Icons.schedule_outlined,
                                  label: 'Duration',
                                  value: '$duration days',
                                  tint: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                      sliver: SliverToBoxAdapter(
                        child: _ApplySection(
                          hasApplied: hasApplied,
                          canApply: canApply,
                          submitting: _submitting,
                          onApply: () => _showApplyDialog(jobData),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<String> _extractSkills(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is Map) {
      return value.entries
          .where((e) => e.value == true || e.value.toString().trim().isNotEmpty)
          .map((e) => e.key.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.45)),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String category;
  final String budget;
  final String duration;
  final String status;

  const _HeaderCard({
    required this.title,
    required this.category,
    required this.budget,
    required this.duration,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallTag(
                          label: category,
                          bg: AppColors.info.withOpacity(0.10),
                          fg: AppColors.info,
                        ),
                        _StatusChip(status: status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniInfoBox(
                  icon: Icons.payments_outlined,
                  label: 'Budget',
                  value: budget,
                  tint: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  icon: Icons.schedule_outlined,
                  label: 'Duration',
                  value: duration,
                  tint: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplySection extends StatelessWidget {
  final bool hasApplied;
  final bool canApply;
  final bool submitting;
  final VoidCallback onApply;

  const _ApplySection({
    required this.hasApplied,
    required this.canApply,
    required this.submitting,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    VoidCallback? action;

    if (submitting) {
      text = 'Sending...';
      action = null;
    } else if (hasApplied) {
      text = 'Already Applied';
      action = null;
    } else if (!canApply) {
      text = 'Job Not Available';
      action = null;
    } else {
      text = 'Apply / Send Proposal';
      action = onApply;
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proposal Action',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasApplied
                ? 'You already submitted a proposal for this job.'
                : 'Send your proposal to the client if this job matches your skills.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: action == null
                    ? null
                    : AppColors.primaryGradient,
                color: action == null
                    ? AppColors.textLight.withOpacity(0.18)
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: AppColors.textSecondary,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  text,
                  style: TextStyle(
                    color: action == null
                        ? AppColors.textSecondary
                        : Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

class _MiniInfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _MiniInfoBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
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

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _SmallTag({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    Color bg;
    Color fg;
    String label;

    if (s == 'open') {
      bg = AppColors.success.withOpacity(0.12);
      fg = AppColors.success;
      label = 'Open';
    } else if (s == 'closed') {
      bg = AppColors.textLight.withOpacity(0.18);
      fg = AppColors.textSecondary;
      label = 'Closed';
    } else if (s == 'contracted') {
      bg = AppColors.warning.withOpacity(0.12);
      fg = AppColors.warning;
      label = 'Contracted';
    } else if (s == 'cancelled') {
      bg = AppColors.error.withOpacity(0.12);
      fg = AppColors.error;
      label = 'Cancelled';
    } else {
      bg = AppColors.textLight.withOpacity(0.18);
      fg = AppColors.textSecondary;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        _GlassCard(
          child: SizedBox(height: 120, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 120, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 100, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 110, child: _SoftLoadingBox()),
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

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

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
              Icons.search_off_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Job not found.',
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

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.onRetry,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load job details.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () => onRetry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(120, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}