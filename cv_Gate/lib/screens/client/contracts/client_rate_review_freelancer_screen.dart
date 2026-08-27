import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:flutter/material.dart';

class ClientRateReviewFreelancerScreen extends StatefulWidget {
  final String contractId;
  final String jobId;
  final String freelancerId;
  final String freelancerName;

  const ClientRateReviewFreelancerScreen({
    super.key,
    required this.contractId,
    required this.jobId,
    required this.freelancerId,
    required this.freelancerName,
  });

  @override
  State<ClientRateReviewFreelancerScreen> createState() => _ClientRateReviewFreelancerScreenState();
}

class _ClientRateReviewFreelancerScreenState extends State<ClientRateReviewFreelancerScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _commentController = TextEditingController();

  double _rating = 5;
  bool _saving = false;
  bool _checking = true;
  bool _canReview = false;

  @override
  void initState() {
    super.initState();
    _checkContractStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkContractStatus() async {
    try {
      final snap = await _db.collection('contracts').doc(widget.contractId).get();
      final status = (snap.data()?['status'] ?? '').toString().trim();

      if (!mounted) return;
      setState(() {
        _canReview = status == 'completed';
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_saving || !_canReview) return;

    final comment = _commentController.text.trim();

    setState(() {
      _saving = true;
    });

    try {
      final freelancerRef = _db.collection('users').doc(widget.freelancerId);
      final freelancerSnap = await freelancerRef.get();
      final freelancerData = freelancerSnap.data() ?? {};

      final oldAvg = _toDouble(freelancerData['ratingAvg']);
      final oldCount = _toInt(freelancerData['ratingCount']);

      final newCount = oldCount + 1;
      final newAvg = ((oldAvg * oldCount) + _rating) / newCount;

      final reviewRef = _db.collection('reviews').doc();
      final notifRef = _db.collection('notifications').doc();

      final batch = _db.batch();

      batch.set(reviewRef, {
        'reviewId': reviewRef.id,
        'contractId': widget.contractId,
        'jobId': widget.jobId,
        'fromUserId': '',
        'toUserId': widget.freelancerId,
        'rating': _rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      batch.update(freelancerRef, {
        'ratingAvg': newAvg,
        'ratingCount': newCount,
      });

      batch.set(notifRef, {
        'notifId': notifRef.id,
        'recipientId': widget.freelancerId,
        'type': 'new_review',
        'title': 'New Review Received',
        'body': 'The client submitted a new review for your completed contract.',
        'refType': 'review',
        'refId': reviewRef.id,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Review submitted successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit review'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text(
              'Rate Freelancer',
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
          title: const Text(
            'Rate Freelancer',
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
        child: !_canReview
            ? ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: const [
            _GlassCard(
              child: _EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Review is not available',
                subtitle: 'You can submit a review only after the contract becomes COMPLETED.',
              ),
            ),
          ],
        )
            : ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Freelancer',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.freelancerName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
                    'Rating',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Wrap(
                      spacing: 6,
                      children: List.generate(
                        5,
                            (index) {
                          final value = index + 1;
                          return InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              setState(() {
                                _rating = value.toDouble();
                              });
                            },
                            child: Icon(
                              value <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: AppColors.warning,
                              size: 34,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
                    'Comment',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your feedback',
                      hintStyle: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.rate_review_outlined),
                label: Text(
                  _saving ? 'Submitting...' : 'Submit Review',
                  style: const TextStyle(
                    fontSize: 15,
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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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