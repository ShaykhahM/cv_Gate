import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Dashboard/AdminNotfication_Screen.dart';
import 'package:cv_gate/screens/Admin/Reports/AdminReports_Screen.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;

  int _users = 0;
  int _openJobs = 0;
  int _activeContracts = 0;
  int _payments = 0;
  int _openDisputes = 0;

  final Map<String, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<int> _safeCount(Query query) async {
    try {
      final agg = await query.count().get();
      return agg.count??0;
    } catch (_) {
      final snap = await query.get();
      return snap.size;
    }
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);

    try {
      final results = await Future.wait<int>([
        _safeCount(_db.collection('users')),
        _safeCount(_db.collection('jobs').where('status', isEqualTo: 'open')),
        _safeCount(_db.collection('contracts').where('status', isEqualTo: 'active')),
        _safeCount(_db.collection('payments')),
        _safeCount(_db.collection('disputes').where('status', isEqualTo: 'open')),
      ]);

      if (!mounted) return;
      setState(() {
        _users = results[0];
        _openJobs = results[1];
        _activeContracts = results[2];
        _payments = results[3];
        _openDisputes = results[4];
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load dashboard.";
        _loading = false;
      });
    }
  }

  Future<String> _getUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      final name = (data['fullName'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      final best = name.isNotEmpty ? name : (email.isNotEmpty ? email : uid);
      _userNameCache[uid] = best;
      return best;
    } catch (_) {
      return uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final crossAxisCount = 2;

    return Scaffold(
      backgroundColor: _bgSlate,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
          title: const Text(
            "Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            _GlassIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminNotificationsScreen(adminId: adminId,)),
                );
              },
            ),
            const SizedBox(width: 10),
            _GlassIconButton(
              icon: Icons.refresh_rounded,
              onTap: _refresh,
            ),
            const SizedBox(width: 6),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_brandNavy, _slateBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _brandNavy,
          child:  CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // SliverToBoxAdapter(
              //   child: _Header(
              //     loading: _loading,
              //     onRefreshTap: _refresh,
              //     onNotificationsTap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
              //       );
              //     },
              //   ),
              // ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _error != null
                      ? _ErrorBanner(
                    text: _error!,
                    onRetry: _refresh,
                  )
                      : const SizedBox.shrink(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate.fixed(
                    _loading
                        ? List.generate(5, (i) => const _KpiSkeleton())
                        : [
                      _KpiCard(
                        title: 'Total Users',
                        value: _users.toString(),
                        icon: Icons.people_alt_rounded,
                        tint: const Color(0xFF2563EB),
                      ),
                      _KpiCard(
                        title: 'Open Jobs',
                        value: _openJobs.toString(),
                        icon: Icons.work_outline_rounded,
                        tint: const Color(0xFF7C3AED),
                      ),
                      _KpiCard(
                        title: 'Active Contracts',
                        value: _activeContracts.toString(),
                        icon: Icons.assignment_turned_in_outlined,
                        tint: const Color(0xFF059669),
                      ),
                      _KpiCard(
                        title: 'Total Payments',
                        value: _payments.toString(),
                        icon: Icons.payments_outlined,
                        tint: const Color(0xFFF59E0B),
                      ),
                      _KpiCard(
                        title: 'Open Disputes',
                        value: _openDisputes.toString(),
                        icon: Icons.gavel_outlined,
                        tint: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: w >= 420 ? 1.85 : 1.75,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: "Quick Actions",
                    subtitle: "Fast access to admin tools",
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _QuickActionsRow(
                    onOpenReports: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: "Pending Certificate Verification",
                    subtitle: "Recent freelancers needing verification",
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _PendingCertificatesCard(
                    db: _db,
                    loadUserName: _getUserName,
                    onOpenUserCertificates: (uid) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminUserCertificatesScreen(uid: uid)),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: "Latest Disputes",
                    subtitle: "Recent dispute activity",
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverToBoxAdapter(
                  child: _LatestDisputesCard(db: _db),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool loading;
  final VoidCallback onRefreshTap;
  final VoidCallback onNotificationsTap;

  const _Header({
    required this.loading,
    required this.onRefreshTap,
    required this.onNotificationsTap,
  });

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            height: 190,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_brandNavy, _slateBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: -40,
          child: _GlowCircle(size: 160, color: Colors.white.withOpacity(0.10)),
        ),
        Positioned(
          bottom: -70,
          left: -40,
          child: _GlowCircle(size: 180, color: Colors.white.withOpacity(0.08)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Admin Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loading ? "Loading insights..." : "Overview of platform activity",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _GlassIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationsTap,
              ),
              const SizedBox(width: 10),
              _GlassIconButton(
                icon: Icons.refresh_rounded,
                onTap: onRefreshTap,
              ),
            ],
          ),
        ),
        Positioned.fill(
          top: 120,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 18,
              decoration: const BoxDecoration(
                color: _bgSlate,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onOpenReports;
  const _QuickActionsRow({required this.onOpenReports});

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: "Reports",
            subtitle: "Users, jobs, payments",
            icon: Icons.bar_chart_rounded,
            gradient: const LinearGradient(
              colors: [_brandNavy, _slateBlue],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            onTap: onOpenReports,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingCertificatesCard extends StatelessWidget {
  final FirebaseFirestore db;
  final Future<String> Function(String uid) loadUserName;
  final void Function(String uid) onOpenUserCertificates;

  const _PendingCertificatesCard({
    required this.db,
    required this.loadUserName,
    required this.onOpenUserCertificates,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final q = db
        .collectionGroup('certificates')
        .where('verifyStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(6);

    return _GlassCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _emptyRow("Failed to load pending certificates.");
          }
          if (!snap.hasData) {
            return const SizedBox(height: 140, child: _SoftLoadingBox());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return _emptyRow("No pending certificates.");
          }

          return Column(
            children: [
              for (int i = 0; i < docs.length; i++) ...[
                _PendingCertTile(
                  certDoc: docs[i],
                  loadUserName: loadUserName,
                  onOpenUserCertificates: onOpenUserCertificates,
                ),
                if (i != docs.length - 1)
                  Divider(height: 18, color: Colors.black.withOpacity(0.06)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _emptyRow(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _textMuted.withOpacity(0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCertTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> certDoc;
  final Future<String> Function(String uid) loadUserName;
  final void Function(String uid) onOpenUserCertificates;

  const _PendingCertTile({
    required this.certDoc,
    required this.loadUserName,
    required this.onOpenUserCertificates,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final data = certDoc.data();
    final certName = (data['name'] ?? 'Certificate').toString().trim();
    final issuer = (data['issuer'] ?? '').toString().trim();
    final createdAt = data['createdAt'];

    String dateText = "Recently";
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      dateText = "${d.year}-${_two(d.month)}-${_two(d.day)}";
    }

    final parent = certDoc.reference.parent.parent;
    final uid = parent == null ? '' : parent.id;

    return FutureBuilder<String>(
      future: uid.isEmpty ? Future.value("Unknown") : loadUserName(uid),
      builder: (context, nameSnap) {
        final displayName = nameSnap.data ?? "Loading...";
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4A6E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_outlined, color: Color(0xFF0C4A6E), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issuer.isEmpty ? certName : "$certName \n $issuer",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: TextStyle(color: _textMuted.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: uid.isEmpty ? null : () => onOpenUserCertificates(uid),
              child: const Text(
                "Review",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  String _two(int v) => v < 10 ? "0$v" : "$v";
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.white.withOpacity(0.14),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.text, required this.onRetry});

  static const _textDark = Color(0xFF0F172A);
  static const _brandNavy = Color(0xFF0A2A43);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              "Retry",
              style: TextStyle(color: _brandNavy, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color tint;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 20,
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

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: const _ShimmerLite(),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

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
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.2),
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

class _ShimmerLite extends StatefulWidget {
  const _ShimmerLite();

  @override
  State<_ShimmerLite> createState() => _ShimmerLiteState();
}

class _ShimmerLiteState extends State<_ShimmerLite> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.withOpacity(0.10),
                Colors.grey.withOpacity(0.20),
                Colors.grey.withOpacity(0.10),
              ],
              stops: [
                (t - 0.25).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.25).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

class _LatestDisputesCard extends StatelessWidget {
  final FirebaseFirestore db;
  const _LatestDisputesCard({required this.db});

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final q = db.collection('disputes').orderBy('createdAt', descending: true).limit(5);

    return _GlassCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _empty("Failed to load disputes.");
          }
          if (!snap.hasData) {
            return const SizedBox(height: 140, child: _SoftLoadingBox());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) return _empty("No disputes found.");

          return Column(
            children: [
              for (int i = 0; i < docs.length; i++) ...[
                _DisputeTile(data: docs[i].data()),
                if (i != docs.length - 1) Divider(height: 18, color: Colors.black.withOpacity(0.06)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _empty(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _textMuted.withOpacity(0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DisputeTile({required this.data});

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'open').toString();
    final reason = (data['reason'] ?? 'Dispute').toString();
    final contractId = (data['contractId'] ?? '').toString();

    final ts = data['createdAt'];
    String whenText = '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      whenText = "${d.year}-${_two(d.month)}-${_two(d.day)}";
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                contractId.isEmpty ? (whenText.isEmpty ? "Recently" : whenText) : "Contract: $contractId",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _StatusChip(status: status),
      ],
    );
  }

  String _two(int v) => v < 10 ? "0$v" : "$v";
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();
    Color bg;
    Color fg;

    if (s == 'open') {
      bg = const Color(0xFFDC2626).withOpacity(0.12);
      fg = const Color(0xFFDC2626);
    } else if (s == 'under_review') {
      bg = const Color(0xFFF59E0B).withOpacity(0.14);
      fg = const Color(0xFFF59E0B);
    } else if (s == 'resolved') {
      bg = const Color(0xFF059669).withOpacity(0.14);
      fg = const Color(0xFF059669);
    } else {
      bg = const Color(0xFF64748B).withOpacity(0.14);
      fg = const Color(0xFF64748B);
    }

    final label = s.replaceAll('_', ' ').toUpperCase();

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
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 70);
    p.quadraticBezierTo(size.width * 0.22, size.height, size.width * 0.55, size.height - 34);
    p.quadraticBezierTo(size.width * 0.85, size.height - 74, size.width, size.height - 22);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    );
  }
}


class AdminUserCertificatesScreen extends StatefulWidget {
  final String uid;
  const AdminUserCertificatesScreen({super.key, required this.uid});

  @override
  State<AdminUserCertificatesScreen> createState() => _AdminUserCertificatesScreenState();
}

class _AdminUserCertificatesScreenState extends State<AdminUserCertificatesScreen> {
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);
  static const _brandNavy = Color(0xFF0A2A43);

  final _db = FirebaseFirestore.instance;

  Future<void> _setStatus({
    required String certId,
    required String status,
    required String note,
  }) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    await _db.collection('users').doc(widget.uid).collection('certificates').doc(certId).update({
      'verifyStatus': status,
      'verifyNote': note,
      'verifiedBy': adminUid,
    });
  }

  Future<String?> _askNote(BuildContext context, String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: TextField(
            controller: c,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Optional note",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _brandNavy),
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _db
        .collection('users')
        .doc(widget.uid)
        .collection('certificates')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: AppBar(
        title: const Text("Certificates", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Text("Failed to load certificates", style: TextStyle(color: _textMuted, fontWeight: FontWeight.w800)),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text("No certificates found", style: TextStyle(color: _textMuted, fontWeight: FontWeight.w800)),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final d = doc.data();
                final name = (d['name'] ?? 'Certificate').toString();
                final issuer = (d['issuer'] ?? '').toString();
                final status = (d['verifyStatus'] ?? 'pending').toString();

                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900)),
                        if (issuer.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(issuer, style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _SmallStatusChip(status: status),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                final note = await _askNote(context, "Approve Certificate");
                                if (note == null) return;
                                await _setStatus(certId: doc.id, status: 'approved', note: note);
                              },
                              child: const Text("Approve", style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                            TextButton(
                              onPressed: () async {
                                final note = await _askNote(context, "Reject Certificate");
                                if (note == null) return;
                                await _setStatus(certId: doc.id, status: 'rejected', note: note);
                              },
                              child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  final String status;
  const _SmallStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();
    Color bg;
    Color fg;

    if (s == 'pending') {
      bg = const Color(0xFFF59E0B).withOpacity(0.14);
      fg = const Color(0xFFF59E0B);
    } else if (s == 'approved') {
      bg = const Color(0xFF059669).withOpacity(0.14);
      fg = const Color(0xFF059669);
    } else if (s == 'rejected') {
      bg = const Color(0xFFDC2626).withOpacity(0.14);
      fg = const Color(0xFFDC2626);
    } else {
      bg = const Color(0xFF64748B).withOpacity(0.14);
      fg = const Color(0xFF64748B);
    }

    final label = s.toUpperCase();

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
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}