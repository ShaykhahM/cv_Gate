import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:flutter/material.dart';


class PaymentDetailsScreen extends StatefulWidget {
  final String paymentId;

  const PaymentDetailsScreen({
    super.key,
    required this.paymentId,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
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
            'Payment Details',
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
        future: _db.collection('payments').doc(widget.paymentId).get(),
        builder: (context, paymentSnapshot) {
          if (paymentSnapshot.hasError) {
            debugPrint('PaymentDetailsScreen payment error: ${paymentSnapshot.error}');
            return _ErrorState(onRetry: _refresh);
          }

          if (!paymentSnapshot.hasData) {
            return const _LoadingView();
          }

          if (!paymentSnapshot.data!.exists) {
            return const _NotFoundState();
          }

          final paymentData = paymentSnapshot.data!.data() ?? {};

          final amount = paymentData['amount'];
          final currency = (paymentData['currency'] ?? 'SAR').toString().trim();
          final method = (paymentData['method'] ?? 'card_sim').toString().trim();
          final status = (paymentData['status'] ?? 'pending').toString().trim();
          final receiptRef = (paymentData['receiptRef'] ?? '-').toString().trim();
          final contractId = (paymentData['contractId'] ?? '').toString().trim();
          final jobIdFromPayment = (paymentData['jobId'] ?? '').toString().trim();
          final clientId = (paymentData['clientId'] ?? '').toString().trim();
          final createdAt = paymentData['createdAt'];

          return FutureBuilder<List<dynamic>>(
            future: Future.wait([
              contractId.isEmpty
                  ? Future.value(null)
                  : _db.collection('contracts').doc(contractId).get(),
              jobIdFromPayment.isEmpty
                  ? Future.value(null)
                  : _db.collection('jobs').doc(jobIdFromPayment).get(),
              clientId.isEmpty
                  ? Future.value(null)
                  : _db.collection('users').doc(clientId).get(),
            ]),
            builder: (context, relatedSnapshot) {
              final contractSnap = relatedSnapshot.hasData ? relatedSnapshot.data![0] : null;
              final jobSnap = relatedSnapshot.hasData ? relatedSnapshot.data![1] : null;
              final clientSnap = relatedSnapshot.hasData ? relatedSnapshot.data![2] : null;

              final contractData = contractSnap is DocumentSnapshot<Map<String, dynamic>>
                  ? (contractSnap.data() ?? {})
                  : <String, dynamic>{};

              final paymentJobId = jobIdFromPayment.isNotEmpty
                  ? jobIdFromPayment
                  : (contractData['jobId'] ?? '').toString().trim();

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                future: jobIdFromPayment.isEmpty && paymentJobId.isNotEmpty
                    ? _db.collection('jobs').doc(paymentJobId).get()
                    : Future.value(
                  jobSnap is DocumentSnapshot<Map<String, dynamic>> ? jobSnap : null,
                ),
                builder: (context, finalJobSnapshot) {
                  final jobData = finalJobSnapshot.data?.data() ?? {};
                  final clientData = clientSnap is DocumentSnapshot<Map<String, dynamic>>
                      ? (clientSnap.data() ?? {})
                      : <String, dynamic>{};

                  final contractStatus = (contractData['status'] ?? '-').toString().trim();
                  final agreedPrice = (contractData['agreedPrice'] ?? '-').toString();
                  final agreedDuration = (contractData['agreedDurationDays'] ?? '-').toString();

                  final jobTitle = (jobData['title'] ?? 'Unknown Job').toString().trim();
                  final jobCategory = (jobData['category'] ?? 'General').toString().trim();
                  final jobBudget = (jobData['budget'] ?? '-').toString();
                  final jobDuration = (jobData['durationDays'] ?? '-').toString();

                  final clientName = (clientData['fullName'] ?? 'Unknown Client').toString().trim();
                  final clientPhone = (clientData['phone'] ?? '-').toString().trim();

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
                              amount: '$amount $currency',
                              status: status,
                              method: _formatMethod(method),
                              date: _formatTimestamp(createdAt),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          sliver: SliverToBoxAdapter(
                            child: _SectionTitle(
                              title: 'Payment Information',
                              subtitle: 'Main details of this payment record',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          sliver: SliverToBoxAdapter(
                            child: _GlassCard(
                              child: Column(
                                children: [
                                  _DetailRow(
                                    label: 'Amount',
                                    value: '$amount',
                                    icon: Icons.payments_outlined,
                                    tint: AppColors.warning,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Currency',
                                    value: currency,
                                    icon: Icons.account_balance_wallet_outlined,
                                    tint: AppColors.success,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Method',
                                    value: _formatMethod(method),
                                    icon: Icons.credit_card_outlined,
                                    tint: AppColors.info,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Status',
                                    icon: Icons.flag_outlined,
                                    tint: AppColors.primary,
                                    valueWidget: _PaymentStatusChip(status: status),
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Receipt Reference',
                                    value: receiptRef.isEmpty ? '-' : receiptRef,
                                    icon: Icons.receipt_long_outlined,
                                    tint: AppColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Date',
                                    value: _formatTimestamp(createdAt),
                                    icon: Icons.calendar_today_outlined,
                                    tint: AppColors.success,
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
                              title: 'Client Information',
                              subtitle: 'Information about the job owner',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          sliver: SliverToBoxAdapter(
                            child: _GlassCard(
                              child: Column(
                                children: [
                                  _DetailRow(
                                    label: 'Client Name',
                                    value: clientName.isEmpty ? 'Unknown Client' : clientName,
                                    icon: Icons.person_outline_rounded,
                                    tint: AppColors.info,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Client Phone',
                                    value: clientPhone.isEmpty ? '-' : clientPhone,
                                    icon: Icons.phone_outlined,
                                    tint: AppColors.success,
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
                              title: 'Related Contract',
                              subtitle: 'Contract linked to this payment',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          sliver: SliverToBoxAdapter(
                            child: _GlassCard(
                              child: Column(
                                children: [
                                  _DetailRow(
                                    label: 'Contract ID',
                                    value: contractId.isEmpty ? '-' : contractId,
                                    icon: Icons.description_outlined,
                                    tint: AppColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Contract Status',
                                    value: contractStatus.isEmpty ? '-' : contractStatus,
                                    icon: Icons.task_alt_outlined,
                                    tint: AppColors.success,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Agreed Price',
                                    value: '$agreedPrice $currency',
                                    icon: Icons.sell_outlined,
                                    tint: AppColors.warning,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Agreed Duration',
                                    value: '$agreedDuration days',
                                    icon: Icons.schedule_outlined,
                                    tint: AppColors.info,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          sliver: SliverToBoxAdapter(
                            child: _SectionTitle(
                              title: 'Related Job',
                              subtitle: 'Job linked to this payment',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                          sliver: SliverToBoxAdapter(
                            child: _GlassCard(
                              child: Column(
                                children: [
                                  _DetailRow(
                                    label: 'Job Title',
                                    value: jobTitle.isEmpty ? 'Unknown Job' : jobTitle,
                                    icon: Icons.work_outline_rounded,
                                    tint: AppColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Category',
                                    value: jobCategory.isEmpty ? '-' : jobCategory,
                                    icon: Icons.category_outlined,
                                    tint: AppColors.info,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Job Budget',
                                    value: '$jobBudget $currency',
                                    icon: Icons.payments_outlined,
                                    tint: AppColors.warning,
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    label: 'Job Duration',
                                    value: '$jobDuration days',
                                    icon: Icons.timer_outlined,
                                    tint: AppColors.success,
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
          );
        },
      ),
    );
  }

  String _formatMethod(String method) {
    final m = method.toLowerCase().trim();
    if (m == 'card_sim') return 'Card';
    if (m == 'stc_sim') return 'STC Pay';
    if (m == 'bank_sim') return 'Bank Transfer';
    return method;
  }

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return 'Recently';
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _two(int value) => value < 10 ? '0$value' : '$value';
}

class _HeaderCard extends StatelessWidget {
  final String amount;
  final String status;
  final String method;
  final String date;

  const _HeaderCard({
    required this.amount,
    required this.status,
    required this.method,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.credit_card_outlined,
                      text: method,
                    ),
                    _PaymentStatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData icon;
  final Color tint;

  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                label,
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
            ],
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
    final s = status.toLowerCase().trim();

    Color bg;
    Color fg;
    String label;

    if (s == 'initiated') {
      bg = AppColors.info.withOpacity(0.12);
      fg = AppColors.info;
      label = 'Initiated';
    } else if (s == 'pending') {
      bg = AppColors.warning.withOpacity(0.12);
      fg = AppColors.warning;
      label = 'Pending';
    } else if (s == 'success') {
      bg = AppColors.success.withOpacity(0.12);
      fg = AppColors.success;
      label = 'Success';
    } else if (s == 'failed') {
      bg = AppColors.error.withOpacity(0.12);
      fg = AppColors.error;
      label = 'Failed';
    } else if (s == 'refunded') {
      bg = AppColors.textLight.withOpacity(0.20);
      fg = AppColors.textSecondary;
      label = 'Refunded';
    } else {
      bg = AppColors.textLight.withOpacity(0.20);
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
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
          child: SizedBox(height: 110, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 250, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 170, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 190, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 190, child: _SoftLoadingBox()),
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
              'Payment not found.',
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
              'Failed to load payment details.',
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