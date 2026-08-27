import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:cv_gate/screens/freelancer/payments/PaymentDetailsScreen.dart';

import 'package:flutter/material.dart';


class PaymentsListScreen extends StatefulWidget {
  final String freelancerId;

  const PaymentsListScreen({
    super.key,
    required this.freelancerId,
  });

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _selectedStatus = 'all';

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
  }

  void _openPaymentDetails(String paymentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDetailsScreen(paymentId: paymentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db
        .collection('payments')
        .where('freelancerId', isEqualTo: widget.freelancerId)
        .orderBy('createdAt', descending: true)
        .snapshots();

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
            'Payments',
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('PaymentsListScreen Error: ${snapshot.error}');
            return _ErrorState(onRetry: _refresh);
          }

          if (!snapshot.hasData) {
            return const _LoadingList();
          }

          final docs = snapshot.data!.docs;

          final filtered = docs.where((doc) {
            final status =
            (doc.data()['status'] ?? '').toString().toLowerCase().trim();
            if (_selectedStatus == 'all') return true;
            return status == _selectedStatus;
          }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: _GlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _TopInfoChip(
                                  icon: Icons.payments_outlined,
                                  label: 'Total Payments',
                                  value: docs.length.toString(),
                                  tint: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TopInfoChip(
                                  icon: Icons.filter_list_rounded,
                                  label: 'Filtered',
                                  value: filtered.length.toString(),
                                  tint: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _StatusFilterChip(
                                  label: 'All',
                                  value: 'all',
                                  selectedValue: _selectedStatus,
                                  onTap: (value) =>
                                      setState(() => _selectedStatus = value),
                                ),
                                const SizedBox(width: 8),
                                _StatusFilterChip(
                                  label: 'Initiated',
                                  value: 'initiated',
                                  selectedValue: _selectedStatus,
                                  onTap: (value) =>
                                      setState(() => _selectedStatus = value),
                                ),
                                const SizedBox(width: 8),
                                _StatusFilterChip(
                                  label: 'Pending',
                                  value: 'pending',
                                  selectedValue: _selectedStatus,
                                  onTap: (value) =>
                                      setState(() => _selectedStatus = value),
                                ),
                                const SizedBox(width: 8),
                                _StatusFilterChip(
                                  label: 'Success',
                                  value: 'success',
                                  selectedValue: _selectedStatus,
                                  onTap: (value) =>
                                      setState(() => _selectedStatus = value),
                                ),
                                const SizedBox(width: 8),
                                _StatusFilterChip(
                                  label: 'Failed',
                                  value: 'failed',
                                  selectedValue: _selectedStatus,
                                  onTap: (value) =>
                                      setState(() => _selectedStatus = value),
                                ),
                                const SizedBox(width: 8),
                                _StatusFilterChip(
                                  label: 'Refunded',
                                  value: 'refunded',
                                  selectedValue: _selectedStatus,
                                  onTap: (value) =>
                                      setState(() => _selectedStatus = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPaymentsState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        return _PaymentCard(
                          paymentId: doc.id,
                          data: doc.data(),
                          db: _db,
                          onTap: () => _openPaymentDetails(doc.id),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String paymentId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.paymentId,
    required this.data,
    required this.db,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amount = data['amount'];
    final currency = (data['currency'] ?? 'SAR').toString().trim();
    final method = (data['method'] ?? 'card_sim').toString().trim();
    final status = (data['status'] ?? 'pending').toString().trim();
    final receiptRef = (data['receiptRef'] ?? '-').toString().trim();
    final createdAt = data['createdAt'];
    final contractId = (data['contractId'] ?? '').toString().trim();
    final clientId = (data['clientId'] ?? '').toString().trim();

    return _GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            contractId.isEmpty
                ? Future.value(null)
                : db.collection('contracts').doc(contractId).get(),
            clientId.isEmpty
                ? Future.value(null)
                : db.collection('users').doc(clientId).get(),
          ]),
          builder: (context, snapshot) {
            String contractStatus = '-';
            String clientName = 'Unknown Client';

            if (snapshot.hasData) {
              final contractSnap = snapshot.data![0];
              final clientSnap = snapshot.data![1];

              if (contractSnap is DocumentSnapshot<Map<String, dynamic>> &&
                  contractSnap.exists) {
                final contractData = contractSnap.data() ?? {};
                final fetchedStatus =
                (contractData['status'] ?? '').toString().trim();
                if (fetchedStatus.isNotEmpty) {
                  contractStatus = fetchedStatus;
                }
              }

              if (clientSnap is DocumentSnapshot<Map<String, dynamic>> &&
                  clientSnap.exists) {
                final clientData = clientSnap.data() ?? {};
                final fetchedName =
                (clientData['fullName'] ?? '').toString().trim();
                if (fetchedName.isNotEmpty) {
                  clientName = fetchedName;
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.primary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$amount $currency',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatMethod(method),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PaymentStatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailLine(
                  label: 'Client Name',
                  value: clientName,
                ),
                const SizedBox(height: 10),
                _DetailLine(
                  label: 'Receipt Reference',
                  value: receiptRef.isEmpty ? '-' : receiptRef,
                ),
                const SizedBox(height: 10),
                _DetailLine(
                  label: 'Date',
                  value: _formatTimestamp(createdAt),
                ),
                const SizedBox(height: 10),
                _DetailLine(
                  label: 'Contract ID',
                  value: contractId.isEmpty ? '-' : contractId,
                ),
                const SizedBox(height: 10),
                _DetailLine(
                  label: 'Contract Status',
                  value: contractStatus.isEmpty ? '-' : contractStatus,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'View Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  String _two(int value) => value < 10 ? '0$value' : '$value';
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
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
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              height: 1.35,
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
      bg = AppColors.textLight.withOpacity(0.18);
      fg = AppColors.textSecondary;
      label = 'Refunded';
    } else {
      bg = AppColors.textLight.withOpacity(0.18);
      fg = AppColors.textSecondary;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final void Function(String value) onTap;

  const _StatusFilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _TopInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _TopInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 19),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
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

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return const _GlassCard(
          child: SizedBox(
            height: 220,
            child: _SoftLoadingBox(),
          ),
        );
      },
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

class _EmptyPaymentsState extends StatelessWidget {
  const _EmptyPaymentsState();

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
              Icons.payments_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No payments found.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your payment records will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
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
              'Failed to load payments.',
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