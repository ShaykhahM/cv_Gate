import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:flutter/material.dart';

class ClientPaymentDetailsScreen extends StatefulWidget {
  final String paymentId;

  const ClientPaymentDetailsScreen({
    super.key,
    required this.paymentId,
  });

  @override
  State<ClientPaymentDetailsScreen> createState() => _ClientPaymentDetailsScreenState();
}

class _ClientPaymentDetailsScreenState extends State<ClientPaymentDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _loadPayment() async {
    final snap = await _db.collection('payments').doc(widget.paymentId).get();
    return snap.data();
  }

  Future<Map<String, dynamic>?> _loadContract(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    return snap.data();
  }

  Future<Map<String, dynamic>?> _loadJob(String jobId) async {
    final snap = await _db.collection('jobs').doc(jobId).get();
    return snap.data();
  }

  Future<Map<String, dynamic>?> _loadFreelancer(String freelancerId) async {
    final snap = await _db.collection('users').doc(freelancerId).get();
    return snap.data();
  }

  Future<List<dynamic>> _loadAllData() async {
    final payment = await _loadPayment();
    if (payment == null) {
      return [null, null, null, null];
    }

    final contractId = (payment['contractId'] ?? '').toString();
    final jobId = (payment['jobId'] ?? '').toString();
    final freelancerId = (payment['freelancerId'] ?? '').toString();

    return Future.wait([
      Future.value(payment),
      _loadContract(contractId),
      _loadJob(jobId),
      _loadFreelancer(freelancerId),
    ]);
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
            'Payment Details',
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
                  _GlassCard(child: SizedBox(height: 140, child: _SoftLoadingBox())),
                  SizedBox(height: 14),
                  _GlassCard(child: SizedBox(height: 240, child: _SoftLoadingBox())),
                ],
              );
            }

            final payment = snap.data![0] as Map<String, dynamic>?;
            final contract = snap.data![1] as Map<String, dynamic>?;
            final job = snap.data![2] as Map<String, dynamic>?;
            final freelancer = snap.data![3] as Map<String, dynamic>?;

            if (payment == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'Payment not found',
                      subtitle: 'This payment does not exist or was removed.',
                    ),
                  ),
                ],
              );
            }

            final amountText = _formatAmount(payment['amount'], (payment['currency'] ?? '').toString());
            final methodText = _prettyMethod((payment['method'] ?? '').toString());
            final status = (payment['status'] ?? '').toString();
            final receiptRef = (payment['receiptRef'] ?? '').toString();
            final createdAt = payment['createdAt'];

            final contractLabel = (contract?['contractId'] ?? payment['contractId'] ?? '').toString();
            final contractStatus = (contract?['status'] ?? '').toString();
            final jobTitle = (job?['title'] ?? 'Job').toString();
            final freelancerName = (freelancer?['fullName'] ?? 'Freelancer').toString();
            final freelancerEmail = (freelancer?['email'] ?? '').toString();

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Amount', value: amountText),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Currency', value: (payment['currency'] ?? '').toString()),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Method', value: methodText),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 108,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _PaymentStatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Receipt Ref',
                        value: receiptRef.isEmpty ? 'Not available' : receiptRef,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Date', value: _dateLabel(createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Related Contract',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Contract ID', value: contractLabel),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Contract Status',
                        value: contractStatus.isEmpty ? 'Unknown' : contractStatus.toUpperCase(),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Related Job', value: jobTitle),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Related Freelancer',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Name', value: freelancerName),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Email',
                        value: freelancerEmail.isEmpty ? 'Not available' : freelancerEmail,
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