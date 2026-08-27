import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatelessWidget {
  final String adminId;

  const AdminNotificationsScreen({
    super.key,
    required this.adminId,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminNotificationsBody(adminId: adminId);
  }
}

class _AdminNotificationsBody extends StatefulWidget {
  final String adminId;

  const _AdminNotificationsBody({
    required this.adminId,
  });

  @override
  State<_AdminNotificationsBody> createState() => _AdminNotificationsBodyState();
}

class _AdminNotificationsBodyState extends State<_AdminNotificationsBody> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  Future<void> _markAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({
      'isRead': true,
    });
  }

  String _formatDate(Timestamp ts) {
    final date = ts.toDate();
    return "${date.year}-${date.month}-${date.day}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  IconData _iconByType(String type) {
    if (type == "contract_update") return Icons.description_outlined;
    if (type == "payment_update") return Icons.payments_outlined;
    if (type == "dispute_update") return Icons.warning_amber_outlined;
    if (type == "job_update") return Icons.work_outline_rounded;
    return Icons.notifications_none_rounded;
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
          title: const Text(
            "Notifications",
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
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('notifications')
            .where('recipientId', isEqualTo: widget.adminId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const _CenteredState(
              icon: Icons.error_outline_rounded,
              title: "Failed to load notifications",
              subtitle: "Please try again later",
            );
          }

          if (!snap.hasData) {
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const _CenteredState(
              icon: Icons.notifications_off_outlined,
              title: "No Notifications",
              subtitle: "You don't have any notifications yet",
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data();

                final notifId = (data['notifId'] ?? docs[i].id).toString();
                final title = (data['title'] ?? '').toString();
                final body = (data['body'] ?? '').toString();
                final type = (data['type'] ?? '').toString();
                final isRead = (data['isRead'] ?? false) == true;
                final createdAt = data['createdAt'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GlassCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        if (!isRead) {
                          await _markAsRead(notifId);
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            child: Icon(
                              _iconByType(type),
                              color: Colors.white,
                              size: 20,
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
                                        style: const TextStyle(
                                          color: _textDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.6,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (createdAt != null)
                                  Text(
                                    _formatDate(createdAt),
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
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
            Icon(icon, size: 36, color: _textMuted),
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