import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/payments/client_payment_details_screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientPaymentsListScreen extends StatefulWidget {
  const ClientPaymentsListScreen({super.key});

  @override
  State<ClientPaymentsListScreen> createState() => _ClientPaymentsListScreenState();
}

class _ClientPaymentsListScreenState extends State<ClientPaymentsListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = clientId;

  String _statusFilter = 'all';

  final Map<String, String> _contractCache = {};
  final Map<String, String> _jobCache = {};

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _db
        .collection('payments')
        .where('clientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);

    if (_statusFilter != 'all') {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return query;
  }

  Future<String> _getContractTitle(String contractId) async {
    if (_contractCache.containsKey(contractId)) return _contractCache[contractId]!;
    try {
      final snap = await _db.collection('contracts').doc(contractId).get();
      final data = snap.data() ?? {};
      final id = (data['contractId'] ?? contractId).toString();
      _contractCache[contractId] = id;
      return id;
    } catch (_) {
      return contractId;
    }
  }

  Future<String> _getJobTitle(String jobId) async {
    if (_jobCache.containsKey(jobId)) return _jobCache[jobId]!;
    try {
      final snap = await _db.collection('jobs').doc(jobId).get();
      final data = snap.data() ?? {};
      final title = (data['title'] ?? 'Job').toString();
      _jobCache[jobId] = title;
      return title;
    } catch (_) {
      return 'Job';
    }
  }

  Future<void> _openDetails(String paymentId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientPaymentDetailsScreen(paymentId: paymentId),
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
            'Payments',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Track All Payments',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Filter payments by current status',
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
                            label: 'Initiated',
                            value: 'initiated',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Pending',
                            value: 'pending',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Success',
                            value: 'success',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Failed',
                            value: 'failed',
                            currentValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipItem(
                            label: 'Refunded',
                            value: 'refunded',
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
                          title: 'Failed to load payments',
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
                        child: SizedBox(height: 130, child: _SoftLoadingBox()),
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
                            icon: Icons.payments_outlined,
                            title: 'No payments found',
                            subtitle: 'Payments will appear here after contract payment starts.',
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

                      final contractId = (data['contractId'] ?? '').toString();
                      final jobId = (data['jobId'] ?? '').toString();

                      return FutureBuilder<List<String>>(
                        future: Future.wait([
                          _getContractTitle(contractId),
                          _getJobTitle(jobId),
                        ]),
                        builder: (context, infoSnap) {
                          final contractLabel = infoSnap.data?[0] ?? 'Loading...';
                          final jobTitle = infoSnap.data?[1] ?? 'Loading...';

                          return _PaymentCard(
                            amount: data['amount'],
                            currency: (data['currency'] ?? '').toString(),
                            method: (data['method'] ?? '').toString(),
                            status: (data['status'] ?? '').toString(),
                            contractLabel: contractLabel,
                            jobTitle: jobTitle,
                            createdAt: data['createdAt'],
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

class _PaymentCard extends StatelessWidget {
  final dynamic amount;
  final String currency;
  final String method;
  final String status;
  final String contractLabel;
  final String jobTitle;
  final dynamic createdAt;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.contractLabel,
    required this.jobTitle,
    required this.createdAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = _formatAmount(amount, currency);
    final methodText = _prettyMethod(method);

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
                    jobTitle,
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
                _PaymentStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Amount', value: amountText),
            const SizedBox(height: 10),
            _InfoRow(label: 'Method', value: methodText),
            const SizedBox(height: 10),
            _InfoRow(label: 'Contract', value: contractLabel),
            const SizedBox(height: 10),
            _InfoRow(label: 'Date', value: _dateLabel(createdAt)),
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

  static String _prettyMethod(String method) {
    if (method == 'card_sim') return 'Card';
    if (method == 'stc_sim') return 'STC Pay';
    if (method == 'bank_sim') return 'Bank Transfer';
    return method;
  }

  static String _formatAmount(dynamic amount, String currency) {
    if (amount == null) return 'Not specified';
    if (amount is int) return '$amount $currency';
    if (amount is double) {
      if (amount == amount.roundToDouble()) return '${amount.toInt()} $currency';
      return '${amount.toStringAsFixed(2)} $currency';
    }
    final parsed = double.tryParse(amount.toString());
    if (parsed == null) return 'Not specified';
    if (parsed == parsed.roundToDouble()) return '${parsed.toInt()} $currency';
    return '${parsed.toStringAsFixed(2)} $currency';
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
          width: 88,
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

class _PaymentStatusChip extends StatelessWidget {
  final String status;

  const _PaymentStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();

    late final Color bg;
    late final Color fg;

    if (s == 'initiated') {
      bg = AppColors.warning.withOpacity(0.14);
      fg = AppColors.warning;
    } else if (s == 'pending') {
      bg = AppColors.accent.withOpacity(0.14);
      fg = AppColors.accent;
    } else if (s == 'success') {
      bg = AppColors.success.withOpacity(0.14);
      fg = AppColors.success;
    } else if (s == 'failed') {
      bg = AppColors.error.withOpacity(0.14);
      fg = AppColors.error;
    } else if (s == 'refunded') {
      bg = const Color(0xFF7C3AED).withOpacity(0.14);
      fg = const Color(0xFF7C3AED);
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

String _dateLabel(dynamic value) {
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }
  return 'Recently';
}

String _two(int v) => v < 10 ? '0$v' : '$v';