import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/contracts/client_contract_details_screen.dart';
import 'package:cv_gate/screens/client/contracts/client_submission_review_screen.dart';
import 'package:cv_gate/screens/client/jobs/JobDetails_Screen.dart';
import 'package:cv_gate/screens/client/payments/client_payment_details_screen.dart';
import 'package:cv_gate/screens/client/profile/ClientProfile_Screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  State<ClientNotificationsScreen> createState() => _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Query<Map<String, dynamic>> _buildQuery() {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);
  }

  Future<void> _markAsRead(String notifId) async {
    try {
      await _db.collection('notifications').doc(notifId).update({
        'isRead': true,
      });
    } catch (_) {}
  }

  Future<void> _handleOpenRef(Map<String, dynamic> data, String notifId) async {
    await _markAsRead(notifId);


    final refType = (data['refType'] ?? '').toString().trim().toLowerCase();
    final refId = (data['refId'] ?? '').toString().trim();

    if (refId.isEmpty) return;

    // if (!mounted) return;
    print('aa $refType');

    if (refType == 'contract') {
      print('aaaaaaaaaaa');
      // await Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => ClientContractDetailsScreen(contractId: refId),
      //   ),
      // );
      GoToScreen(context: context, screen: ClientContractDetailsScreen(contractId: refId));
      return;
    }

    if (refType == 'payment') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientPaymentDetailsScreen(paymentId: refId),
        ),
      );
      return;
    }

    if (refType == 'job') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientJobDetailsScreen(jobId: refId),
        ),
      );
      return;
    }
    if (refType == 'submissions') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientSubmissionReviewScreen( contractId: refId,),
        ),
      );
      return;
    }

    if (refType == 'review') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientProfileScreen(),
        ),
      );
      return;
    }
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final unread = docs.where((e) => e.data()['isRead'] != true).toList();
    if (unread.isEmpty) return;

    const chunkSize = 400;

    for (int i = 0; i < unread.length; i += chunkSize) {
      final batch = _db.batch();
      final chunk = unread.skip(i).take(chunkSize);
      for (final doc in chunk) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
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
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];

                return TextButton(
                  onPressed: docs.isEmpty ? null : () => _markAllAsRead(docs),
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _buildQuery().snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: _GlassCard(
                  child: _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Failed to load notifications',
                    subtitle: 'Please try again later.',
                  ),
                ),
              );
            }

            if (!snap.hasData) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const _GlassCard(
                  child: SizedBox(height: 100, child: _SoftLoadingBox()),
                ),
              );
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications found',
                      subtitle: 'New system and workflow updates will appear here.',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final title = (data['title'] ?? 'Notification').toString();
                final body = (data['body'] ?? '').toString();
                final isRead = data['isRead'] == true;
                final createdAt = data['createdAt'];

                return _GlassCard(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _handleOpenRef(data, doc.id),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.textSecondary.withOpacity(0.12)
                                : AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isRead ? Icons.notifications_none_rounded : Icons.notifications_active_outlined,
                            color: isRead ? AppColors.textSecondary : AppColors.primary,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                body.isEmpty ? 'No details available.' : body,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.6,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _dateLabel(createdAt),
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

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