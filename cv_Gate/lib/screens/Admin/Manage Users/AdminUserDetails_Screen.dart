import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Manage%20Users/CertificatesVerification_Screen.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:flutter/material.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final String uid;
  const AdminUserDetailsScreen({super.key, required this.uid});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  String _roleLabel(String raw) {
    final r = raw.trim().toLowerCase();
    if (r == 'client' || r == 'job_seeker') return 'Client';
    if (r == 'freelancer' || r == 'technician') return 'Freelancer';
    if (r == 'admin' || r == 'administrator') return 'Admin';
    if (r.isEmpty) return 'Unknown';
    return r[0].toUpperCase() + r.substring(1);
  }

  bool _isFreelancerRole(String raw) {
    final r = raw.trim().toLowerCase();
    return r == 'freelancer' || r == 'technician';
  }

  Color _roleTint(String roleLabel) {
    final s = roleLabel.toLowerCase();
    if (s == 'client') return const Color(0xFF2563EB);
    if (s == 'freelancer') return const Color(0xFF7C3AED);
    if (s == 'admin') return const Color(0xFF0C4A6E);
    return const Color(0xFF64748B);
  }

  Future<int> _pendingCertificatesCount() async {
    try {
      final q = _db
          .collection('users')
          .doc(widget.uid)
          .collection('certificates')
          .where('verifyStatus', isEqualTo: 'pending');

      try {
        final agg = await q.count().get();
        return agg.count??0;
      } catch (_) {
        final snap = await q.get();
        return snap.size;
      }
    } catch (_) {
      return 0;
    }
  }

  Future<void> _setActive(bool active) async {
    await _db.collection('users').doc(widget.uid).update({'isActive': active});
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1000)),
    );
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 26,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: confirmColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, color: confirmColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Colors.black.withOpacity(0.45)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _brandNavy,
                                side: BorderSide(color: _brandNavy.withOpacity(0.22)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRef = _db.collection('users').doc(widget.uid);

    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            "User Details",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text("Failed to load user", style: TextStyle(color: _textMuted, fontWeight: FontWeight.w900)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)));
          }

          final data = snap.data!.data();
          if (data == null) {
            return const Center(
              child: Text("User not found", style: TextStyle(color: _textMuted, fontWeight: FontWeight.w900)),
            );
          }

          final fullName = (data['fullName'] ?? '').toString().trim();
          final email = (data['email'] ?? '').toString().trim();
          final city = (data['city'] ?? '').toString().trim();
          final photoUrl = (data['photoUrl'] ?? '').toString().trim();

          final roleRaw = (data['role'] ?? '').toString();
          final isFreelancer = _isFreelancerRole(roleRaw);
          final role = _roleLabel(roleRaw);

          final isActive = (data['isActive'] is bool) ? data['isActive'] as bool : true;

          final ratingAvg = data['ratingAvg'];
          final ratingCount = data['ratingCount'];
          final avg = (ratingAvg is num) ? ratingAvg.toDouble() : 0.0;
          final cnt = (ratingCount is num) ? ratingCount.toInt() : 0;

          final tint = _roleTint(role);
          final nameDisplay = fullName.isNotEmpty ? fullName : "Unknown name";
          final emailDisplay = email.isNotEmpty ? email : "No email";

          final profileRef = _db.collection('users').doc(widget.uid).collection('profile').doc('main');

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _GlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(
                        name: nameDisplay,
                        tint: tint,
                        photoUrl: photoUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(
                              icon: Icons.alternate_email_rounded,
                              text: emailDisplay,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              text: role,
                              iconColor: tint,
                              textColor: tint,
                              bold: true,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: isActive ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                              text: isActive ? "Active" : "Suspended",
                              iconColor: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              textColor: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              bold: true,
                            ),
                            if (city.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.location_city_rounded,
                                text: city,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  child: Column(
                    children: [
                      _StatRow(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: "Rating",
                        value: cnt > 0 ? avg.toStringAsFixed(1) : "0.0",
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        icon: Icons.rate_review_outlined,
                        iconColor: _textMuted,
                        title: "Reviews",
                        value: "$cnt",
                      ),
                      if (isFreelancer) ...[
                        const SizedBox(height: 12),
                        FutureBuilder<int>(
                          future: _pendingCertificatesCount(),
                          builder: (context, certSnap) {
                            final pending = certSnap.data ?? 0;
                            return _StatRow(
                              icon: Icons.verified_outlined,
                              iconColor: _textMuted,
                              title: "Pending certificates",
                              valueWidget: _CountPill(count: pending),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isFreelancer
                      ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: profileRef.snapshots(),
                    builder: (context, pSnap) {
                      if (pSnap.hasError) {
                        return const _GlassCard(
                          child: _EmptyInsideCard(
                            icon: Icons.error_outline_rounded,
                            title: "Profile info not available",
                            subtitle: "Failed to load freelancer profile",
                          ),
                        );
                      }
                      if (!pSnap.hasData) {
                        return const _GlassCard(
                          child: Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3))),
                        );
                      }

                      final pData = pSnap.data!.data();
                      if (pData == null) {
                        return const _GlassCard(
                          child: _EmptyInsideCard(
                            icon: Icons.person_outline_rounded,
                            title: "Freelancer profile is empty",
                            subtitle: "No profile details found",
                          ),
                        );
                      }

                      final title = (pData['title'] ?? '').toString().trim();
                      final bio = (pData['bio'] ?? '').toString().trim();

                      final skillsRaw = pData['skills'];
                      final skills = <String>[];
                      if (skillsRaw is Map) {
                        skillsRaw.forEach((k, v) {
                          if (v == true) skills.add(k.toString());
                        });
                      }

                      final portfolioRaw = pData['portfolioLinks'];
                      final portfolio = <Map<String, String>>[];
                      if (portfolioRaw is Map) {
                        portfolioRaw.forEach((k, v) {
                          if (v is Map) {
                            final t = (v['title'] ?? '').toString().trim();
                            final u = (v['url'] ?? '').toString().trim();
                            if (t.isNotEmpty || u.isNotEmpty) {
                              portfolio.add({'title': t, 'url': u});
                            }
                          }
                        });
                      }

                      return _GlassCard(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _CardTitleRow(
                                icon: Icons.work_outline_rounded,
                                title: "Freelancer Profile",
                              ),
                              if (title.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _InfoRow(
                                  icon: Icons.title_rounded,
                                  text: title,
                                  bold: true,
                                  textColor: _textDark,
                                  iconColor: _textMuted,
                                ),
                              ],
                              if (bio.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const _SmallLabel(icon: Icons.subject_rounded, text: "Bio"),
                                const SizedBox(height: 8),
                                Text(
                                  bio,
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              if (skills.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const _SmallLabel(icon: Icons.auto_awesome_rounded, text: "Skills"),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills
                                      .map(
                                        (s) => _SkillChip(label: s),
                                  )
                                      .toList(),
                                ),
                              ],
                              if (portfolio.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const _SmallLabel(icon: Icons.link_rounded, text: "Portfolio Links"),
                                const SizedBox(height: 10),
                                Column(
                                  children: portfolio.map((item) {
                                    final t = item['title'] ?? '';
                                    final u = item['url'] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _LinkRow(title: t, url: u),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (title.isEmpty && bio.isEmpty && skills.isEmpty && portfolio.isEmpty) ...[
                                const SizedBox(height: 10),
                                const _EmptyInsideCard(
                                  icon: Icons.info_outline_rounded,
                                  title: "No extra profile details",
                                  subtitle: "This freelancer has not completed profile info",
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  )
                      : const SizedBox(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isActive ? const Color(0xFFDC2626) : const Color(0xFF059669),
                          side: BorderSide(
                            color: (isActive ? const Color(0xFFDC2626) : const Color(0xFF059669)).withOpacity(0.25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final wantSuspend = isActive;
                          final ok = await _confirmAction(
                            title: wantSuspend ? "Suspend user" : "Activate user",
                            message: wantSuspend
                                ? "This user will not be able to use the app until activated again."
                                : "This user will regain access to the app.",
                            confirmText: wantSuspend ? "Suspend" : "Activate",
                            confirmColor: wantSuspend ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            icon: wantSuspend ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                          );
                          if (ok != true) return;

                          try {
                            await _setActive(!wantSuspend);
                            _toast(wantSuspend ? "User suspended" : "User activated");
                          } catch (_) {
                            _toast("Action failed");
                          }
                        },
                        child: Text(isActive ? "Suspend" : "Activate", style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    isFreelancer? Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFreelancer ? _brandNavy : _textMuted.withOpacity(0.35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isFreelancer
                            ? () {

                          GoToScreen(context: context, screen: CertificatesVerificationScreen(uid: widget.uid,));
                        }
                            : null,
                        child: const Text("Certificates", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ):SizedBox(),

                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color tint;
  final String photoUrl;

  const _Avatar({
    required this.name,
    required this.tint,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.trim().characters.first.toUpperCase() : "U";

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: tint.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: photoUrl.isNotEmpty
            ? Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Center(
              child: Text(
                initial,
                style: TextStyle(color: tint, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            );
          },
        )
            : Center(
          child: Text(
            initial,
            style: TextStyle(color: tint, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;
  final bool bold;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
    this.bold = false,
  });

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? _textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor ?? _textMuted,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              fontSize: 12.8,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final Widget? valueWidget;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    this.valueWidget,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (valueWidget != null) valueWidget!,
        if (valueWidget == null)
          Text(value ?? "-", style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final bg = count > 0 ? const Color(0xFFF59E0B).withOpacity(0.14) : const Color(0xFF64748B).withOpacity(0.12);
    final fg = count > 0 ? const Color(0xFFF59E0B) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        "$count",
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _CardTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardTitleRow({required this.icon, required this.title});

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 14.5),
        ),
      ],
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SmallLabel({required this.icon, required this.text});

  static const _textMuted = Color(0xFF64748B);
  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 13.5),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  static const _brandNavy = Color(0xFF0A2A43);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _brandNavy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w900, fontSize: 12.3),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String title;
  final String url;
  const _LinkRow({required this.title, required this.url});

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final t = title.isNotEmpty ? title : "Link";
    final u = url.isNotEmpty ? url : "No URL";

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link_rounded, size: 18, color: _textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.public_rounded, size: 18, color: _textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    u,
                    style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInsideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyInsideCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: _textMuted.withOpacity(0.85)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 14.5),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ],
      ),
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