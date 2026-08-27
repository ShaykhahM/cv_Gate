import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/payments/client_make_payment_screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientSubmissionReviewScreen extends StatefulWidget {
  final String contractId;

  const ClientSubmissionReviewScreen({
    super.key,
    required this.contractId,
  });

  @override
  State<ClientSubmissionReviewScreen> createState() => _ClientSubmissionReviewScreenState();
}

class _ClientSubmissionReviewScreenState extends State<ClientSubmissionReviewScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _processing = false;

  Future<Map<String, dynamic>?> _loadContract() async {
    final snap = await _db.collection('contracts').doc(widget.contractId).get();
    return snap.data();
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _loadLatestSubmission() async {
    final snap = await _db
        .collection('submissions')
        .where('contractId', isEqualTo: widget.contractId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<List<dynamic>> _loadData() async {
    return Future.wait([
      _loadContract(),
      _loadLatestSubmission(),
    ]);
  }

  Future<void> _openFile(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showSnackBar('Invalid file URL', AppColors.error);
      return;
    }

    final uri = Uri.tryParse(cleanUrl);

    if (uri == null || (!uri.hasScheme)) {
      _showSnackBar('Invalid file URL', AppColors.error);
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!opened) {
        _showSnackBar('Could not open file', AppColors.error);
      }
    } catch (_) {
      _showSnackBar('Failed to open file', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  List<_SubmissionFileItem> _extractFiles(dynamic filesRaw) {
    if (filesRaw is! List) return [];

    final result = <_SubmissionFileItem>[];

    for (final item in filesRaw) {
      if (item is String) {
        final cleanUrl = item.trim();
        if (cleanUrl.isNotEmpty) {
          result.add(
            _SubmissionFileItem(
              name: _extractFileNameFromUrl(cleanUrl),
              url: cleanUrl,
            ),
          );
        }
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item);

        final url = (map['fileUrl'] ??
            map['url'] ??
            map['downloadUrl'] ??
            '')
            .toString()
            .trim();

        if (url.isEmpty) continue;

        final name = (map['fileName'] ??
            map['name'] ??
            _extractFileNameFromUrl(url))
            .toString()
            .trim();

        result.add(
          _SubmissionFileItem(
            name: name.isEmpty ? 'File' : name,
            url: url,
          ),
        );
      }
    }

    return result;
  }

  String _extractFileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) return 'File';
    return uri.pathSegments.last;
  }

  Future<bool> _confirmDialog({
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _requestRevision({
    required String submissionId,
    required String freelancerId,
    required String jobId,
  }) async {
    if (_processing) return;

    final confirmed = await _confirmDialog(
      title: 'Request Revision',
      message: 'Are you sure you want to request a revision for this submission?',
      confirmText: 'Request Revision',
      confirmColor: AppColors.warning,
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      final now = Timestamp.now();
      final notifRef = _db.collection('notifications').doc();

      final batch = _db.batch();

      batch.update(_db.collection('submissions').doc(submissionId), {
        'status': 'revision_requested',
        'updatedAt': now,
      });

      batch.update(_db.collection('contracts').doc(widget.contractId), {
        'status': 'revision_requested',
        'updatedAt': now,
      });

      batch.set(notifRef, {
        'notifId': notifRef.id,
        'recipientId': freelancerId,
        'type': 'revision_requested',
        'title': 'Revision Requested',
        'body': 'The client requested a revision for your submitted work.',
        'refType': 'contract',
        'refId': widget.contractId,
        'isRead': false,
        'createdAt': now,
      });

      await batch.commit();

      if (!mounted) return;

      _showSnackBar('Revision requested successfully', AppColors.success);

      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Failed to request revision', AppColors.error);
    }

    if (mounted) {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> _acceptAndMoveToPayment({
    required String submissionId,
    required String freelancerId,
    required String jobId,
    required dynamic amount,
    required String currency,
  }) async {
    if (_processing) return;

    final confirmed = await _confirmDialog(
      title: 'Accept Work',
      message: 'Are you sure you want to accept this submission and move to payment?',
      confirmText: 'Accept Work',
      confirmColor: AppColors.success,
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      final now = Timestamp.now();
      final notifRef = _db.collection('notifications').doc();

      final batch = _db.batch();

      batch.update(_db.collection('submissions').doc(submissionId), {
        'status': 'accepted',
        'updatedAt': now,
      });

      batch.update(_db.collection('contracts').doc(widget.contractId), {
        'updatedAt': now,
      });

      batch.set(notifRef, {
        'notifId': notifRef.id,
        'recipientId': freelancerId,
        'type': 'submission_accepted',
        'title': 'Work Accepted',
        'body': 'The client accepted your submitted work and is proceeding to payment.',
        'refType': 'contract',
        'refId': widget.contractId,
        'isRead': false,
        'createdAt': now,
      });

      await batch.commit();

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientMakePaymentScreen(
            contractId: widget.contractId,
            jobId: jobId,
            freelancerId: freelancerId,
            amount: _toDouble(amount),
            currency: currency,
          ),
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Failed to accept submission', AppColors.error);
    }

    if (mounted) {
      setState(() {
        _processing = false;
      });
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
          title: const Text(
            'Submission Review',
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
          future: _loadData(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(child: SizedBox(height: 140, child: _SoftLoadingBox())),
                  SizedBox(height: 14),
                  _GlassCard(child: SizedBox(height: 260, child: _SoftLoadingBox())),
                ],
              );
            }

            final contract = snap.data![0] as Map<String, dynamic>?;
            final submissionDoc = snap.data![1] as QueryDocumentSnapshot<Map<String, dynamic>>?;

            if (contract == null || submissionDoc == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.upload_file_outlined,
                      title: 'No submission found',
                      subtitle: 'The freelancer has not submitted any work yet.',
                    ),
                  ),
                ],
              );
            }

            final submission = submissionDoc.data();
            final submissionId = submissionDoc.id;

            final note = (submission['note'] ?? '').toString().trim();
            final files = _extractFiles(submission['files']);
            final submissionStatus = (submission['status'] ?? '').toString().trim();

            final freelancerId = (contract['freelancerId'] ?? '').toString();
            final jobId = (contract['jobId'] ?? '').toString();
            final amount = contract['agreedPrice'];
            final currency = (contract['currency'] ?? 'SAR').toString();

            final canReview = submissionStatus == 'submitted';

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submission Status',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _SubmissionStatusChip(status: submissionStatus),
                        ],
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
                        'Submission Note',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        note.isEmpty ? 'No note provided.' : note,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
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
                        'Uploaded Files',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (files.isEmpty)
                        const Text(
                          'No uploaded files found.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Column(
                          children: files
                              .map(
                                (file) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FileTile(
                                fileName: file.name,
                                onOpen: () => _openFile(file.url),
                              ),
                            ),
                          )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (canReview) ...[
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _processing
                          ? null
                          : () => _acceptAndMoveToPayment(
                        submissionId: submissionId,
                        freelancerId: freelancerId,
                        jobId: jobId,
                        amount: amount,
                        currency: currency,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.success.withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text(
                        'Accept Work & Continue to Payment',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _processing
                          ? null
                          : () => _requestRevision(
                        submissionId: submissionId,
                        freelancerId: freelancerId,
                        jobId: jobId,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Request Revision',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ] else
                  const _GlassCard(
                    child: _EmptyState(
                      icon: Icons.info_outline_rounded,
                      title: 'This submission is not awaiting review',
                      subtitle: 'Only submissions with status SUBMITTED can be reviewed here.',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _SubmissionFileItem {
  final String name;
  final String url;

  const _SubmissionFileItem({
    required this.name,
    required this.url,
  });
}

class _FileTile extends StatelessWidget {
  final String fileName;
  final VoidCallback onOpen;

  const _FileTile({
    required this.fileName,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.attach_file_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onOpen,
            child: const Text(
              'Open',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionStatusChip extends StatelessWidget {
  final String status;

  const _SubmissionStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();

    late final Color bg;
    late final Color fg;

    if (s == 'submitted') {
      bg = AppColors.accent.withOpacity(0.14);
      fg = AppColors.accent;
    } else if (s == 'accepted') {
      bg = AppColors.success.withOpacity(0.14);
      fg = AppColors.success;
    } else if (s == 'revision_requested') {
      bg = AppColors.warning.withOpacity(0.14);
      fg = AppColors.warning;
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
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}