import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDisputeDetailsScreen extends StatefulWidget {
  final String disputeId;

  const AdminDisputeDetailsScreen({
    super.key,
    required this.disputeId,
  });

  @override
  State<AdminDisputeDetailsScreen> createState() => _AdminDisputeDetailsScreenState();
}

class _AdminDisputeDetailsScreenState extends State<AdminDisputeDetailsScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;
  final _noteController = TextEditingController();

  bool _saving = false;
  bool _noteInitialized = false;

  String _statusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'open') return 'Open';
    if (s == 'under_review') return 'Under Review';
    if (s == 'resolved') return 'Resolved';
    if (s == 'rejected') return 'Rejected';
    if (s.isEmpty) return 'Unknown';
    return raw;
  }

  Color _statusColor(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'open') return const Color(0xFFDC2626);
    if (s == 'under_review') return const Color(0xFFF59E0B);
    if (s == 'resolved') return const Color(0xFF059669);
    if (s == 'rejected') return const Color(0xFF64748B);
    return _textMuted;
  }

  String _contractStatusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'draft') return 'Draft';
    if (s == 'active') return 'Active';
    if (s == 'submitted') return 'Submitted';
    if (s == 'completed') return 'Completed';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'disputed') return 'Disputed';
    if (s.isEmpty) return 'Unknown';
    return raw;
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }
    return '—';
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final value = url.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contract link is not available")),
      );
      return;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid contract link")),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open contract link")),
      );
    }
  }

  Future<void> _updateDispute(String status) async {
    if (_saving) return;

    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin user not found")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _db.collection('disputes').doc(widget.disputeId).update({
        'status': status,
        'adminNote': _noteController.text.trim(),
        'handledBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'resolved'
                ? "Dispute resolved successfully"
                : "Dispute rejected successfully",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update dispute")),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
            "Dispute Details",
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('disputes').doc(widget.disputeId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const _CenteredState(
              icon: Icons.error_outline_rounded,
              title: "Failed to load dispute",
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

          if (!snap.data!.exists) {
            return const _CenteredState(
              icon: Icons.gavel_rounded,
              title: "Dispute not found",
              subtitle: "This dispute may have been removed",
            );
          }

          final data = snap.data!.data() ?? {};
          final contractId = (data['contractId'] ?? '').toString().trim();
          final jobId = (data['jobId'] ?? '').toString().trim();
          final clientId = (data['clientId'] ?? '').toString().trim();
          final freelancerId = (data['freelancerId'] ?? '').toString().trim();
          final createdBy = (data['createdBy'] ?? '').toString().trim();
          final reason = (data['reason'] ?? '').toString().trim();
          final details = (data['details'] ?? '').toString().trim();
          final status = (data['status'] ?? '').toString().trim();
          final adminNote = (data['adminNote'] ?? '').toString();
          final handledBy = (data['handledBy'] ?? '').toString().trim();
          final createdAt = data['createdAt'];
          final updatedAt = data['updatedAt'];

          if (!_noteInitialized) {
            _noteController.text = adminNote;
            _noteInitialized = true;
          }

          final statusColor = _statusColor(status);
          final canHandle = status == 'open' || status == 'under_review';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              children: [
                _HeaderCard(
                  icon: Icons.report_problem_outlined,
                  title: reason.isEmpty ? "Dispute Overview" : reason,
                  subtitle: _statusLabel(status),
                  tint: statusColor,
                ),
                const SizedBox(height: 12),
                _JobInfoCard(
                  db: _db,
                  jobId: jobId,
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  child: Column(
                    children: [
                      const _SectionTitle(
                        icon: Icons.info_outline_rounded,
                        title: "Dispute Information",
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(label: "Status", value: _statusLabel(status), valueColor: statusColor),
                      _InfoRow(label: "Reason", value: reason.isEmpty ? "—" : reason),
                      _InfoRow(label: "Details", value: details.isEmpty ? "—" : details),
                      _InfoRow(label: "Created At", value: _formatDate(createdAt)),
                      _InfoRow(label: "Updated At", value: _formatDate(updatedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  child: Column(
                    children: [
                      const _SectionTitle(
                        icon: Icons.people_alt_outlined,
                        title: "Related Users",
                      ),
                      const SizedBox(height: 14),
                      _UserInfoTile(
                        db: _db,
                        uid: createdBy,
                        label: "Created By",
                      ),
                      const SizedBox(height: 10),
                      _UserInfoTile(
                        db: _db,
                        uid: clientId,
                        label: "Client",
                      ),
                      const SizedBox(height: 10),
                      _UserInfoTile(
                        db: _db,
                        uid: freelancerId,
                        label: "Freelancer",
                      ),
                      if (handledBy.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _UserInfoTile(
                          db: _db,
                          uid: handledBy,
                          label: "Handled By",
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ContractInfoCard(
                  db: _db,
                  contractId: contractId,
                  onOpenUrl: (url) => _openUrl(context, url),
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(
                        icon: Icons.edit_note_rounded,
                        title: "Admin Note",
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _noteController,
                        maxLines: 5,
                        enabled: canHandle && !_saving,
                        decoration: InputDecoration(
                          hintText: "Write admin note here",
                          hintStyle: TextStyle(
                            color: _textMuted.withOpacity(0.8),
                            fontWeight: FontWeight.w700,
                          ),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.025),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide(
                              color: _brandNavy,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (canHandle)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : () => _updateDispute('rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFDC2626)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Text(
                                  "Reject",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : () => _updateDispute('resolved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brandNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  "Resolve",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.025),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: const Text(
                            "This dispute has already been handled.",
                            style: TextStyle(
                              color: _textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JobInfoCard extends StatelessWidget {
  final FirebaseFirestore db;
  final String jobId;

  const _JobInfoCard({
    required this.db,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context) {
    if (jobId.isEmpty) {
      return _GlassCard(
        child: Column(
          children: const [
            _SectionTitle(
              icon: Icons.work_outline_rounded,
              title: "Job Information",
            ),
            SizedBox(height: 14),
            _SimpleNote(text: "No related job found"),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('jobs').doc(jobId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const _GlassCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
          );
        }

        if (!snap.data!.exists) {
          return _GlassCard(
            child: Column(
              children: const [
                _SectionTitle(
                  icon: Icons.work_outline_rounded,
                  title: "Job Information",
                ),
                SizedBox(height: 14),
                _SimpleNote(text: "Job not found"),
              ],
            ),
          );
        }

        final data = snap.data!.data() ?? {};
        final title = (data['title'] ?? '').toString().trim();
        final category = (data['category'] ?? '').toString().trim();
        final status = (data['status'] ?? '').toString().trim();
        final budget = data['budget'];
        final currency = (data['currency'] ?? '').toString().trim();

        return _GlassCard(
          child: Column(
            children: [
              const _SectionTitle(
                icon: Icons.work_outline_rounded,
                title: "Job Information",
              ),
              const SizedBox(height: 14),
              _InfoRow(label: "Job Title", value: title.isEmpty ? "—" : title),
              _InfoRow(label: "Category", value: category.isEmpty ? "—" : category),
              _InfoRow(label: "Job Status", value: status.isEmpty ? "—" : status),
              _InfoRow(
                label: "Budget",
                value: budget is num
                    ? "${budget.toStringAsFixed(budget is int ? 0 : 2)} ${currency.trim()}".trim()
                    : "—",
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContractInfoCard extends StatelessWidget {
  final FirebaseFirestore db;
  final String contractId;
  final ValueChanged<String> onOpenUrl;

  const _ContractInfoCard({
    required this.db,
    required this.contractId,
    required this.onOpenUrl,
  });

  String _statusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'draft') return 'Draft';
    if (s == 'active') return 'Active';
    if (s == 'submitted') return 'Submitted';
    if (s == 'completed') return 'Completed';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'disputed') return 'Disputed';
    if (s.isEmpty) return 'Unknown';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    if (contractId.isEmpty) {
      return _GlassCard(
        child: Column(
          children: const [
            _SectionTitle(
              icon: Icons.description_outlined,
              title: "Contract Information",
            ),
            SizedBox(height: 14),
            _SimpleNote(
              text: "No related contract found",
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('contracts').doc(contractId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const _GlassCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
          );
        }

        if (!snap.data!.exists) {
          return _GlassCard(
            child: Column(
              children: const [
                _SectionTitle(
                  icon: Icons.description_outlined,
                  title: "Contract Information",
                ),
                SizedBox(height: 14),
                _SimpleNote(
                  text: "Contract document not found",
                ),
              ],
            ),
          );
        }

        final data = snap.data!.data() ?? {};
        final status = (data['status'] ?? '').toString().trim();
        final agreedPrice = data['agreedPrice'];
        final currency = (data['currency'] ?? '').toString().trim();
        final duration = data['agreedDurationDays'];
        final pdfUrl = (data['pdfUrl'] ?? '').toString().trim();

        return _GlassCard(
          child: Column(
            children: [
              const _SectionTitle(
                icon: Icons.description_outlined,
                title: "Contract Information",
              ),
              const SizedBox(height: 14),
              _InfoRow(label: "Contract Status", value: _statusLabel(status)),
              _InfoRow(
                label: "Agreed Price",
                value: agreedPrice is num
                    ? "${agreedPrice.toStringAsFixed(agreedPrice is int ? 0 : 2)} ${currency.trim()}".trim()
                    : "—",
              ),
              _InfoRow(
                label: "Duration",
                value: duration is num ? "${duration.toInt()} days" : "—",
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: pdfUrl.trim().isEmpty ? null : () => onOpenUrl(pdfUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2A43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text(
                    "Open Contract",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserInfoTile extends StatelessWidget {
  final FirebaseFirestore db;
  final String uid;
  final String label;

  const _UserInfoTile({
    required this.db,
    required this.uid,
    required this.label,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  String _fallback() {
    if (uid.isEmpty) return "Unknown";
    if (uid.length <= 12) return uid;
    return "${uid.substring(0, 6)}…${uid.substring(uid.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return _InfoBlock(
        title: label,
        line1: "Unknown user",
        line2: "—",
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        String name = _fallback();
        String email = "—";
        String role = "—";

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() ?? {};
          final fullName = (data['fullName'] ?? '').toString().trim();
          final emailValue = (data['email'] ?? '').toString().trim();
          final roleValue = (data['role'] ?? '').toString().trim();
          name = fullName.isNotEmpty ? fullName : _fallback();
          email = emailValue.isNotEmpty ? emailValue : "—";
          role = roleValue.isNotEmpty ? roleValue : "—";
        }

        return _InfoBlock(
          title: label,
          line1: name,
          line2: "$email\nRole: $role",
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: tint,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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

class _InfoBlock extends StatelessWidget {
  final String title;
  final String line1;
  final String line2;

  const _InfoBlock({
    required this.title,
    required this.line1,
    required this.line2,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.025),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            line1,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            line2,
            style: const TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleNote extends StatelessWidget {
  final String text;

  const _SimpleNote({
    required this.text,
  });

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
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
            width: 110,
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