import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/jobs/client_applications_list_screen.dart';
import 'package:cv_gate/screens/client/jobs/client_edit_job_screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientJobDetailsScreen extends StatefulWidget {
  final String jobId;

  const ClientJobDetailsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ClientJobDetailsScreen> createState() => _ClientJobDetailsScreenState();
}

class _ClientJobDetailsScreenState extends State<ClientJobDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = clientId;

  bool _processing = false;

  bool _canEdit(String status) => status != 'contracted' && status != 'cancelled';
  bool _canClose(String status) => status == 'open';
  bool _canCancel(String status) => status == 'open' || status == 'closed';

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientEditJobScreen(jobId: widget.jobId),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openApplications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientApplicationsListScreen(jobId: widget.jobId),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _closeJob() async {
    if (_processing) return;

    final confirmed = await _confirmAction(
      title: 'Close Job',
      message: 'Are you sure you want to close this job?',
      confirmText: 'Close Job',
      confirmColor: AppColors.warning,
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      await _db.collection('jobs').doc(widget.jobId).update({
        'status': 'closed',
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job closed successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to close job'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> _cancelJob() async {
    if (_processing) return;

    final confirmed = await _confirmAction(
      title: 'Cancel Job',
      message: 'Are you sure you want to cancel this job? Applied freelancers will be notified.',
      confirmText: 'Cancel Job',
      confirmColor: AppColors.error,
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      final applicationsSnap = await _db
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .get();

      final batch = _db.batch();
      final now = Timestamp.now();

      batch.update(_db.collection('jobs').doc(widget.jobId), {
        'status': 'cancelled',
        'updatedAt': now,
      });

      for (final doc in applicationsSnap.docs) {
        final data = doc.data();
        final freelancerId = (data['freelancerId'] ?? '').toString().trim();

        if (freelancerId.isNotEmpty) {
          final notifRef = _db.collection('notifications').doc();
          batch.set(notifRef, {
            'notifId': notifRef.id,
            'recipientId': freelancerId,
            'type': 'job_cancelled',
            'title': 'Job Cancelled',
            'body': 'A job you applied for has been cancelled by the client.',
            'refType': 'job',
            'refId': widget.jobId,
            'isRead': false,
            'createdAt': now,
          });
        }
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job cancelled successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to cancel job'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<int> _loadApplicationsCount() async {
    try {
      final agg = await _db.collection('applications').where('jobId', isEqualTo: widget.jobId).count().get();
      return agg.count ?? 0;
    } catch (_) {
      final snap = await _db.collection('applications').where('jobId', isEqualTo: widget.jobId).limit(1000).get();
      return snap.size;
    }
  }

  @override
  Widget build(BuildContext context) {
    final docStream = _db.collection('jobs').doc(widget.jobId).snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Job Details',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: docStream,
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
                    child: SizedBox(height: 260, child: _SoftLoadingBox()),
                  ),
                ],
              );
            }

            final data = snap.data!.data();
            if (data == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.work_off_outlined,
                      title: 'Job not found',
                      subtitle: 'This job does not exist or was removed.',
                    ),
                  ),
                ],
              );
            }

            final clientId = (data['clientId'] ?? '').toString();
            if (clientId != _uid) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.lock_outline_rounded,
                      title: 'Access denied',
                      subtitle: 'You are not allowed to view this job.',
                    ),
                  ),
                ],
              );
            }

            final title = (data['title'] ?? '').toString().trim();
            final description = (data['description'] ?? '').toString().trim();
            final category = (data['category'] ?? '').toString().trim();
            final currency = (data['currency'] ?? '').toString().trim();
            final budget = data['budget'];
            final durationDays = data['durationDays'];
            final status = (data['status'] ?? 'open').toString().trim();
            final createdAt = data['createdAt'];
            final updatedAt = data['updatedAt'];
            final skills = (data['skillsRequired'] is List)
                ? List<String>.from(data['skillsRequired'])
                : <String>[];

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title.isEmpty ? 'Untitled Job' : title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _LabeledValueRow(
                        label: 'Category',
                        value: category.isEmpty ? 'Not specified' : category,
                      ),
                      const SizedBox(height: 12),
                      _LabeledValueRow(
                        label: 'Budget',
                        value: _formatBudget(budget, currency),
                      ),
                      const SizedBox(height: 12),
                      _LabeledValueRow(
                        label: 'Duration',
                        value: _formatDuration(durationDays),
                      ),
                      const SizedBox(height: 12),
                      _LabeledValueRow(
                        label: 'Created Date',
                        value: _dateLabel(createdAt),
                      ),
                      const SizedBox(height: 12),
                      _LabeledValueRow(
                        label: 'Last Updated',
                        value: _dateLabel(updatedAt),
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
                        'Description',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description.isEmpty ? 'No description available.' : description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
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
                        'Skills Required',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      skills.isEmpty
                          ? const Text(
                        'No skills specified.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills
                            .map((skill) => _SkillChip(text: skill))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FutureBuilder<int>(
                  future: _loadApplicationsCount(),
                  builder: (context, countSnap) {
                    final applicationsCount = countSnap.data ?? 0;
                    return _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Actions',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ActionInfoRow(
                            label: 'Applications',
                            value: '$applicationsCount',
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openApplications,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.list_alt_rounded),
                              label: const Text(
                                'View Applications',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _canEdit(status) ? _openEdit : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text(
                                    'Edit Job',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _canClose(status) && !_processing ? _closeJob : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.warning,
                                    side: const BorderSide(color: AppColors.warning),
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.pause_circle_outline_rounded),
                                  label: const Text(
                                    'Close Job',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _canCancel(status) && !_processing ? _cancelJob : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text(
                                    'Cancel Job',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatBudget(dynamic budget, String currency) {
    if (budget == null) return 'Not specified';
    if (budget is int) return '$budget $currency';
    if (budget is double) {
      if (budget == budget.roundToDouble()) return '${budget.toInt()} $currency';
      return '${budget.toStringAsFixed(2)} $currency';
    }
    final parsed = double.tryParse(budget.toString());
    if (parsed == null) return 'Not specified';
    if (parsed == parsed.roundToDouble()) return '${parsed.toInt()} $currency';
    return '${parsed.toStringAsFixed(2)} $currency';
  }

  static String _formatDuration(dynamic duration) {
    if (duration == null) return 'Not specified';
    if (duration is int) return '$duration days';
    final parsed = int.tryParse(duration.toString());
    if (parsed == null) return 'Not specified';
    return '$parsed days';
  }
}

class _LabeledValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ActionInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    late final Color bg;
    late final Color fg;

    if (s == 'open') {
      bg = AppColors.success.withOpacity(0.14);
      fg = AppColors.success;
    } else if (s == 'closed') {
      bg = AppColors.warning.withOpacity(0.14);
      fg = AppColors.warning;
    } else if (s == 'contracted') {
      bg = AppColors.accent.withOpacity(0.14);
      fg = AppColors.accent;
    } else if (s == 'cancelled') {
      bg = AppColors.error.withOpacity(0.14);
      fg = AppColors.error;
    } else {
      bg = AppColors.textSecondary.withOpacity(0.14);
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.2,
          letterSpacing: 0.2,
        ),
      ),
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

class _SoftLoadingBox extends StatelessWidget {
  const _SoftLoadingBox();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(color: Colors.black.withOpacity(0.03)),
    );
  }
}

String _dateLabel(dynamic value) {
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }
  return 'Recently';
}

String _two(int v) => v < 10 ? '0$v' : '$v';