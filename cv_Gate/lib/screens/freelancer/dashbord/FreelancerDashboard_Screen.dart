import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:cv_gate/screens/freelancer/Profile/FreelancerProfileScreen.dart';
import 'package:cv_gate/screens/freelancer/Profile/freelancer_certificates_portfolio_screen.dart';
import 'package:cv_gate/screens/freelancer/Works/FreelancerWork_Screen.dart';
import 'package:cv_gate/screens/freelancer/jobs/FreelancerJobs_Layout.dart';
import 'package:cv_gate/screens/freelancer/notifications/freelancer_notifications_screen.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:flutter/material.dart';


class FreelancerDashboardScreen extends StatefulWidget {
  final String freelancerId;

  const FreelancerDashboardScreen({
    super.key,
    required this.freelancerId,
  });

  @override
  State<FreelancerDashboardScreen> createState() =>
      _FreelancerDashboardScreenState();
}

class _FreelancerDashboardScreenState extends State<FreelancerDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
  }

  void _openComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title screen will be connected next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 420 ? 2 : 2;
    final ratio = width >= 420 ? 1.72 : 1.55;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
          _TopGlassIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {
              GoToScreen(context: context, screen: FreelancerNotificationsScreen(freelancerId: widget.freelancerId,));
            },
          ),
          const SizedBox(width: 10),
          _TopGlassIconButton(
            icon: Icons.refresh_rounded,
            onTap: _refresh,
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _FreelancerWelcomeCard(
                    freelancerId: widget.freelancerId,
                    db: _db,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Profile Summary',
                    subtitle: 'Verification and professional overview',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _ProfileSummaryCard(
                    freelancerId: widget.freelancerId,
                    db: _db,
                    onOpenProfile: () {
                      GoToScreen(context: context, screen: FreelancerProfileScreen(freelancerId: widget.freelancerId,));
                    },
                    onUploadCertificate: () {
                      GoToScreen(context: context, screen: FreelancerCertificatesPortfolioScreen( freelancerId: widget.freelancerId,));
                    },

                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Activity Overview',
                    subtitle: 'Quick numbers from your account',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate.fixed(
                    [
                      _DashboardKpiCard(
                        title: 'Available Jobs',
                        icon: Icons.work_outline_rounded,
                        tint: AppColors.info,
                        future: _safeCount(_db
                            .collection('jobs')
                            .where('status', isEqualTo: 'open')),
                      ),
                      _DashboardKpiCard(
                        title: 'Active Contracts',
                        icon: Icons.assignment_turned_in_outlined,
                        tint: AppColors.success,
                        future: _safeCount(_db
                            .collection('contracts')
                            .where('freelancerId',
                            isEqualTo: widget.freelancerId)
                            .where('status', isEqualTo: 'active')),
                      ),
                      _DashboardKpiCard(
                        title: 'Pending Payments',
                        icon: Icons.payments_outlined,
                        tint: AppColors.warning,
                        future: _safeCount(_db
                            .collection('payments')
                            .where('freelancerId',
                            isEqualTo: widget.freelancerId)
                            .where('status', isEqualTo: 'pending')),
                      ),
                      _AverageRatingKpiCard(
                        freelancerId: widget.freelancerId,
                        db: _db,
                      ),
                    ],
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: ratio,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Quick Actions',
                    subtitle: 'Fast access to your main tools',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _QuickActionsGrid(
                    onBrowseJobs: () {
                      GoToScreen(context: context, screen: FreelancerJobsLayout( freelancerId: widget.freelancerId,));
                    },
                    onOpenWork: () {
                      GoToScreen(context: context, screen: ContractsListScreen( freelancerId: widget.freelancerId,));
                    },
                    onOpenProfile: () {
                      GoToScreen(context: context, screen: FreelancerProfileScreen( freelancerId: widget.freelancerId,));
                    },
                    onUploadCertificate: () {
                      GoToScreen(context: context, screen: FreelancerCertificatesPortfolioScreen( freelancerId: widget.freelancerId,));
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Recent Notifications',
                    subtitle: 'Latest updates related to your account',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                sliver: SliverToBoxAdapter(
                  child: _RecentNotificationsPreview(
                    freelancerId: widget.freelancerId,
                    db: _db,
                    onOpenAll: (){
                      GoToScreen(context: context, screen: FreelancerNotificationsScreen(freelancerId:widget.freelancerId,));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _safeCount(Query query) async {
    try {
      final agg = await query.count().get();
      return agg.count ?? 0;
    } catch (_) {
      final snap = await query.get();
      return snap.size;
    }
  }
}

class _FreelancerWelcomeCard extends StatelessWidget {
  final String freelancerId;
  final FirebaseFirestore db;

  const _FreelancerWelcomeCard({
    required this.freelancerId,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: db.collection('users').doc(freelancerId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 110, child: _SoftLoadingBox());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox(
              height: 110,
              child: _EmptyStateRow(
                icon: Icons.person_outline_rounded,
                text: 'Failed to load freelancer information.',
              ),
            );
          }

          final data = snapshot.data!.data() ?? {};
          final fullName = (data['fullName'] ?? 'Freelancer').toString().trim();
          final city = (data['city'] ?? '').toString().trim();
          final photoUrl = (data['photoUrl'] ?? '').toString().trim();

          return Row(
            children: [
              _UserAvatar(
                name: fullName,
                photoUrl: photoUrl,
                size: 62,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName.isEmpty ? 'Freelancer' : fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city.isEmpty ? 'City not added yet' : city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
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
}

class _ProfileSummaryCard extends StatelessWidget {
  final String freelancerId;
  final FirebaseFirestore db;
  final VoidCallback onOpenProfile;
  final VoidCallback onUploadCertificate;

  const _ProfileSummaryCard({
    required this.freelancerId,
    required this.db,
    required this.onOpenProfile,
    required this.onUploadCertificate,
  });

  @override
  Widget build(BuildContext context) {
    final userFuture = db.collection('users').doc(freelancerId).get();
    final profileFuture =
    db.collection('users').doc(freelancerId).collection('profile').doc('main').get();
    final certsFuture =
    db.collection('users').doc(freelancerId).collection('certificates').get();

    return _GlassCard(
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([userFuture, profileFuture, certsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 170, child: _SoftLoadingBox());
          }

          if (!snapshot.hasData) {
            return const _EmptyStateRow(
              icon: Icons.info_outline_rounded,
              text: 'Failed to load profile summary.',
            );
          }

          final userSnap =
          snapshot.data![0] as DocumentSnapshot<Map<String, dynamic>>;
          final profileSnap =
          snapshot.data![1] as DocumentSnapshot<Map<String, dynamic>>;
          final certsSnap = snapshot.data![2] as QuerySnapshot<Map<String, dynamic>>;

          final userData = userSnap.data() ?? {};
          final profileData = profileSnap.data() ?? {};

          final title = (profileData['title'] ?? '').toString().trim();
          final bio = (profileData['bio'] ?? '').toString().trim();
          final isActive = (userData['isActive'] ?? false) == true;

          final certDocs = certsSnap.docs;
          final verifiedCount = certDocs
              .where((e) =>
          (e.data()['verifyStatus'] ?? '').toString().toLowerCase() ==
              'verified')
              .length;
          final pendingCount = certDocs
              .where((e) =>
          (e.data()['verifyStatus'] ?? '').toString().toLowerCase() ==
              'pending')
              .length;
          final rejectedCount = certDocs
              .where((e) =>
          (e.data()['verifyStatus'] ?? '').toString().toLowerCase() ==
              'rejected')
              .length;

          final skills = _extractListFromDynamic(profileData['skills']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MiniBadge(
                    label: isActive ? 'Active' : 'Inactive',
                    bg: (isActive ? AppColors.success : AppColors.error)
                        .withOpacity(0.12),
                    fg: isActive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  _MiniBadge(
                    label: '$verifiedCount Verified',
                    bg: AppColors.success.withOpacity(0.12),
                    fg: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _MiniBadge(
                    label: '$pendingCount Pending',
                    bg: AppColors.warning.withOpacity(0.12),
                    fg: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title.isEmpty ? 'Professional title not added yet' : title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                bio.isEmpty
                    ? 'Your professional bio is not complete yet.'
                    : bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.isEmpty
                    ? [
                  _SkillChip(label: 'No skills added yet'),
                ]
                    : skills.take(6).map((e) => _SkillChip(label: e)).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TinyInfoCard(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Certificates',
                      value: certDocs.length.toString(),
                      tint: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TinyInfoCard(
                      icon: Icons.cancel_outlined,
                      title: 'Rejected',
                      value: rejectedCount.toString(),
                      tint: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionOutlineButton(
                      text: 'Open Profile',
                      icon: Icons.person_outline_rounded,
                      onTap: onOpenProfile,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionFilledButton(
                      text: 'Upload Certificate',
                      icon: Icons.upload_file_rounded,
                      onTap: onUploadCertificate,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> _extractListFromDynamic(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is Map) {
      return value.entries
          .where((e) => e.value == true || e.value.toString().trim().isNotEmpty)
          .map((e) => e.key.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }
}

class _DashboardKpiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final Future<int> future;

  const _DashboardKpiCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: FutureBuilder<int>(
        future: future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final value = snapshot.data ?? 0;

          return Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: tint, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: loading
                    ? const _KpiLoadingColumn()
                    : Column(
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
                      value.toString(),
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
          );
        },
      ),
    );
  }
}

class _AverageRatingKpiCard extends StatelessWidget {
  final String freelancerId;
  final FirebaseFirestore db;

  const _AverageRatingKpiCard({
    required this.freelancerId,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: db.collection('users').doc(freelancerId).get(),
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;

          double rating = 0;
          int count = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() ?? {};
            final rawRating = data['ratingAvg'];
            final rawCount = data['ratingCount'];

            if (rawRating is num) rating = rawRating.toDouble();
            if (rawCount is num) count = rawCount.toInt();
          }

          return Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: loading
                    ? const _KpiLoadingColumn()
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Rating',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($count)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onBrowseJobs;
  final VoidCallback onOpenWork;
  final VoidCallback onOpenProfile;
  final VoidCallback onUploadCertificate;

  const _QuickActionsGrid({
    required this.onBrowseJobs,
    required this.onOpenWork,
    required this.onOpenProfile,
    required this.onUploadCertificate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Browse Jobs',
                subtitle: 'Find open jobs',
                icon: Icons.search_rounded,
                gradient: AppColors.blueGradient,
                onTap: onBrowseJobs,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Open Work',
                subtitle: 'View contracts',
                icon: Icons.assignment_outlined,
                gradient: AppColors.successGradient,
                onTap: onOpenWork,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Open Profile',
                subtitle: 'View your profile',
                icon: Icons.person_outline_rounded,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E88E5),
                    Color(0xFF1565C0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: onOpenProfile,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Upload Certificate',
                subtitle: 'Add new document',
                icon: Icons.workspace_premium_outlined,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00C853),
                    Color(0xFF009624),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: onUploadCertificate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentNotificationsPreview extends StatelessWidget {
  final String freelancerId;
  final FirebaseFirestore db;
  final VoidCallback onOpenAll;

  const _RecentNotificationsPreview({
    required this.freelancerId,
    required this.db,
    required this.onOpenAll,
  });

  @override
  Widget build(BuildContext context) {
    final stream = db
        .collection('notifications')
        .where('recipientId', isEqualTo: freelancerId)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();

    return _GlassCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _EmptyStateRow(
              icon: Icons.notifications_off_outlined,
              text: 'Failed to load notifications.',
            );
          }

          if (!snapshot.hasData) {
            return const SizedBox(height: 170, child: _SoftLoadingBox());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Column(
              children: [
                const _EmptyStateRow(
                  icon: Icons.notifications_none_rounded,
                  text: 'No notifications yet.',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onOpenAll,
                    child: const Text(
                      'Open Notifications',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            );
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onOpenAll,
                  child: const Text(
                    'See All',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
    final isRead = (data['isRead'] ?? false) == true;
    final createdAt = data['createdAt'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (isRead ? AppColors.textLight : AppColors.primary)
                .withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isRead
                ? Icons.mark_email_read_outlined
                : Icons.notifications_active_outlined,
            color: isRead ? AppColors.textSecondary : AppColors.primary,
            size: 21,
          ),
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
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body.isEmpty ? 'No details available.' : body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _formatTimestamp(createdAt),
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return 'Recently';
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _two(int value) => value < 10 ? '0$value' : '$value';
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
          ),
        ),
      ],
    );
  }
}

class _TopGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopGlassIconButton({
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
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
              color: Colors.white.withOpacity(0.6),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.7),
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

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionFilledButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionFilledButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionOutlineButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionOutlineButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: BorderSide(color: AppColors.primary.withOpacity(0.24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _TinyInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color tint;

  const _TinyInfoCard({
    required this.icon,
    required this.title,
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
              color: tint.withOpacity(0.16),
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
                  title,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
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

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _MiniBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final double size;

  const _UserAvatar({
    required this.name,
    required this.photoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.16),
            width: 2,
          ),
        ),
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(),
        ),
      );
    }

    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    final first = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'F';

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        first,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyStateRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyStateRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary),
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

class _KpiLoadingColumn extends StatelessWidget {
  const _KpiLoadingColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LineLoader(width: 70, height: 10),
        SizedBox(height: 8),
        _LineLoader(width: 34, height: 18),
      ],
    );
  }
}

class _LineLoader extends StatelessWidget {
  final double width;
  final double height;

  const _LineLoader({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textLight.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}