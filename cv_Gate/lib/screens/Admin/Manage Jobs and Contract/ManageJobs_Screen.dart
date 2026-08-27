import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Manage%20Jobs%20and%20Contract/AdminJobDetails_Screen.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:flutter/material.dart';

class ManageJobsScreen extends StatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  State<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  String _statusFilter = 'all';

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = _db.collection('jobs');

    if (_statusFilter != 'all') {
      q = q.where('status', isEqualTo: _statusFilter);
    }

    return q.orderBy('createdAt', descending: true).limit(80);
  }

  Future<void> _openFilterDialog() async {
    final result = await showModalBottomSheet<_JobsFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JobsFilterSheet(status: _statusFilter),
    );

    if (result == null) return;

    setState(() {
      _statusFilter = result.status;
    });
  }

  String _statusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'open') return 'Open';
    if (s == 'closed') return 'Closed';
    if (s == 'contracted') return 'Contracted';
    if (s == 'cancelled') return 'Cancelled';
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _statusTint(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'open') return const Color(0xFF2563EB);
    if (s == 'contracted') return const Color(0xFF059669);
    if (s == 'closed') return const Color(0xFF64748B);
    if (s == 'cancelled') return const Color(0xFFDC2626);
    return const Color(0xFF64748B);
  }

  String _filterSummary() {
    if (_statusFilter == 'all') return "All jobs\nAll status";
    return "Jobs\n${_statusLabel(_statusFilter)}";
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String okText,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(okText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  Future<void> _closeJob(String jobId) async {
    final ok = await _confirmAction(
      title: "Close Job",
      message: "This will set the job status to Closed.",
      okText: "Close",
    );
    if (!ok) return;

    await _db.collection('jobs').doc(jobId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _removeJob(String jobId) async {
    final ok = await _confirmAction(
      title: "Remove Job",
      message: "This will set the job status to Cancelled.",
      okText: "Remove",
    );
    if (!ok) return;

    await _db.collection('jobs').doc(jobId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Container(
      color: _bgSlate,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
                        title: "Failed to load jobs",
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
                        icon: Icons.work_outline_rounded,
                        title: "No jobs found",
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
                        final jobId = docs[i].id;
                        final d = docs[i].data();

                        final title = (d['title'] ?? '').toString().trim();
                        final desc = (d['description'] ?? '').toString().trim();
                        final category = (d['category'] ?? '').toString().trim();
                        final statusRaw = (d['status'] ?? '').toString().trim();
                        final clientId = (d['clientId'] ?? '').toString().trim();

                        final budget = d['budget'];
                        final currency = (d['currency'] ?? '').toString().trim();
                        final durationDays = d['durationDays'];

                        final createdAt = d['createdAt'];
                        DateTime? created;
                        if (createdAt is Timestamp) created = createdAt.toDate();

                        final statusLabel = _statusLabel(statusRaw);
                        final tint = _statusTint(statusRaw);

                        final budgetText = (budget is num)
                            ? "${budget.toStringAsFixed(budget is int ? 0 : 2)} ${currency.isNotEmpty ? currency : ''}".trim()
                            : (currency.isNotEmpty ? currency : "—");

                        final durationText = (durationDays is num) ? "${durationDays.toInt()} days" : "—";

                        final createdText = created != null
                            ? "${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}"
                            : "—";

                        final subtitle = category.isNotEmpty ? category : (desc.isNotEmpty ? desc : "No description");

                        return _JobTile(
                          db: _db,
                          jobId: jobId,
                          title: title.isNotEmpty ? title : "Untitled Job",
                          subtitle: subtitle,
                          status: statusLabel,
                          statusRaw: statusRaw,
                          statusTint: tint,
                          budgetText: budgetText,
                          durationText: durationText,
                          createdText: createdText,
                          clientId: clientId,
                          onTap: () {
                            GoToScreen(
                              context: context,
                              screen: AdminJobDetailsScreen(jobId: jobId),
                            );
                          },
                          onClose: () => _closeJob(jobId),
                          onRemove: () => _removeJob(jobId),
                          allowClose: statusRaw.toLowerCase() == 'open' || statusRaw.toLowerCase() == 'contracted',
                          allowRemove: statusRaw.toLowerCase() != 'cancelled',
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
            child: const Icon(Icons.work_outline_rounded, color: Colors.white),
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
                      "Jobs Overview",
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

class _JobTile extends StatelessWidget {
  final FirebaseFirestore db;
  final String jobId;
  final String title;
  final String subtitle;
  final String status;
  final String statusRaw;
  final Color statusTint;
  final String budgetText;
  final String durationText;
  final String createdText;
  final String clientId;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onRemove;
  final bool allowClose;
  final bool allowRemove;

  const _JobTile({
    required this.db,
    required this.jobId,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusRaw,
    required this.statusTint,
    required this.budgetText,
    required this.durationText,
    required this.createdText,
    required this.clientId,
    required this.onTap,
    required this.onClose,
    required this.onRemove,
    required this.allowClose,
    required this.allowRemove,
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
            child: Icon(Icons.work_rounded, color: statusTint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: _textMuted),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (v) {
                        if (v == 'close') onClose();
                        if (v == 'remove') onRemove();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          value: 'close',
                          enabled: allowClose,
                          child: const Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 18),
                              SizedBox(width: 10),
                              Text("Close Job", style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'remove',
                          enabled: allowRemove,
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18),
                              SizedBox(width: 10),
                              Text("Remove Job", style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MiniChip(
                  icon: Icons.flag_outlined,
                  label: status,
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
                    _ClientNameChip(db: db, clientId: clientId),
                    _ApplicationsCountChip(db: db, jobId: jobId),
                    _MiniChip(icon: Icons.payments_outlined, label: budgetText.isEmpty ? "—" : budgetText, bg: Colors.black.withOpacity(0.03), fg: _textMuted),
                    _MiniChip(icon: Icons.timelapse_outlined, label: durationText, bg: Colors.black.withOpacity(0.03), fg: _textMuted),
                    _MiniChip(icon: Icons.calendar_today_outlined, label: createdText, bg: Colors.black.withOpacity(0.03), fg: _textMuted),
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

class _ClientNameChip extends StatelessWidget {
  final FirebaseFirestore db;
  final String clientId;

  const _ClientNameChip({
    required this.db,
    required this.clientId,
  });

  static const _textMuted = Color(0xFF64748B);

  String _fallbackFromId() {
    if (clientId.isEmpty) return "Unknown";
    if (clientId.length <= 10) return clientId;
    return "${clientId.substring(0, 6)}…${clientId.substring(clientId.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _fallbackFromId();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: clientId.isEmpty ? null : db.collection('users').doc(clientId).snapshots(),
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
            label: "Client: $name",
            bg: Colors.black.withOpacity(0.03),
            fg: _textMuted,
          ),
        );
      },
    );
  }
}

class _ApplicationsCountChip extends StatelessWidget {
  final FirebaseFirestore db;
  final String jobId;

  const _ApplicationsCountChip({
    required this.db,
    required this.jobId,
  });

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final q = db.collection('applications').where('jobId', isEqualTo: jobId);

    return FutureBuilder<AggregateQuerySnapshot>(
      future: q.count().get(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.count : 0;
        return _MiniChip(
          icon: Icons.description_outlined,
          label: "Apps: $count",
          bg: Colors.black.withOpacity(0.03),
          fg: _textMuted,
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

class _JobsFilterSheet extends StatefulWidget {
  final String status;

  const _JobsFilterSheet({
    required this.status,
  });

  @override
  State<_JobsFilterSheet> createState() => _JobsFilterSheetState();
}

class _JobsFilterSheetState extends State<_JobsFilterSheet> {
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
                          "Filter Jobs",
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
                      _ChoiceItem(value: 'contracted', label: 'Contracted'),
                      _ChoiceItem(value: 'closed', label: 'Closed'),
                      _ChoiceItem(value: 'cancelled', label: 'Cancelled'),
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
                            Navigator.pop(context, _JobsFilterResult(status: _status));
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

class _JobsFilterResult {
  final String status;
  const _JobsFilterResult({required this.status});
}