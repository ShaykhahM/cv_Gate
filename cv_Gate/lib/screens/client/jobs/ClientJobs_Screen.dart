import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/jobs/JobDetails_Screen.dart';
import 'package:cv_gate/screens/client/jobs/PostJob_Screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientJobsListScreen extends StatefulWidget {
  const ClientJobsListScreen({super.key});

  @override
  State<ClientJobsListScreen> createState() => _ClientJobsListScreenState();
}

class _ClientJobsListScreenState extends State<ClientJobsListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid =clientId;

  String _statusFilter = 'all';

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _db
        .collection('jobs')
        .where('clientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);

    if (_statusFilter != 'all') {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return query;
  }

  Future<void> _openCreateJob() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientPostNewJobScreen(),
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
            'My Jobs',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateJob,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Post Job',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Your Jobs',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Track all posted jobs and filter them by status',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _FilterChipItem(
                            label: 'All',
                            value: 'all',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Open',
                            value: 'open',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Closed',
                            value: 'closed',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Contracted',
                            value: 'contracted',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Cancelled',
                            value: 'cancelled',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _buildQuery().snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: _GlassCard(
                        child: _EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Failed to load jobs',
                          subtitle: 'Please try again later.',
                        ),
                      ),
                    );
                  }

                  if (!snap.hasData) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, __) => const _JobCardSkeleton(),
                    );
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: [
                        const SizedBox(height: 8),
                        const _GlassCard(
                          child: _EmptyState(
                            icon: Icons.work_outline_rounded,
                            title: 'No jobs found',
                            subtitle: 'Create your first job post to start receiving applications.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _openCreateJob,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text(
                              'Post New Job',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        return _JobCard(data: data);
                      },
                    ),
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


class _JobCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _JobCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Untitled Job').toString().trim();
    final category = (data['category'] ?? '').toString().trim();
    final currency = (data['currency'] ?? '').toString().trim();
    final budget = data['budget'];
    final durationDays = data['durationDays'];
    final status = (data['status'] ?? 'open').toString().trim();
    final createdAt = data['createdAt'];

    final budgetText = _formatBudget(budget, currency);
    final durationText = _formatDuration(durationDays);

    return InkWell(
      onTap: ()
      {
        GoToScreen(context: context, screen: ClientJobDetailsScreen(jobId: data['jobId'],));
      },
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.isEmpty ? 'Untitled Job' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (category.isNotEmpty)
                  _InfoChip(
                    icon: Icons.category_outlined,
                    text: category,
                  ),
                if (budgetText.isNotEmpty)
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    text: budgetText,
                  ),
                if (durationText.isNotEmpty)
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    text: durationText,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _dateLabel(createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBudget(dynamic budget, String currency) {
    if (budget == null) return '';
    if (budget is int) return '$budget $currency';
    if (budget is double) {
      if (budget == budget.roundToDouble()) {
        return '${budget.toInt()} $currency';
      }
      return '${budget.toStringAsFixed(2)} $currency';
    }
    final parsed = double.tryParse(budget.toString());
    if (parsed == null) return '';
    if (parsed == parsed.roundToDouble()) {
      return '${parsed.toInt()} $currency';
    }
    return '${parsed.toStringAsFixed(2)} $currency';
  }

  static String _formatDuration(dynamic duration) {
    if (duration == null) return '';
    if (duration is int) return '$duration days';
    final parsed = int.tryParse(duration.toString());
    if (parsed == null) return '';
    return '$parsed days';
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final String value;
  final String currentValue;
  final ValueChanged<String> onSelected;

  const _FilterChipItem({
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


class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

class _JobCardSkeleton extends StatelessWidget {
  const _JobCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _GlassCard(
      child: SizedBox(
        height: 110,
        child: _SoftLoadingBox(),
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
          Icon(
            icon,
            size: 34,
            color: AppColors.textSecondary,
          ),
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