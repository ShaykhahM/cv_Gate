import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/contracts/client_contract_pdf_preview_screen.dart';
import 'package:cv_gate/screens/client/contracts/client_rate_review_freelancer_screen.dart';
import 'package:cv_gate/screens/client/contracts/client_submission_review_screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:flutter/material.dart';

class ClientContractDetailsScreen extends StatefulWidget {
  final String contractId;

  const ClientContractDetailsScreen({
    super.key,
    required this.contractId,
  });

  @override
  State<ClientContractDetailsScreen> createState() => _ClientContractDetailsScreenState();
}

class _ClientContractDetailsScreenState extends State<ClientContractDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _loadContract() async {
    final snap = await _db.collection('contracts').doc(widget.contractId).get();
    return snap.data() ?? {};
  }

  Future<Map<String, dynamic>> _loadJob(String jobId) async {
    final snap = await _db.collection('jobs').doc(jobId).get();
    return snap.data() ?? {};
  }

  Future<Map<String, dynamic>> _loadUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data() ?? {};
  }

  Future<Map<String, dynamic>?> _loadLatestSubmission(String contractId) async {
    final snap = await _db
        .collection('submissions')
        .where('contractId', isEqualTo: contractId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  Future<List<dynamic>> _loadAll() async {
    final contract = await _loadContract();
    final jobId = (contract['jobId'] ?? '').toString();
    final freelancerId = (contract['freelancerId'] ?? '').toString();

    return Future.wait([
      Future.value(contract),
      _loadJob(jobId),
      _loadUser(freelancerId),
      _loadLatestSubmission(widget.contractId),
    ]);
  }

  Future<void> _openSubmissionReview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientSubmissionReviewScreen(contractId: widget.contractId),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openRateReview(String freelancerId, String jobId,String freelancerMame) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientRateReviewFreelancerScreen(
          contractId: widget.contractId,
          freelancerId: freelancerId,
          jobId: jobId,
          freelancerName: freelancerMame,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openPdfPreview({
    required Map<String, dynamic> contract,
    required Map<String, dynamic> job,
    required Map<String, dynamic> freelancer,
  }) async {
    final agreedPrice = _toDouble(contract['agreedPrice']);
    final currency = (contract['currency'] ?? 'SAR').toString();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientContractPdfPreviewScreen(
          contractId: widget.contractId,
        ),
      ),
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
            'Contract Details',
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
          future: _loadAll(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(child: SizedBox(height: 150, child: _SoftLoadingBox())),
                  SizedBox(height: 14),
                  _GlassCard(child: SizedBox(height: 220, child: _SoftLoadingBox())),
                  SizedBox(height: 14),
                  _GlassCard(child: SizedBox(height: 170, child: _SoftLoadingBox())),
                ],
              );
            }

            final contract = snap.data![0] as Map<String, dynamic>;
            final job = snap.data![1] as Map<String, dynamic>;
            final freelancer = snap.data![2] as Map<String, dynamic>;
            final submission = snap.data![3] as Map<String, dynamic>?;

            if (contract.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'Contract not found',
                      subtitle: 'This contract does not exist or was removed.',
                    ),
                  ),
                ],
              );
            }

            final freelancerId = (contract['freelancerId'] ?? '').toString();
            final jobId = (contract['jobId'] ?? '').toString();
            final status = (contract['status'] ?? '').toString();
            final pdfUrl = (contract['pdfUrl'] ?? '').toString();

            final freelancerName = (freelancer['fullName'] ?? 'Freelancer').toString();
            final freelancerEmail = (freelancer['email'] ?? '').toString();
            final jobTitle = (job['title'] ?? 'Project').toString();
            final jobCategory = (job['category'] ?? '').toString();
            final jobDescription = (job['description'] ?? '').toString();
            final agreedPrice = _formatBudget(contract['agreedPrice'], (contract['currency'] ?? 'SAR').toString());
            final agreedDuration = _formatDuration(contract['agreedDurationDays']);
            final submissionStatus = submission == null ? '' : (submission['status'] ?? '').toString();

            final canOpenSubmission = status == 'submitted' || submissionStatus == 'submitted' || submissionStatus == 'revision_requested';
            final canLeaveReview = status == 'completed';

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
                              jobTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(label: 'Contract ID', value: widget.contractId),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Agreed Price', value: agreedPrice),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Agreed Duration', value: agreedDuration),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Created Date', value: _dateLabel(contract['createdAt'])),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Updated Date', value: _dateLabel(contract['updatedAt'])),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job Details',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Job Title', value: jobTitle),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Category', value: jobCategory.isEmpty ? 'Not specified' : jobCategory),
                      const SizedBox(height: 10),
                      _SectionText(
                        label: 'Description',
                        value: jobDescription.isEmpty ? 'No description available.' : jobDescription,
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
                        'Freelancer Info',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Name', value: freelancerName),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Email', value: freelancerEmail.isEmpty ? 'Not available' : freelancerEmail),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (submission != null)
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
                        _InfoRow(
                          label: 'Current Submission',
                          value: submissionStatus.isEmpty ? 'Unknown' : submissionStatus.replaceAll('_', ' ').toUpperCase(),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          label: 'Submitted Date',
                          value: _dateLabel(submission['createdAt']),
                        ),
                      ],
                    ),
                  ),
                if (submission != null) const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openPdfPreview(
                            contract: contract,
                            job: job,
                            freelancer: freelancer,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(
                            pdfUrl.isEmpty ? 'Open PDF Preview' : 'Open Saved PDF',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canOpenSubmission ? _openSubmissionReview : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text(
                            'Open Submission Review',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canLeaveReview
                              ? () => _openRateReview(freelancerId, jobId,freelancerName)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF7C3AED).withOpacity(0.45),
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.star_outline_rounded),
                          label: const Text(
                            'Leave Review',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
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

class _SectionText extends StatelessWidget {
  final String label;
  final String value;

  const _SectionText({
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
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12.8,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
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
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
    final s = status.trim().toLowerCase();

    late final Color bg;
    late final Color fg;

    if (s == 'draft') {
      bg = AppColors.warning.withOpacity(0.14);
      fg = AppColors.warning;
    } else if (s == 'active') {
      bg = AppColors.success.withOpacity(0.14);
      fg = AppColors.success;
    } else if (s == 'submitted') {
      bg = AppColors.accent.withOpacity(0.14);
      fg = AppColors.accent;
    } else if (s == 'completed') {
      bg = const Color(0xFF7C3AED).withOpacity(0.14);
      fg = const Color(0xFF7C3AED);
    } else if (s == 'cancelled') {
      bg = AppColors.error.withOpacity(0.14);
      fg = AppColors.error;
    } else if (s == 'disputed') {
      bg = const Color(0xFF92400E).withOpacity(0.14);
      fg = const Color(0xFF92400E);
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
      child: Container(color: Colors.black.withOpacity(0.03)),
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

String _dateLabel(dynamic value) {
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }
  return 'Recently';
}

String _two(int v) => v < 10 ? '0$v' : '$v';