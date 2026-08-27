import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:cv_gate/screens/freelancer/Works/ContractDetailsScreen.dart';
import 'package:flutter/material.dart';



class ContractsListScreen extends StatefulWidget {
  final String freelancerId;

  const ContractsListScreen({
    super.key,
    required this.freelancerId,
  });

  @override
  State<ContractsListScreen> createState() => _ContractsListScreenState();
}

class _ContractsListScreenState extends State<ContractsListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _selectedStatus = 'all';

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
  }

  void _openContractDetails(String contractId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractDetailsScreen(
          contractId: contractId,
          freelancerId: widget.freelancerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db
        .collection('contracts')
        .where('freelancerId', isEqualTo: widget.freelancerId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
          title: const Text(
            'My Contracts',
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
            try {
              throw snapshot.error!;
            } catch (e, s) {
              debugPrint('MyApplicationsScreen Error: $e');
              debugPrint('MyApplicationsScreen Stack: $s');
            }
            return _ErrorState(onRetry: _refresh);
          }
          // if (snapshot.hasError) {
          //   debugPrint('ContractsListScreen Error: ${snapshot.error}');
          //
          //   return _ErrorState(onRetry: _refresh);
          // }

          if (!snapshot.hasData) {
            return const _LoadingList();
          }

          final docs = snapshot.data!.docs;

          final filtered = docs.where((doc) {
            final status = (doc.data()['status'] ?? '').toString().toLowerCase().trim();
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
                  child: Column(
                    children: [
                      _GlassCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _TopInfoChip(
                                    icon: Icons.description_outlined,
                                    label: 'Total Contracts',
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
                                    onTap: (value) {
                                      setState(() {
                                        _selectedStatus = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusFilterChip(
                                    label: 'Draft',
                                    value: 'draft',
                                    selectedValue: _selectedStatus,
                                    onTap: (value) {
                                      setState(() {
                                        _selectedStatus = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusFilterChip(
                                    label: 'Active',
                                    value: 'active',
                                    selectedValue: _selectedStatus,
                                    onTap: (value) {
                                      setState(() {
                                        _selectedStatus = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusFilterChip(
                                    label: 'Submitted',
                                    value: 'submitted',
                                    selectedValue: _selectedStatus,
                                    onTap: (value) {
                                      setState(() {
                                        _selectedStatus = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusFilterChip(
                                    label: 'Completed',
                                    value: 'completed',
                                    selectedValue: _selectedStatus,
                                    onTap: (value) {
                                      setState(() {
                                        _selectedStatus = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusFilterChip(
                                    label: 'Cancelled',
                                    value: 'cancelled',
                                    selectedValue: _selectedStatus,
                                    onTap: (value) {
                                      setState(() {
                                        _selectedStatus = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusFilterChip(
                                    label: 'Disputed',
                                    value: 'disputed',
                                    selectedValue: _selectedStatus,
                                    onTap: (value) {
                                      setState(() {
                                        _selectedStatus = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyContractsState(),
                  )
                else
                  SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return _ContractCard(
                        contractId: doc.id,
                        data: doc.data(),
                        db: _db,
                        onTap: () => _openContractDetails(doc.id),
                      );
                    },
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final String contractId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;
  final VoidCallback onTap;

  const _ContractCard({
    required this.contractId,
    required this.data,
    required this.db,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'draft').toString().trim();
    final agreedPrice = data['agreedPrice'];
    final currency = (data['currency'] ?? 'SAR').toString().trim();
    final duration = (data['agreedDurationDays'] ?? 0).toString();
    final jobId = (data['jobId'] ?? '').toString().trim();
    final clientId = (data['clientId'] ?? '').toString().trim();
    final createdAt = data['createdAt'];

    return _GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            jobId.isEmpty
                ? Future.value(null)
                : db.collection('jobs').doc(jobId).get(),
            clientId.isEmpty
                ? Future.value(null)
                : db.collection('users').doc(clientId).get(),
          ]),
          builder: (context, snapshot) {
            String jobTitle = 'Job';
            String clientName = 'Unknown Client';

            if (snapshot.hasData) {
              final jobSnap = snapshot.data![0];
              final clientSnap = snapshot.data![1];

              if (jobSnap is DocumentSnapshot<Map<String, dynamic>> &&
                  jobSnap.exists) {
                final jobData = jobSnap.data() ?? {};
                final fetchedTitle = (jobData['title'] ?? '').toString().trim();
                if (fetchedTitle.isNotEmpty) jobTitle = fetchedTitle;
              }

              if (clientSnap is DocumentSnapshot<Map<String, dynamic>> &&
                  clientSnap.exists) {
                final clientData = clientSnap.data() ?? {};
                final fetchedName =
                (clientData['fullName'] ?? '').toString().trim();
                if (fetchedName.isNotEmpty) clientName = fetchedName;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ClientTag(name: clientName),
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
                        value: '$agreedPrice $currency',
                        tint: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniInfoBox(
                        icon: Icons.schedule_outlined,
                        label: 'Duration',
                        value: '$duration days',
                        tint: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfoBox(
                        icon: Icons.badge_outlined,
                        label: 'Contract ID',
                        value: contractId,
                        tint: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniInfoBox(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created At',
                        value: _formatTimestamp(createdAt),
                        tint: AppColors.success,
                      ),
                    ),
                  ],
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
                        'View Contract',
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

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return 'Recently';
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  String _two(int value) => value < 10 ? '0$value' : '$value';
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

class _ClientTag extends StatelessWidget {
  final String name;

  const _ClientTag({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.info,
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
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return const _GlassCard(
          child: SizedBox(
            height: 185,
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

class _EmptyContractsState extends StatelessWidget {
  const _EmptyContractsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
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
              Icons.description_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No contracts found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your current and past contracts will appear here.',
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
        margin: const EdgeInsets.symmetric(horizontal: 6),
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
              'Failed to load contracts.',
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