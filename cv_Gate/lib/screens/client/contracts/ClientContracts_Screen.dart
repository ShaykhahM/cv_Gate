import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/contracts/ClientGenerateContract_Screen.dart';
import 'package:cv_gate/screens/client/contracts/client_contract_details_screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientContractsListScreen extends StatefulWidget {
  const ClientContractsListScreen({super.key});

  @override
  State<ClientContractsListScreen> createState() => _ClientContractsListScreenState();
}

class _ClientContractsListScreenState extends State<ClientContractsListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = clientId;

  String _statusFilter = 'all';

  final Map<String, String> _userNameCache = {};
  final Map<String, String> _jobTitleCache = {};

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _db
        .collection('contracts')
        .where('clientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);

    if (_statusFilter != 'all') {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return query;
  }

  Future<String> _getUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      final name = (data['fullName'] ?? '').toString().trim();
      _userNameCache[uid] = name.isEmpty ? 'Freelancer' : name;
      return _userNameCache[uid]!;
    } catch (_) {
      return 'Freelancer';
    }
  }

  Future<String> _getJobTitle(String jobId) async {
    if (_jobTitleCache.containsKey(jobId)) return _jobTitleCache[jobId]!;
    try {
      final snap = await _db.collection('jobs').doc(jobId).get();
      final data = snap.data() ?? {};
      final title = (data['title'] ?? '').toString().trim();
      _jobTitleCache[jobId] = title.isEmpty ? 'Job' : title;
      return _jobTitleCache[jobId]!;
    } catch (_) {
      return 'Job';
    }
  }

  Future<void> _openDetails(String contractId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientContractDetailsScreen(contractId: contractId),
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
            'Contracts',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          // leading: IconButton(
          //     onPressed: ()
          //     {
          //     GoToScreen(
          //         context: context,
          //         screen: ClientGenerateContractScreen(
          //           applicationId: 'GFaL7qCUlE0izZmajpef',
          //           jobId: 'e3kOMmGn6p2D8UWqBZoB',
          //           freelancerId: 'O8zKa7nMUYOOIiBCctDTyTy6qvt1',));
          //     },
          //     icon: Icon(Icons.account_circle)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Track All Contracts',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Filter contracts by current status',
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
                            label: 'Draft',
                            value: 'draft',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Active',
                            value: 'active',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Submitted',
                            value: 'submitted',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Completed',
                            value: 'completed',
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
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Disputed',
                            value: 'disputed',
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
                          title: 'Failed to load contracts',
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
                        child: SizedBox(height: 128, child: _SoftLoadingBox()),
                      ),
                    );
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: const [
                        _GlassCard(
                          child: _EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'No contracts found',
                            subtitle: 'Contracts will appear here after generating agreements.',
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      final freelancerId = (data['freelancerId'] ?? '').toString();
                      final jobId = (data['jobId'] ?? '').toString();

                      return FutureBuilder<List<String>>(
                        future: Future.wait([
                          _getUserName(freelancerId),
                          _getJobTitle(jobId),
                        ]),
                        builder: (context, infoSnap) {
                          final freelancerName = infoSnap.data?[0] ?? 'Loading...';
                          final jobTitle = infoSnap.data?[1] ?? 'Loading...';

                          return _ContractCard(
                            freelancerName: freelancerName,
                            jobTitle: jobTitle,
                            agreedPrice: data['agreedPrice'],
                            currency: (data['currency'] ?? '').toString(),
                            durationDays: data['agreedDurationDays'],
                            status: (data['status'] ?? '').toString(),
                            onTap: () => _openDetails(doc.id),
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

class _ContractCard extends StatelessWidget {
  final String freelancerName;
  final String jobTitle;
  final dynamic agreedPrice;
  final String currency;
  final dynamic durationDays;
  final String status;
  final VoidCallback onTap;

  const _ContractCard({
    required this.freelancerName,
    required this.jobTitle,
    required this.agreedPrice,
    required this.currency,
    required this.durationDays,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = _formatBudget(agreedPrice, currency);
    final durationText = _formatDuration(durationDays);

    return _GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    jobTitle.isEmpty ? 'Job' : jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Freelancer', value: freelancerName),
            const SizedBox(height: 10),
            _InfoRow(label: 'Agreed Price', value: priceText),
            const SizedBox(height: 10),
            _InfoRow(label: 'Duration', value: durationText),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Open Details',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
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
          width: 108,
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

  const _StatusChip({required this.status});

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