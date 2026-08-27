import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/bloc/client/cubit.dart';
import 'package:cv_gate/screens/client/jobs/PostJob_Screen.dart';
import 'package:cv_gate/screens/client/notifications/ClientNotifications_Screen.dart';
import 'package:cv_gate/screens/client/profile/ClientProfile_Screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onPostNewJob;
  final VoidCallback? onBrowseFreelancers;
  final VoidCallback? onOpenContracts;
  final VoidCallback? onOpenProfile;

  const ClientDashboardScreen({
    super.key,
    this.onOpenNotifications,
    this.onPostNewJob,
    this.onBrowseFreelancers,
    this.onOpenContracts,
    this.onOpenProfile,
  });

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = clientId;

  late Future<int> _totalJobsFuture;
  late Future<int> _openJobsFuture;
  late Future<int> _activeContractsFuture;
  late Future<int> _pendingPaymentsFuture;

  final Map<String, String> _userNameCache = {};
  final Map<String, String> _jobTitleCache = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void _loadCounts() {
    _totalJobsFuture = _countTotalJobs();
    _openJobsFuture = _countOpenJobs();
    _activeContractsFuture = _countActiveContracts();
    _pendingPaymentsFuture = _countPendingPayments();
  }

  Future<int> _safeCount(Query<Map<String, dynamic>> query) async {
    try {
      final agg = await query.count().get();
      return agg.count ?? 0;
    } catch (_) {
      final snap = await query.limit(1000).get();
      return snap.size;
    }
  }

  Future<int> _countTotalJobs() {
    return _safeCount(
      _db.collection('jobs').where('clientId', isEqualTo: _uid),
    );
  }

  Future<int> _countOpenJobs() {
    return _safeCount(
      _db.collection('jobs').where('clientId', isEqualTo: _uid).where('status', isEqualTo: 'open'),
    );
  }

  Future<int> _countActiveContracts() {
    return _safeCount(
      _db.collection('contracts').where('clientId', isEqualTo: _uid).where('status', whereIn: ['active', 'submitted']),
    );
  }

  Future<int> _countPendingPayments() {
    return _safeCount(
      _db.collection('payments').where('clientId', isEqualTo: _uid).where('status', whereIn: ['initiated', 'pending']),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _loadCounts();
    });
  }

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) return 'User';
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId]!;
    try {
      final snap = await _db.collection('users').doc(userId).get();
      final data = snap.data() ?? {};
      final name = (data['fullName'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      final best = name.isNotEmpty ? name : (email.isNotEmpty ? email : 'User');
      _userNameCache[userId] = best;
      return best;
    } catch (_) {
      return 'User';
    }
  }

  Future<String> _getJobTitle(String jobId) async {
    if (jobId.isEmpty) return 'Job';
    if (_jobTitleCache.containsKey(jobId)) return _jobTitleCache[jobId]!;
    try {
      final snap = await _db.collection('jobs').doc(jobId).get();
      final data = snap.data() ?? {};
      final title = (data['title'] ?? '').toString().trim();
      final best = title.isNotEmpty ? title : 'Job';
      _jobTitleCache[jobId] = best;
      return best;
    } catch (_) {
      return 'Job';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            // if (widget.onOpenNotifications != null) ...[
            //   _GlassIconButton(
            //     icon: Icons.notifications_none_rounded,
            //     onTap: widget.onOpenNotifications!,
            //   ),
            //   const SizedBox(width: 10),
            // ],
            _GlassIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: ()
              {
                GoToScreen(context: context, screen: ClientNotificationsScreen());
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
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _ClientWelcomeCard(
                    uid: _uid,
                    db: _db,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate.fixed([
                    FutureBuilder<int>(
                      future: _totalJobsFuture,
                      builder: (_, snap) => _KpiCard(
                        title: 'Total Jobs',
                        value: snap.hasData ? '${snap.data}' : '...',
                        icon: Icons.work_outline_rounded,
                        tint: AppColors.accent,
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _openJobsFuture,
                      builder: (_, snap) => _KpiCard(
                        title: 'Open Jobs',
                        value: snap.hasData ? '${snap.data}' : '...',
                        icon: Icons.folder_open_outlined,
                        tint: const Color(0xFF7C3AED),
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _activeContractsFuture,
                      builder: (_, snap) => _KpiCard(
                        title: 'Active Contracts',
                        value: snap.hasData ? '${snap.data}' : '...',
                        icon: Icons.assignment_turned_in_outlined,
                        tint: AppColors.success,
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _pendingPaymentsFuture,
                      builder: (_, snap) => _KpiCard(
                        title: 'Pending Payments',
                        value: snap.hasData ? '${snap.data}' : '...',
                        icon: Icons.account_balance_wallet_outlined,
                        tint: AppColors.warning,
                      ),
                    ),
                  ]),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: width >= 420 ? 1.86 : 1.72,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Quick Actions',
                    subtitle: 'Fast access to the main client tools',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _QuickActionsGrid(
                    onPostNewJob: ()
                    {
                      GoToScreen(context: context, screen: ClientPostNewJobScreen());
                    },
                    onBrowseFreelancers: ()
                    {
                      ClientCubit.get(context).changeScreen(2);
                    },
                    onOpenContracts:  ()
                    {
                      ClientCubit.get(context).changeScreen(3);
                    },
                    onOpenProfile: (){
                      GoToScreen(context: context, screen: ClientProfileScreen());
                    },
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Recent Applications',
                    subtitle: 'Latest freelancer proposals on your jobs',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _RecentApplicationsCard(
                    db: _db,
                    clientId: _uid,
                    loadUserName: _getUserName,
                    loadJobTitle: _getJobTitle,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Recent Notifications',
                    subtitle: 'Latest updates related to your account',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverToBoxAdapter(
                  child: _RecentNotificationsCard(
                    db: _db,
                    clientId: _uid,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientWelcomeCard extends StatelessWidget {
  final String uid;
  final FirebaseFirestore db;

  const _ClientWelcomeCard({
    required this.uid,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const SizedBox(
              height: 112,
              child: _SoftLoadingBox(),
            );
          }

          final data = snap.data?.data() ?? {};
          final fullName = (data['fullName'] ?? 'Client').toString().trim();
          final city = (data['city'] ?? '').toString().trim();
          final photoUrl = (data['photoUrl'] ?? '').toString().trim();

          return Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.10),
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                  _initials(fullName),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName.isEmpty ? 'Client' : fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TinyInfoChip(
                      icon: Icons.location_on_outlined,
                      text: city.isEmpty ? 'No city' : city,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onPostNewJob;
  final VoidCallback? onBrowseFreelancers;
  final VoidCallback? onOpenContracts;
  final VoidCallback? onOpenProfile;

  const _QuickActionsGrid({
    this.onPostNewJob,
    this.onBrowseFreelancers,
    this.onOpenContracts,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Post Job',
                subtitle: 'Create a new job',
                icon: Icons.add_business_outlined,
                gradient: AppColors.primaryGradient,
                onTap: onPostNewJob,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Freelancers',
                subtitle: 'Browse profiles',
                icon: Icons.people_alt_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                onTap: onBrowseFreelancers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Contracts',
                subtitle: 'Open agreements',
                icon: Icons.assignment_turned_in_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF92400E), Color(0xFFF59E0B)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                onTap: onOpenContracts,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Profile',
                subtitle: 'Manage account',
                icon: Icons.person_outline_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                onTap: ()
                {
                  GoToScreen(context: context, screen: ClientProfileScreen());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentApplicationsCard extends StatelessWidget {
  final FirebaseFirestore db;
  final String clientId;
  final Future<String> Function(String userId) loadUserName;
  final Future<String> Function(String jobId) loadJobTitle;

  const _RecentApplicationsCard({
    required this.db,
    required this.clientId,
    required this.loadUserName,
    required this.loadJobTitle,
  });

  @override
  Widget build(BuildContext context) {
    final query = db
        .collection('applications')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .limit(4);

    return _GlassCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const _SimpleEmptyState(text: 'Failed to load applications.');
          }
          if (!snap.hasData) {
            return const SizedBox(height: 140, child: _SoftLoadingBox());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const _SimpleEmptyState(text: 'No applications yet.');
          }

          return Column(
            children: [
              for (int i = 0; i < docs.length; i++) ...[
                _ApplicationTile(
                  data: docs[i].data(),
                  loadUserName: loadUserName,
                  loadJobTitle: loadJobTitle,
                ),
                if (i != docs.length - 1)
                  Divider(
                    height: 18,
                    color: Colors.black.withOpacity(0.06),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecentNotificationsCard extends StatelessWidget {
  final FirebaseFirestore db;
  final String clientId;

  const _RecentNotificationsCard({
    required this.db,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final query = db
        .collection('notifications')
        .where('recipientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .limit(4);

    return _GlassCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const _SimpleEmptyState(text: 'Failed to load notifications.');
          }
          if (!snap.hasData) {
            return const SizedBox(height: 140, child: _SoftLoadingBox());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const _SimpleEmptyState(text: 'No notifications yet.');
          }

          return Column(
            children: [
              for (int i = 0; i < docs.length; i++) ...[
                _NotificationTile(data: docs[i].data()),
                if (i != docs.length - 1)
                  Divider(
                    height: 18,
                    color: Colors.black.withOpacity(0.06),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<String> Function(String userId) loadUserName;
  final Future<String> Function(String jobId) loadJobTitle;

  const _ApplicationTile({
    required this.data,
    required this.loadUserName,
    required this.loadJobTitle,
  });

  @override
  Widget build(BuildContext context) {
    final freelancerId = (data['freelancerId'] ?? '').toString();
    final jobId = (data['jobId'] ?? '').toString();
    final status = (data['status'] ?? 'pending').toString();
    final proposedPrice = (data['proposedPrice'] ?? '').toString();
    final proposedDurationDays = (data['proposedDurationDays'] ?? '').toString();
    final createdAt = data['createdAt'];

    return FutureBuilder<List<String>>(
      future: Future.wait([
        loadUserName(freelancerId),
        loadJobTitle(jobId),
      ]),
      builder: (context, snap) {
        final freelancerName = snap.data?[0] ?? 'Loading...';
        final jobTitle = snap.data?[1] ?? 'Loading...';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    freelancerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _applicationMeta(proposedPrice, proposedDurationDays),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateLabel(createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusChip(status: status),
          ],
        );
      },
    );
  }

  static String _applicationMeta(String price, String duration) {
    final parts = <String>[];
    if (price.trim().isNotEmpty) {
      parts.add(price);
    }
    if (duration.trim().isNotEmpty) {
      parts.add('$duration days');
    }
    return parts.isEmpty ? 'New proposal' : parts.join(' • ');
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _NotificationTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Notification').toString().trim();
    final body = (data['body'] ?? '').toString().trim();
    final isRead = data['isRead'] == true;
    final createdAt = data['createdAt'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (isRead ? AppColors.textSecondary : AppColors.warning).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isRead ? Icons.notifications_none_rounded : Icons.notifications_active_outlined,
            color: isRead ? AppColors.textSecondary : AppColors.warning,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Notification' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body.isEmpty ? 'No details available.' : body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLabel(createdAt),
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (!isRead) _UnreadDot(),
      ],
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

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
                            color: AppColors.textPrimary,
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
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
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
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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

class _TinyInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TinyInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
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

class _UnreadDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

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

class _SimpleEmptyState extends StatelessWidget {
  final String text;

  const _SimpleEmptyState({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary.withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
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
    final s = status.trim().toLowerCase();
    late final Color bg;
    late final Color fg;

    if (s == 'pending' || s == 'initiated') {
      bg = AppColors.warning.withOpacity(0.14);
      fg = AppColors.warning;
    } else if (s == 'accepted' || s == 'active' || s == 'success' || s == 'completed') {
      bg = AppColors.success.withOpacity(0.14);
      fg = AppColors.success;
    } else if (s == 'submitted') {
      bg = AppColors.accent.withOpacity(0.14);
      fg = AppColors.accent;
    } else if (s == 'rejected' || s == 'failed' || s == 'cancelled' || s == 'withdrawn') {
      bg = AppColors.error.withOpacity(0.14);
      fg = AppColors.error;
    } else if (s == 'revision_requested') {
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
        s.replaceAll('_', ' ').toUpperCase(),
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

String _dateLabel(dynamic value) {
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }
  return 'Recently';
}

String _two(int v) => v < 10 ? '0$v' : '$v';