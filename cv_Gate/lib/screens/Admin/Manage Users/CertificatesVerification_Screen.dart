import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesVerificationScreen extends StatefulWidget {
  final String uid;
  const CertificatesVerificationScreen({super.key, required this.uid});

  @override
  State<CertificatesVerificationScreen> createState() => _CertificatesVerificationScreenState();
}

class _CertificatesVerificationScreenState extends State<CertificatesVerificationScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1100)),
    );
  }

  Color _statusColor(String s) {
    final v = s.trim().toLowerCase();
    if (v == 'verified') return const Color(0xFF059669);
    if (v == 'rejected') return const Color(0xFFDC2626);
    return const Color(0xFFF59E0B);
  }

  String _statusLabel(String s) {
    final v = s.trim().toLowerCase();
    if (v == 'verified') return 'Verified';
    if (v == 'rejected') return 'Rejected';
    return 'Pending';
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) {
      _toast("Invalid file URL");
      return;
    }
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok) _toast("Cannot open certificate");
  }

  Future<void> _handleDecision({
    required String certDocId,
    required String currentStatus,
    required bool approve,
  }) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DecisionSheet(
        approve: approve,
        currentStatus: currentStatus,
      ),
    );

    if (note == null) return;

    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';

    try {
      await _db
          .collection('users')
          .doc(widget.uid)
          .collection('certificates')
          .doc(certDocId)
          .update({
        'verifyStatus': approve ? 'verified' : 'rejected',
        'verifyNote': note.trim(),
        'verifiedBy': adminUid,
      });

      _toast(approve ? "Certificate approved" : "Certificate rejected");
    } catch (_) {
      _toast("Update failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final certsRef = _db
        .collection('users')
        .doc(widget.uid)
        .collection('certificates')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: _bgSlate,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            "Certificates Verification",
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _GlassCard(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: certsRef.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: "Failed to load certificates",
                  subtitle: "Please try again later",
                );
              }

              if (!snap.hasData) {
                return const Center(
                  child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                );
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const _EmptyState(
                  icon: Icons.verified_outlined,
                  title: "No certificates found",
                  subtitle: "This user has not uploaded certificates",
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Divider(
                  height: 18,
                  color: Colors.black.withOpacity(0.06),
                ),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data();

                  final name = (d['name'] ?? '').toString().trim();
                  final issuer = (d['issuer'] ?? '').toString().trim();
                  final issueDate = (d['issueDate'] ?? '').toString().trim();
                  final fileUrl = (d['fileUrl'] ?? '').toString().trim();

                  final verifyStatus = (d['verifyStatus'] ?? 'pending').toString().trim();
                  final verifyNote = (d['verifyNote'] ?? '').toString().trim();
                  final verifiedBy = d['verifiedBy'];

                  final statusColor = _statusColor(verifyStatus);
                  final statusLabel = _statusLabel(verifyStatus);

                  final title = name.isNotEmpty ? name : "Certificate";
                  final subtitleIssuer = issuer.isNotEmpty ? issuer : "Unknown issuer";
                  final subtitleDate = issueDate.isNotEmpty ? issueDate : "Unknown date";

                  return InkWell(
                    onTap: fileUrl.isNotEmpty ? () => _openUrl(fileUrl) : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.workspace_premium_rounded, color: statusColor),
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
                                        color: _textDark,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                  _StatusPill(label: statusLabel, color: statusColor),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.school_outlined, size: 18, color: _textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subtitleIssuer,
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.8,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.event_outlined, size: 18, color: _textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subtitleDate,
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (verifyNote.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes_rounded, size: 18, color: _textMuted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        verifyNote,
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.8,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (verifiedBy != null && verifiedBy.toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined, size: 18, color: _textMuted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Verified by: ${verifiedBy.toString()}",
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _brandNavy,
                                        side: BorderSide(color: _brandNavy.withOpacity(0.20)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: fileUrl.isEmpty ? null : () => _openUrl(fileUrl),
                                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                      label: const Text("View", style: TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: () => _handleDecision(
                                        certDocId: doc.id,
                                        currentStatus: verifyStatus,
                                        approve: true,
                                      ),
                                      icon: const Icon(Icons.check_rounded, size: 18),
                                      label: const Text("Approve", style: TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFDC2626),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: () => _handleDecision(
                                        certDocId: doc.id,
                                        currentStatus: verifyStatus,
                                        approve: false,
                                      ),
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DecisionSheet extends StatefulWidget {
  final bool approve;
  final String currentStatus;
  const _DecisionSheet({required this.approve, required this.currentStatus});

  @override
  State<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends State<_DecisionSheet> {
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.approve ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final title = widget.approve ? "Approve Certificate" : "Reject Certificate";
    final btn = widget.approve ? "Approve" : "Reject";

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + MediaQuery.of(context).viewInsets.bottom),
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
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(widget.approve ? Icons.check_rounded : Icons.close_rounded, color: color),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: Colors.black.withOpacity(0.45)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Write a note (optional).",
                          style: const TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _NoteField(controller: _c),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A2A43),
                            side: BorderSide(color: const Color(0xFF0A2A43).withOpacity(0.22)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.pop(context, _c.text),
                          child: Text(btn, style: const TextStyle(fontWeight: FontWeight.w900)),
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
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark),
      decoration: InputDecoration(
        hintText: "Optional note",
        filled: true,
        fillColor: Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0A2A43), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: _textMuted.withOpacity(0.85)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
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
    );
  }
}