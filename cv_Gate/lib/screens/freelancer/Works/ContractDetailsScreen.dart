import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:cv_gate/screens/freelancer/Works/SubmitCompletedWorkScreen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';



class ContractDetailsScreen extends StatefulWidget {
  final String contractId;
  final String freelancerId;

  const ContractDetailsScreen({
    super.key,
    required this.contractId,
    required this.freelancerId,
  });

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openPdf(String url) async {
    try {
      if (url.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF contract link is not available.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open PDF contract.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('ContractDetailsScreen _openPdf error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open PDF contract.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openSubmitWork() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitCompletedWorkScreen(
          contractId: widget.contractId,
          freelancerId: widget.freelancerId,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
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
            'Contract Details',
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
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _db.collection('contracts').doc(widget.contractId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('ContractDetailsScreen error: ${snapshot.error}');
            return _ErrorState(onRetry: _refresh);
          }

          if (!snapshot.hasData) {
            return const _LoadingView();
          }

          if (!snapshot.data!.exists) {
            return const _NotFoundState();
          }

          final contractData = snapshot.data!.data() ?? {};
          final jobId = (contractData['jobId'] ?? '').toString().trim();
          final agreedPrice = contractData['agreedPrice'];
          final currency = (contractData['currency'] ?? 'SAR').toString().trim();
          final agreedDuration =
          (contractData['agreedDurationDays'] ?? '-').toString();
          final status = (contractData['status'] ?? 'draft').toString().trim();
          final pdfUrl = (contractData['pdfUrl'] ?? '').toString().trim();
          final acceptedAt = contractData['acceptedAt'];
          final createdAt = contractData['createdAt'];
          final updatedAt = contractData['updatedAt'];

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: jobId.isEmpty ? Future.value(null) : _db.collection('jobs').doc(jobId).get(),
            builder: (context, jobSnapshot) {
              final jobData = jobSnapshot.data?.data() ?? {};
              final jobTitle = (jobData['title'] ?? 'Unknown Job').toString().trim();
              final jobCategory = (jobData['category'] ?? 'General').toString().trim();
              final jobDescription = (jobData['description'] ?? '').toString().trim();

              final canSubmitWork = status.toLowerCase() == 'active' ||  status.toLowerCase() == 'revision_requested';


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
                          jobTitle: jobTitle,
                          category: jobCategory,
                          agreedPrice: '$agreedPrice $currency',
                          duration: '$agreedDuration days',
                          status: status,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Contract Information',
                          subtitle: 'Main details about this agreement',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.badge_outlined,
                                title: 'Contract ID',
                                value: widget.contractId,
                                tint: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.work_outline_rounded,
                                title: 'Job Title',
                                value: jobTitle,
                                tint: AppColors.info,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.payments_outlined,
                                title: 'Agreed Price',
                                value: '$agreedPrice $currency',
                                tint: AppColors.warning,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.schedule_outlined,
                                title: 'Duration',
                                value: '$agreedDuration days',
                                tint: AppColors.success,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.flag_outlined,
                                title: 'Status',
                                valueWidget: _ContractStatusChip(status: status),
                                tint: AppColors.primary,
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
                          title: 'Work Progress',
                          subtitle: 'Current stage and important timestamps',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.category_outlined,
                                title: 'Job Category',
                                value: jobCategory,
                                tint: AppColors.info,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.event_available_outlined,
                                title: 'Accepted At',
                                value: _formatTimestamp(acceptedAt),
                                tint: AppColors.success,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                title: 'Created At',
                                value: _formatTimestamp(createdAt),
                                tint: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.update_outlined,
                                title: 'Updated At',
                                value: _formatTimestamp(updatedAt),
                                tint: AppColors.warning,
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
                          title: 'Job Description',
                          subtitle: 'Related job information for this contract',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Text(
                            jobDescription.isEmpty
                                ? 'No job description available.'
                                : jobDescription,
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
                          title: 'Contract PDF',
                          subtitle: 'Open the official contract file',
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
                              Text(
                                pdfUrl.isEmpty
                                    ? 'No PDF file available.'
                                    : pdfUrl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                                    gradient: pdfUrl.isEmpty
                                        ? null
                                        : AppColors.primaryGradient,
                                    color: pdfUrl.isEmpty
                                        ? AppColors.textLight.withOpacity(0.18)
                                        : null,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: pdfUrl.isEmpty ? null : () => _openPdf(pdfUrl),
                                    icon: Icon(
                                      Icons.picture_as_pdf_outlined,
                                      color: pdfUrl.isEmpty
                                          ? AppColors.textSecondary
                                          : Colors.white,
                                    ),
                                    label: Text(
                                      'Open PDF Contract',
                                      style: TextStyle(
                                        color: pdfUrl.isEmpty
                                            ? AppColors.textSecondary
                                            : Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
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
                                  ),
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
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Next Action',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                canSubmitWork
                                    ? 'This contract is active. You can submit your completed work now.'
                                    : 'Submit Completed Work becomes available when the contract status is active.',
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
                                    gradient: canSubmitWork
                                        ? AppColors.primaryGradient
                                        : null,
                                    color: canSubmitWork
                                        ? null
                                        : AppColors.textLight.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: canSubmitWork ? _openSubmitWork : null,
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
                                    child: Text(
                                      'Submit Completed Work',
                                      style: TextStyle(
                                        color: canSubmitWork
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return 'Not available';
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _two(int value) => value < 10 ? '0$value' : '$value';
}

class _HeaderCard extends StatelessWidget {
  final String jobTitle;
  final String category;
  final String agreedPrice;
  final String duration;
  final String status;

  const _HeaderCard({
    required this.jobTitle,
    required this.category,
    required this.agreedPrice,
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
                  Icons.description_outlined,
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
                      jobTitle,
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
                        _ContractStatusChip(status: status),
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
                  label: 'Agreed Price',
                  value: agreedPrice,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? valueWidget;
  final Color tint;

  const _InfoRow({
    required this.icon,
    required this.title,
    this.value,
    this.valueWidget,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: tint,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              valueWidget ??
                  Text(
                    value ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContractStatusChip extends StatelessWidget {
  final String status;

  const _ContractStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    Color bg;
    Color fg;
    String label;

    if (s == 'draft') {
      bg = AppColors.textLight.withOpacity(0.18);
      fg = AppColors.textSecondary;
      label = 'Draft';
    } else if (s == 'active') {
      bg = AppColors.success.withOpacity(0.12);
      fg = AppColors.success;
      label = 'Active';
    } else if (s == 'submitted') {
      bg = AppColors.info.withOpacity(0.12);
      fg = AppColors.info;
      label = 'Submitted';
    } else if (s == 'completed') {
      bg = AppColors.primary.withOpacity(0.12);
      fg = AppColors.primary;
      label = 'Completed';
    } else if (s == 'cancelled') {
      bg = AppColors.error.withOpacity(0.12);
      fg = AppColors.error;
      label = 'Cancelled';
    } else if (s == 'disputed') {
      bg = AppColors.warning.withOpacity(0.12);
      fg = AppColors.warning;
      label = 'Disputed';
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
          child: SizedBox(height: 220, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 150, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 130, child: _SoftLoadingBox()),
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
              'Contract not found.',
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
              'Failed to load contract details.',
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