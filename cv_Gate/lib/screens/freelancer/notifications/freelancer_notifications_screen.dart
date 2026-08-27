import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:cv_gate/screens/freelancer/Profile/freelancer_certificates_portfolio_screen.dart';
import 'package:cv_gate/screens/freelancer/Works/ContractDetailsScreen.dart';
import 'package:cv_gate/screens/freelancer/jobs/JobDetailsScreen.dart';
import 'package:cv_gate/screens/freelancer/jobs/MyApplicationsScreen.dart';
import 'package:cv_gate/screens/freelancer/payments/PaymentDetailsScreen.dart';
import 'package:cv_gate/screens/freelancer/reviews/FreelancerReviews_Screen.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FreelancerNotificationsScreen extends StatefulWidget {
  final freelancerId;
  const FreelancerNotificationsScreen({required this.freelancerId,super.key});

  @override
  State<FreelancerNotificationsScreen> createState() => _FreelancerNotificationsScreenState();
}

class _FreelancerNotificationsScreenState extends State<FreelancerNotificationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _refreshing = false;

  // String? get freelancerId => _auth.currentUser?.uid;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  Future<void> _openNotification(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final notifId = doc.id;
    final isRead = data['isRead'] == true;
    final refType = (data['refType'] ?? '').toString().trim();
    final refId = (data['refId'] ?? '').toString().trim();

    if (!isRead) {
      try {
        await _db.collection('notifications').doc(notifId).set({
          'isRead': true,
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (refType.isEmpty || refId.isEmpty) {
      _showSnack('No related item found for this notification.', AppColors.warning);
      return;
    }

    if (refType == 'jobs' || refType == 'job') {
      GoToScreen(context: context, screen: JobDetailsScreen(jobId: refId, freelancerId: widget.freelancerId));

      return;
    }

    if (refType == 'applications' || refType == 'application') {
      GoToScreen(context: context, screen: MyApplicationsScreen(freelancerId: widget.freelancerId,));

      return;
    }

    if (refType == 'contract' || refType == 'contracts') {
      GoToScreen(context: context, screen: ContractDetailsScreen(contractId: refId, freelancerId: widget.freelancerId,));

      return;
    }

    if (refType == 'payment' || refType == 'payments') {
      GoToScreen(context: context, screen: PaymentDetailsScreen(paymentId: refId,));


      return;
    }

    if (refType == 'reviews' || refType == 'review') {
      GoToScreen(context: context, screen: FreelancerReviewsScreen(freelancerId: widget.freelancerId,));

      return;
    }

    if (refType == 'certificates' || refType == 'certificate') {
      GoToScreen(context: context, screen: FreelancerCertificatesPortfolioScreen( freelancerId: widget.freelancerId,));

      return;
    }

    _showSnack('This notification does not have a supported destination yet.', AppColors.info);
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final unreadDocs = docs.where((e) => e.data()['isRead'] != true).toList();

    if (unreadDocs.isEmpty) {
      _showSnack('All notifications are already read.', AppColors.info);
      return;
    }

    try {
      final batch = _db.batch();
      for (final doc in unreadDocs) {
        batch.set(
          _db.collection('notifications').doc(doc.id),
          {'isRead': true},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      _showSnack('All notifications marked as read.', AppColors.success);
    } catch (_) {
      _showSnack('Failed to mark notifications as read.', AppColors.error);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'Recently';
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _two(int value) => value < 10 ? '0$value' : '$value';

  String _formatType(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'proposal') return 'Proposal';
    if (t == 'contract') return 'Contract';
    if (t == 'payment') return 'Payment';
    if (t == 'review') return 'Review';
    if (t == 'certificate') return 'Certificate';
    if (t == 'system') return 'System';
    return type.isEmpty ? 'Update' : type;
  }

  Color _typeColor(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'proposal') return AppColors.info;
    if (t == 'contract') return AppColors.primary;
    if (t == 'payment') return AppColors.success;
    if (t == 'review') return AppColors.warning;
    if (t == 'certificate') return AppColors.primary;
    return AppColors.textSecondary;
  }

  IconData _typeIcon(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'proposal') return Icons.campaign_outlined;
    if (t == 'contract') return Icons.description_outlined;
    if (t == 'payment') return Icons.payments_outlined;
    if (t == 'review') return Icons.star_outline_rounded;
    if (t == 'certificate') return Icons.workspace_premium_outlined;
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.freelancerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _NotLoggedInState(),
      );
    }

    final notificationsStream = _db
        .collection('notifications')
        .where('recipientId', isEqualTo: widget.freelancerId)
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
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _refreshing ? null : _refresh,
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: const [
                  _ErrorCard(
                    text: 'Failed to load notifications.',
                  ),
                ],
              );
            }

            if (!snapshot.hasData) {
              return const _LoadingView();
            }

            final docs = snapshot.data!.docs;
            final unreadCount = docs.where((e) => e.data()['isRead'] != true).length;

            if (docs.isEmpty) {
              return ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: const [
                  _EmptyCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    subtitle: 'Your system updates and alerts will appear here.',
                  ),
                ],
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _GlassCard(
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
                              Icons.notifications_active_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'System Updates',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$unreadCount unread notifications',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _markAllAsRead(docs),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
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
                      title: 'Notifications List',
                      subtitle: 'Tap any notification to open the related item',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      final title = (data['title'] ?? 'Notification').toString().trim();
                      final body = (data['body'] ?? '').toString().trim();
                      final type = (data['type'] ?? 'system').toString().trim();
                      final isRead = data['isRead'] == true;
                      final createdAt = data['createdAt'];

                      return _NotificationCard(
                        title: title.isEmpty ? 'Notification' : title,
                        body: body.isEmpty ? 'No details available.' : body,
                        date: _formatTime(createdAt),
                        isRead: isRead,
                        icon: _typeIcon(type),
                        typeLabel: _formatType(type),
                        tint: _typeColor(type),
                        onTap: () => _openNotification(doc),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
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

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final bool isRead;
  final IconData icon;
  final String typeLabel;
  final Color tint;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.date,
    required this.isRead,
    required this.icon,
    required this.typeLabel,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isRead
                  ? Colors.white.withOpacity(0.55)
                  : tint.withOpacity(0.28),
              width: isRead ? 1.2 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tint.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: tint,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: isRead ? FontWeight.w800 : FontWeight.w900,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: tint,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: icon,
                            text: typeLabel,
                            tint: tint,
                          ),
                          _MetaChip(
                            icon: Icons.access_time_rounded,
                            text: date,
                            tint: AppColors.textSecondary,
                            light: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color tint;
  final bool light;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.tint,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = light ? tint.withOpacity(0.08) : tint.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: tint,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: tint,
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
          child: SizedBox(height: 90, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 120, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 120, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 120, child: _SoftLoadingBox()),
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

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String text;

  const _ErrorCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotLoggedInState extends StatelessWidget {
  const _NotLoggedInState();

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
              Icons.lock_outline_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'You need to login first.',
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