import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  String _range = '30d';
  late Future<_ReportMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadMetrics();
  }

  DateTime? _rangeStart() {
    final now = DateTime.now();
    if (_range == '7d') return now.subtract(const Duration(days: 7));
    if (_range == '30d') return now.subtract(const Duration(days: 30));
    if (_range == '90d') return now.subtract(const Duration(days: 90));
    return null;
  }

  Query<Map<String, dynamic>> _applyRange(Query<Map<String, dynamic>> query, String field) {
    final start = _rangeStart();
    if (start == null) return query;
    return query.where(field, isGreaterThanOrEqualTo: Timestamp.fromDate(start));
  }

  Future<int> _countCollection(String collection, {String field = 'createdAt'}) async {
    final q = _applyRange(_db.collection(collection), field);
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

  Future<int> _countWithEquals(
      String collection, {
        required String whereField,
        required dynamic whereValue,
        String field = 'createdAt',
      }) async {
    Query<Map<String, dynamic>> q = _db.collection(collection).where(whereField, isEqualTo: whereValue);
    q = _applyRange(q, field);
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

  Future<double> _sumPaymentsByStatus(String? status) async {
    Query<Map<String, dynamic>> q = _db.collection('payments');
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    q = _applyRange(q, 'createdAt');
    final snap = await q.get();
    double total = 0;
    for (final doc in snap.docs) {
      final value = doc.data()['amount'];
      if (value is num) {
        total += value.toDouble();
      }
    }
    return total;
  }

  Future<double> _avgFreelancerRating() async {
    Query<Map<String, dynamic>> q = _db.collection('users').where('role', isEqualTo: 'freelancer');
    final snap = await q.get();
    double sum = 0;
    int count = 0;
    for (final doc in snap.docs) {
      final value = doc.data()['ratingAvg'];
      if (value is num) {
        sum += value.toDouble();
        count++;
      }
    }
    if (count == 0) return 0;
    return sum / count;
  }

  Future<_ReportMetrics> _loadMetrics() async {
    try {
      final totalUsers = await _countCollection('users');
      final clients = await _countWithEquals('users', whereField: 'role', whereValue: 'client', field: 'createdAt');
      final freelancers = await _countWithEquals('users', whereField: 'role', whereValue: 'freelancer', field: 'createdAt');

      final jobs = await _countCollection('jobs');
      final openJobs = await _countWithEquals('jobs', whereField: 'status', whereValue: 'open');
      final contractedJobs = await _countWithEquals('jobs', whereField: 'status', whereValue: 'contracted');
      final cancelledJobs = await _countWithEquals('jobs', whereField: 'status', whereValue: 'cancelled');

      final applications = await _countCollection('applications');
      final acceptedApplications = await _countWithEquals('applications', whereField: 'status', whereValue: 'accepted');

      final contracts = await _countCollection('contracts');
      final activeContracts = await _countWithEquals('contracts', whereField: 'status', whereValue: 'active');
      final completedContracts = await _countWithEquals('contracts', whereField: 'status', whereValue: 'completed');
      final disputedContracts = await _countWithEquals('contracts', whereField: 'status', whereValue: 'disputed');

      final totalPayments = await _countCollection('payments');
      final successPayments = await _countWithEquals('payments', whereField: 'status', whereValue: 'success');
      final pendingPayments = await _countWithEquals('payments', whereField: 'status', whereValue: 'pending');
      final failedPayments = await _countWithEquals('payments', whereField: 'status', whereValue: 'failed');
      final refundedPayments = await _countWithEquals('payments', whereField: 'status', whereValue: 'refunded');

      final totalRevenue = await _sumPaymentsByStatus(null);
      final successRevenue = await _sumPaymentsByStatus('success');
      final refundedRevenue = await _sumPaymentsByStatus('refunded');

      final disputes = await _countCollection('disputes');
      final openDisputes = await _countWithEquals('disputes', whereField: 'status', whereValue: 'open');
      final underReviewDisputes = await _countWithEquals('disputes', whereField: 'status', whereValue: 'under_review');
      final resolvedDisputes = await _countWithEquals('disputes', whereField: 'status', whereValue: 'resolved');
      final rejectedDisputes = await _countWithEquals('disputes', whereField: 'status', whereValue: 'rejected');

      final reviews = await _countCollection('reviews');
      final avgFreelancerRating = await _avgFreelancerRating();

      final conversionRate = jobs == 0 ? 0 : (contractedJobs / jobs) * 100;
      final paymentSuccessRate = totalPayments == 0 ? 0 : (successPayments / totalPayments) * 100;
      final disputeRate = contracts == 0 ? 0 : (disputes / contracts) * 100;
      final applicationAcceptanceRate = applications == 0 ? 0 : (acceptedApplications / applications) * 100;
      final avgRevenuePerSuccessPayment = successPayments == 0 ? 0 : (successRevenue / successPayments);

      return _ReportMetrics(
        totalUsers: totalUsers,
        clients: clients,
        freelancers: freelancers,
        jobs: jobs,
        openJobs: openJobs,
        contractedJobs: contractedJobs,
        cancelledJobs: cancelledJobs,
        applications: applications,
        acceptedApplications: acceptedApplications,
        contracts: contracts,
        activeContracts: activeContracts,
        completedContracts: completedContracts,
        disputedContracts: disputedContracts,
        totalPayments: totalPayments,
        successPayments: successPayments,
        pendingPayments: pendingPayments,
        failedPayments: failedPayments,
        refundedPayments: refundedPayments,
        totalRevenue: totalRevenue,
        successRevenue: successRevenue,
        refundedRevenue: refundedRevenue,
        disputes: disputes,
        openDisputes: openDisputes,
        underReviewDisputes: underReviewDisputes,
        resolvedDisputes: resolvedDisputes,
        rejectedDisputes: rejectedDisputes,
        reviews: reviews,
        avgFreelancerRating: avgFreelancerRating,
        conversionRate: conversionRate.toDouble(),
        paymentSuccessRate: paymentSuccessRate.toDouble(),
        disputeRate: disputeRate.toDouble(),
        applicationAcceptanceRate: applicationAcceptanceRate.toDouble(),
        avgRevenuePerSuccessPayment: avgRevenuePerSuccessPayment.toDouble(),
      );
    } catch (e, s) {
      debugPrint('================ REPORTS LOAD ERROR ================');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $s');
      debugPrint('===================================================');
      rethrow;
    }
  }
  void _reload() {
    setState(() {
      _future = _loadMetrics();
    });
  }

  String _rangeLabel() {
    if (_range == '7d') return 'Last 7 Days';
    if (_range == '30d') return 'Last 30 Days';
    if (_range == '90d') return 'Last 90 Days';
    return 'All Time';
  }

  String _money(double value) {
    return "${value.toStringAsFixed(0)} SAR";
  }

  String _percent(double value) {
    return "${value.toStringAsFixed(1)}%";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
          title: const Text(
            "Reports & Analytics",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_brandNavy, _slateBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_brandNavy, _slateBlue],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Reports Overview",
                              style: TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _rangeLabel(),
                              style: const TextStyle(
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _RangeSelector(
                    value: _range,
                    onChanged: (v) {
                      setState(() {
                        _range = v;
                        _future = _loadMetrics();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<_ReportMetrics>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const _CenteredState(
                    icon: Icons.error_outline_rounded,
                    title: "Failed to load reports",
                    subtitle: "Please try again later",
                  );
                }

                if (!snap.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  );
                }

                final m = snap.data!;

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    children: [
                      const _SectionTitle(
                        icon: Icons.dashboard_outlined,
                        title: "Main KPIs",
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _MetricCard(
                            title: "Total Users",
                            value: "${m.totalUsers}",
                            icon: Icons.people_alt_outlined,
                          ),
                          _MetricCard(
                            title: "Jobs Posted",
                            value: "${m.jobs}",
                            icon: Icons.work_outline_rounded,
                          ),
                          _MetricCard(
                            title: "Contracts",
                            value: "${m.contracts}",
                            icon: Icons.description_outlined,
                          ),
                          _MetricCard(
                            title: "Revenue",
                            value: _money(m.successRevenue),
                            icon: Icons.payments_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          children: [
                            const _SectionTitle(
                              icon: Icons.person_outline_rounded,
                              title: "User Activity Report",
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(label: "Total Users", value: "${m.totalUsers}"),
                            _InfoRow(label: "Clients", value: "${m.clients}"),
                            _InfoRow(label: "Freelancers", value: "${m.freelancers}"),
                            _InfoRow(label: "Applications Submitted", value: "${m.applications}"),
                            _InfoRow(label: "Accepted Applications", value: "${m.acceptedApplications}"),
                            _InfoRow(
                              label: "Acceptance Rate",
                              value: _percent(m.applicationAcceptanceRate),
                              valueColor: const Color(0xFF2563EB),
                            ),
                            _InfoRow(label: "Reviews Added", value: "${m.reviews}"),
                            _InfoRow(
                              label: "Avg Freelancer Rating",
                              value: m.avgFreelancerRating.toStringAsFixed(1),
                              valueColor: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          children: [
                            const _SectionTitle(
                              icon: Icons.receipt_long_outlined,
                              title: "Transaction Volume Report",
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(label: "Total Payments", value: "${m.totalPayments}"),
                            _InfoRow(label: "Successful Payments", value: "${m.successPayments}"),
                            _InfoRow(label: "Pending Payments", value: "${m.pendingPayments}"),
                            _InfoRow(label: "Failed Payments", value: "${m.failedPayments}"),
                            _InfoRow(label: "Refunded Payments", value: "${m.refundedPayments}"),
                            _InfoRow(
                              label: "Payment Success Rate",
                              value: _percent(m.paymentSuccessRate),
                              valueColor: const Color(0xFF059669),
                            ),
                            _InfoRow(
                              label: "Average Payment Value",
                              value: _money(m.avgRevenuePerSuccessPayment),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          children: [
                            const _SectionTitle(
                              icon: Icons.monitor_heart_outlined,
                              title: "Platform Performance Report",
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(label: "Open Jobs", value: "${m.openJobs}"),
                            _InfoRow(label: "Contracted Jobs", value: "${m.contractedJobs}"),
                            _InfoRow(label: "Cancelled Jobs", value: "${m.cancelledJobs}"),
                            _InfoRow(label: "Active Contracts", value: "${m.activeContracts}"),
                            _InfoRow(label: "Completed Contracts", value: "${m.completedContracts}"),
                            _InfoRow(label: "Disputed Contracts", value: "${m.disputedContracts}"),
                            _InfoRow(
                              label: "Job Conversion Rate",
                              value: _percent(m.conversionRate),
                              valueColor: const Color(0xFF2563EB),
                            ),
                            _InfoRow(
                              label: "Dispute Rate",
                              value: _percent(m.disputeRate),
                              valueColor: const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          children: [
                            const _SectionTitle(
                              icon: Icons.attach_money_rounded,
                              title: "Revenue Metrics Report",
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              label: "Gross Payment Volume",
                              value: _money(m.totalRevenue),
                            ),
                            _InfoRow(
                              label: "Successful Revenue",
                              value: _money(m.successRevenue),
                              valueColor: const Color(0xFF059669),
                            ),
                            _InfoRow(
                              label: "Refunded Value",
                              value: _money(m.refundedRevenue),
                              valueColor: const Color(0xFF7C3AED),
                            ),
                            _InfoRow(
                              label: "Open Disputes",
                              value: "${m.openDisputes}",
                              valueColor: const Color(0xFFDC2626),
                            ),
                            _InfoRow(label: "Under Review", value: "${m.underReviewDisputes}"),
                            _InfoRow(label: "Resolved Disputes", value: "${m.resolvedDisputes}"),
                            _InfoRow(label: "Rejected Disputes", value: "${m.rejectedDisputes}"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                              icon: Icons.summarize_outlined,
                              title: "Quick Summary",
                            ),
                            const SizedBox(height: 14),
                            _SummaryText(
                              text: "In ${_rangeLabel().toLowerCase()}, the platform recorded ${m.totalUsers} users, ${m.jobs} posted jobs, ${m.contracts} contracts, and ${m.totalPayments} payment records.",
                            ),
                            const SizedBox(height: 8),
                            _SummaryText(
                              text: "The current successful revenue reached ${_money(m.successRevenue)}, while the payment success rate is ${_percent(m.paymentSuccessRate)}.",
                            ),
                            const SizedBox(height: 8),
                            _SummaryText(
                              text: "Platform performance shows ${m.activeContracts} active contracts and ${m.openDisputes} open disputes, with a job conversion rate of ${_percent(m.conversionRate)}.",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetrics {
  final int totalUsers;
  final int clients;
  final int freelancers;
  final int jobs;
  final int openJobs;
  final int contractedJobs;
  final int cancelledJobs;
  final int applications;
  final int acceptedApplications;
  final int contracts;
  final int activeContracts;
  final int completedContracts;
  final int disputedContracts;
  final int totalPayments;
  final int successPayments;
  final int pendingPayments;
  final int failedPayments;
  final int refundedPayments;
  final double totalRevenue;
  final double successRevenue;
  final double refundedRevenue;
  final int disputes;
  final int openDisputes;
  final int underReviewDisputes;
  final int resolvedDisputes;
  final int rejectedDisputes;
  final int reviews;
  final double avgFreelancerRating;
  final double conversionRate;
  final double paymentSuccessRate;
  final double disputeRate;
  final double applicationAcceptanceRate;
  final double avgRevenuePerSuccessPayment;

  const _ReportMetrics({
    required this.totalUsers,
    required this.clients,
    required this.freelancers,
    required this.jobs,
    required this.openJobs,
    required this.contractedJobs,
    required this.cancelledJobs,
    required this.applications,
    required this.acceptedApplications,
    required this.contracts,
    required this.activeContracts,
    required this.completedContracts,
    required this.disputedContracts,
    required this.totalPayments,
    required this.successPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.refundedPayments,
    required this.totalRevenue,
    required this.successRevenue,
    required this.refundedRevenue,
    required this.disputes,
    required this.openDisputes,
    required this.underReviewDisputes,
    required this.resolvedDisputes,
    required this.rejectedDisputes,
    required this.reviews,
    required this.avgFreelancerRating,
    required this.conversionRate,
    required this.paymentSuccessRate,
    required this.disputeRate,
    required this.applicationAcceptanceRate,
    required this.avgRevenuePerSuccessPayment,
  });
}

class _RangeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RangeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _RangeChip(
          label: '7 Days',
          selected: value == '7d',
          onTap: () => onChanged('7d'),
        ),
        _RangeChip(
          label: '30 Days',
          selected: value == '30d',
          onTap: () => onChanged('30d'),
        ),
        _RangeChip(
          label: '90 Days',
          selected: value == '90d',
          onTap: () => onChanged('90d'),
        ),
        _RangeChip(
          label: 'All Time',
          selected: value == 'all',
          onTap: () => onChanged('all'),
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? const LinearGradient(
            colors: [_brandNavy, _slateBlue],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          )
              : null,
          color: selected ? null : Colors.black.withOpacity(0.03),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _textMuted,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_brandNavy, _slateBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String text;

  const _SummaryText({
    required this.text,
  });

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12.8,
        height: 1.5,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.35,
              ),
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
          width: double.infinity,
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

class _CenteredState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CenteredState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: _textMuted.withOpacity(0.85)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textMuted,
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