import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Manage%20Payments%20and%20Disputed/AdminDisputeDetails_Screen.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:flutter/material.dart';


class AdminDisputesListView extends StatefulWidget {
  const AdminDisputesListView({super.key});

  @override
  State<AdminDisputesListView> createState() => _AdminDisputesListViewState();
}

class _AdminDisputesListViewState extends State<AdminDisputesListView> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  String _statusFilter = 'all';

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = _db.collection('disputes');

    if (_statusFilter != 'all') {
      q = q.where('status', isEqualTo: _statusFilter);
    }

    return q.orderBy('createdAt', descending: true).limit(80);
  }

  Future<void> _openFilterDialog() async {
    final result = await showModalBottomSheet<_DisputesFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DisputesFilterSheet(status: _statusFilter),
    );

    if (result == null) return;

    setState(() {
      _statusFilter = result.status;
    });
  }

  String _statusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'open') return 'Open';
    if (s == 'under_review') return 'Under Review';
    if (s == 'resolved') return 'Resolved';
    if (s == 'rejected') return 'Rejected';
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _statusTint(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'open') return const Color(0xFFDC2626);
    if (s == 'under_review') return const Color(0xFFF59E0B);
    if (s == 'resolved') return const Color(0xFF059669);
    if (s == 'rejected') return const Color(0xFF64748B);
    return const Color(0xFF64748B);
  }

  String _filterSummary() {
    if (_statusFilter == 'all') return "All disputes\nAll status";
    return "Disputes\n${_statusLabel(_statusFilter)}";
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Container(
      color: _bgSlate,
      child: Column(
        children: [
          _TopInfoCard(
            summary: _filterSummary(),
            onChange: _openFilterDialog,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _GlassCard(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const _EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: "Failed to load disputes",
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
                    return const _EmptyState(
                      icon: Icons.gavel_rounded,
                      title: "No disputes found",
                      subtitle: "Try changing filters",
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
                      final disputeId = docs[i].id;
                      final d = docs[i].data();

                      final contractId = (d['contractId'] ?? '').toString().trim();
                      final createdBy = (d['createdBy'] ?? '').toString().trim();
                      final clientId = (d['clientId'] ?? '').toString().trim();
                      final freelancerId = (d['freelancerId'] ?? '').toString().trim();
                      final reason = (d['reason'] ?? '').toString().trim();
                      final details = (d['details'] ?? '').toString().trim();
                      final statusRaw = (d['status'] ?? '').toString().trim();

                      final createdAt = d['createdAt'];
                      DateTime? created;
                      if (createdAt is Timestamp) created = createdAt.toDate();

                      final createdText = created != null
                          ? "${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}"
                          : "—";

                      final title = reason.isNotEmpty ? reason : "Dispute";
                      final subtitle = details.isNotEmpty ? details : "No details provided";
                      final statusLabel = _statusLabel(statusRaw);
                      final tint = _statusTint(statusRaw);

                      return _DisputeTile(
                        db: _db,
                        disputeId: disputeId,
                        contractId: contractId,
                        createdBy: createdBy,
                        clientId: clientId,
                        freelancerId: freelancerId,
                        title: title,
                        subtitle: subtitle,
                        statusLabel: statusLabel,
                        statusTint: tint,
                        createdText: createdText,
                        onTap: () {
                          GoToScreen(
                            context: context,
                            screen: AdminDisputeDetailsScreen(disputeId: disputeId),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopInfoCard extends StatelessWidget {
  final String summary;
  final VoidCallback onChange;

  const _TopInfoCard({required this.summary, required this.onChange});

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
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
            child: const Icon(Icons.gavel_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: _textMuted),
                    SizedBox(width: 6),
                    Text(
                      "Disputes Overview",
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.filter_alt_rounded, size: 18, color: _textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        summary.split('\n').last,
                        style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(
              "Filter",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  final FirebaseFirestore db;
  final String disputeId;
  final String contractId;
  final String createdBy;
  final String clientId;
  final String freelancerId;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusTint;
  final String createdText;
  final VoidCallback onTap;

  const _DisputeTile({
    required this.db,
    required this.disputeId,
    required this.contractId,
    required this.createdBy,
    required this.clientId,
    required this.freelancerId,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusTint,
    required this.createdText,
    required this.onTap,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusTint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.report_problem_outlined, color: statusTint, size: 20),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 8),
                _MiniChip(
                  icon: Icons.flag_outlined,
                  label: statusLabel,
                  bg: statusTint.withOpacity(0.12),
                  fg: statusTint,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(
                      icon: Icons.calendar_today_outlined,
                      label: createdText,
                      bg: Colors.black.withOpacity(0.03),
                      fg: _textMuted,
                    ),
                    _MiniChip(
                      icon: Icons.description_outlined,
                      label: contractId.isEmpty ? "No contract" : "Contract: $contractId",
                      bg: Colors.black.withOpacity(0.03),
                      fg: _textMuted,
                    ),
                    _UserNameChip(db: db, userId: createdBy, label: "Created By"),
                    _UserNameChip(db: db, userId: clientId, label: "Client"),
                    _UserNameChip(db: db, userId: freelancerId, label: "Freelancer"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: _textMuted),
        ],
      ),
    );
  }
}

class _UserNameChip extends StatelessWidget {
  final FirebaseFirestore db;
  final String userId;
  final String label;

  const _UserNameChip({
    required this.db,
    required this.userId,
    required this.label,
  });

  static const _textMuted = Color(0xFF64748B);

  String _fallbackFromId() {
    if (userId.isEmpty) return "Unknown";
    if (userId.length <= 10) return userId;
    return "${userId.substring(0, 6)}…${userId.substring(userId.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _fallbackFromId();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userId.isEmpty ? null : db.collection('users').doc(userId).snapshots(),
      builder: (context, snap) {
        String name = fallback;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() ?? {};
          final fullName = (data['fullName'] ?? '').toString().trim();
          final email = (data['email'] ?? '').toString().trim();
          name = fullName.isNotEmpty ? fullName : (email.isNotEmpty ? email : fallback);
        }

        final screenW = MediaQuery.of(context).size.width;
        final chipMax = (screenW * 0.52).clamp(150.0, 240.0);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: chipMax),
          child: _MiniChipText(
            icon: Icons.person_outline_rounded,
            label: "$label: $name",
            bg: Colors.black.withOpacity(0.03),
            fg: _textMuted,
          ),
        );
      },
    );
  }
}

class _MiniChipText extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _MiniChipText({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              letterSpacing: 0.15,
            ),
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

class _DisputesFilterSheet extends StatefulWidget {
  final String status;

  const _DisputesFilterSheet({
    required this.status,
  });

  @override
  State<_DisputesFilterSheet> createState() => _DisputesFilterSheetState();
}

class _DisputesFilterSheetState extends State<_DisputesFilterSheet> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 26,
                    offset: const Offset(0, -10),
                  )
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_brandNavy, _slateBlue],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Filter Disputes",
                          style: TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _SheetGroupTitle(icon: Icons.flag_outlined, title: "Status"),
                  const SizedBox(height: 10),
                  _SheetChoiceRow(
                    value: _status,
                    items: const [
                      _ChoiceItem(value: 'all', label: 'All'),
                      _ChoiceItem(value: 'open', label: 'Open'),
                      _ChoiceItem(value: 'under_review', label: 'Under Review'),
                      _ChoiceItem(value: 'resolved', label: 'Resolved'),
                      _ChoiceItem(value: 'rejected', label: 'Rejected'),
                    ],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _brandNavy,
                            side: BorderSide(color: _brandNavy.withOpacity(0.25)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => setState(() => _status = 'all'),
                          child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pop(context, _DisputesFilterResult(status: _status));
                          },
                          child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.w900)),
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

class _SheetGroupTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SheetGroupTitle({required this.icon, required this.title});

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
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _ChoiceItem {
  final String value;
  final String label;
  const _ChoiceItem({required this.value, required this.label});
}

class _SheetChoiceRow extends StatelessWidget {
  final String value;
  final List<_ChoiceItem> items;
  final ValueChanged<String> onChanged;

  const _SheetChoiceRow({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((it) {
        final selected = value == it.value;
        return GestureDetector(
          onTap: () => onChanged(it.value),
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
              it.label,
              style: TextStyle(
                color: selected ? Colors.white : _textMuted,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DisputesFilterResult {
  final String status;
  const _DisputesFilterResult({required this.status});
}