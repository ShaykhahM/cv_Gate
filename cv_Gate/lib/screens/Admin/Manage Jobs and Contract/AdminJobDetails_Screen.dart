import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Manage%20Jobs%20and%20Contract/AdminContractDetails_Screen.dart';
import 'package:flutter/material.dart';

class AdminJobDetailsScreen extends StatefulWidget {
  final String jobId;
  const AdminJobDetailsScreen({super.key, required this.jobId});

  @override
  State<AdminJobDetailsScreen> createState() => _AdminJobDetailsScreenState();
}

class _AdminJobDetailsScreenState extends State<AdminJobDetailsScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  final Map<String, String> _nameCache = {};
  final Map<String, Future<String>> _nameFutures = {};

  Stream<DocumentSnapshot<Map<String, dynamic>>> _jobStream() {
    return _db.collection('jobs').doc(widget.jobId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _appsStream() {
    return _db
        .collection('applications')
        .where('jobId', isEqualTo: widget.jobId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  Future<int> _contractsCount() async {
    final snap = await _db.collection('contracts').where('jobId', isEqualTo: widget.jobId).count().get();
    return snap.count??0;
  }

  Future<String> _getUserName(String uid) {
    if (uid.isEmpty) return Future.value("Unknown");
    if (_nameCache.containsKey(uid)) return Future.value(_nameCache[uid]!);
    if (_nameFutures.containsKey(uid)) return _nameFutures[uid]!;

    final f = _db.collection('users').doc(uid).get().then((snap) {
      String name = _shortId(uid);
      if (snap.exists) {
        final d = snap.data() ?? {};
        final fullName = (d['fullName'] ?? '').toString().trim();
        final email = (d['email'] ?? '').toString().trim();
        name = fullName.isNotEmpty ? fullName : (email.isNotEmpty ? email : name);
      }
      _nameCache[uid] = name;
      return name;
    });

    _nameFutures[uid] = f;
    return f;
  }

  String _shortId(String id) {
    if (id.isEmpty) return "Unknown";
    if (id.length <= 10) return id;
    return "${id.substring(0, 6)}…${id.substring(id.length - 4)}";
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

  String _appStatusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'pending') return 'Pending';
    if (s == 'accepted') return 'Accepted';
    if (s == 'rejected') return 'Rejected';
    if (s == 'withdrawn') return 'Withdrawn';
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _appStatusTint(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'pending') return const Color(0xFF2563EB);
    if (s == 'accepted') return const Color(0xFF059669);
    if (s == 'rejected') return const Color(0xFFDC2626);
    if (s == 'withdrawn') return const Color(0xFF64748B);
    return const Color(0xFF64748B);
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

  Future<void> _closeJob() async {
    final ok = await _confirmAction(
      title: "Close Job",
      message: "This will set the job status to Closed.",
      okText: "Close",
    );
    if (!ok) return;

    await _db.collection('jobs').doc(widget.jobId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _removeJob() async {
    final ok = await _confirmAction(
      title: "Remove Job",
      message: "This will set the job status to Cancelled.",
      okText: "Remove",
    );
    if (!ok) return;

    await _db.collection('jobs').doc(widget.jobId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _openContracts(String jobId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('contracts')
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final contractId = query.docs.first.id;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminContractDetailsScreen(
              contractId: contractId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contract found for this job')),
        );
      }
    } catch (e) {
      print(e);
    }
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
          centerTitle: false,
          title: const Text(
            "Job Details",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (v) {
                if (v == 'close') _closeJob();
                if (v == 'remove') _removeJob();
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18),
                      SizedBox(width: 10),
                      Text("Close Job", style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18),
                      SizedBox(width: 10),
                      Text("Remove Job", style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
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
        stream: _jobStream(),
        builder: (context, jobSnap) {
          if (jobSnap.hasError) {
            return const _EmptyState(
              icon: Icons.error_outline_rounded,
              title: "Failed to load job",
              subtitle: "Please try again later",
            );
          }

          if (!jobSnap.hasData) {
            return const Center(
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            );
          }

          if (!jobSnap.data!.exists) {
            return const _EmptyState(
              icon: Icons.work_outline_rounded,
              title: "Job not found",
              subtitle: "This job may have been removed",
            );
          }

          final job = jobSnap.data!.data() ?? {};
          final title = (job['title'] ?? '').toString().trim();
          final description = (job['description'] ?? '').toString().trim();
          final category = (job['category'] ?? '').toString().trim();
          final statusRaw = (job['status'] ?? '').toString().trim();
          final clientId = (job['clientId'] ?? '').toString().trim();
          final jobId = (job['jobId'] ?? '').toString().trim();

          final budget = job['budget'];

          final currency = (job['currency'] ?? '').toString().trim();
          final durationDays = job['durationDays'];

          final createdAt = job['createdAt'];
          DateTime? created;
          if (createdAt is Timestamp) created = createdAt.toDate();

          final statusLabel = _statusLabel(statusRaw);
          final statusTint = _statusTint(statusRaw);

          final budgetText = (budget is num)
              ? "${budget.toStringAsFixed(budget is int ? 0 : 2)} ${currency.isNotEmpty ? currency : ''}".trim()
              : (currency.isNotEmpty ? currency : "—");

          final durationText = (durationDays is num) ? "${durationDays.toInt()} days" : "—";
          final createdText = created != null
              ? "${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}"
              : "—";

          final isContracted = statusRaw.toLowerCase() == 'contracted';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : "Untitled Job",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MiniChip(
                      icon: Icons.flag_outlined,
                      label: statusLabel,
                      bg: statusTint.withOpacity(0.12),
                      fg: statusTint,
                    ),
                    const SizedBox(height: 12),
                    if (category.isNotEmpty)
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: "Category",
                        value: category,
                      ),
                    _ClientRow(
                      getName: () => _getUserName(clientId),
                      fallback: _shortId(clientId),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniChip(icon: Icons.payments_outlined, label: budgetText, bg: Colors.black.withOpacity(0.03), fg: _textMuted),
                        _MiniChip(icon: Icons.timelapse_outlined, label: durationText, bg: Colors.black.withOpacity(0.03), fg: _textMuted),
                        _MiniChip(icon: Icons.calendar_today_outlined, label: createdText, bg: Colors.black.withOpacity(0.03), fg: _textMuted),
                      ],
                    ),
                    if (isContracted) ...[
                      const SizedBox(height: 14),
                      _ContractsEntryCard(
                        loadCount: _contractsCount,
                        onTap: ()
                        {
                          _openContracts(jobId.toString());
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    const _SectionTitle(icon: Icons.description_outlined, title: "Description"),
                    const SizedBox(height: 8),
                    Text(
                      description.isNotEmpty ? description : "No description provided.",
                      style: const TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(icon: Icons.folder_copy_outlined, title: "Applications"),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _appsStream(),
                      builder: (context, appsSnap) {
                        if (appsSnap.hasError) {
                          return const _EmptyStateInline(
                            icon: Icons.error_outline_rounded,
                            title: "Failed to load applications",
                            subtitle: "Try again later",
                          );
                        }

                        if (!appsSnap.hasData) {
                          return const Center(
                            child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
                          );
                        }

                        final apps = appsSnap.data!.docs;
                        if (apps.isEmpty) {
                          return const _EmptyStateInline(
                            icon: Icons.inbox_outlined,
                            title: "No applications yet",
                            subtitle: "This job has no proposals",
                          );
                        }

                        return Column(
                          children: List.generate(apps.length, (i) {
                            final a = apps[i].data();
                            final freelancerId = (a['freelancerId'] ?? '').toString().trim();
                            final msg = (a['message'] ?? '').toString().trim();
                            final stRaw = (a['status'] ?? '').toString().trim();

                            final proposedPrice = a['proposedPrice'];
                            final proposedDurationDays = a['proposedDurationDays'];

                            final createdAt = a['createdAt'];
                            DateTime? created;
                            if (createdAt is Timestamp) created = createdAt.toDate();

                            final stLabel = _appStatusLabel(stRaw);
                            final stTint = _appStatusTint(stRaw);

                            final priceText = (proposedPrice is num)
                                ? proposedPrice.toStringAsFixed(proposedPrice is int ? 0 : 2)
                                : "—";

                            final durText = (proposedDurationDays is num) ? "${proposedDurationDays.toInt()} days" : "—";

                            final createdText = created != null
                                ? "${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}"
                                : "—";

                            return Padding(
                              padding: EdgeInsets.only(bottom: i == apps.length - 1 ? 0 : 12),
                              child: _ApplicationCard(
                                freelancerFuture: _getUserName(freelancerId),
                                freelancerFallback: _shortId(freelancerId),
                                statusLabel: stLabel,
                                statusTint: stTint,
                                priceText: priceText,
                                durationText: durText,
                                createdText: createdText,
                                message: msg,
                              ),
                            );
                          }),
                        );
                      },
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

class _ContractsEntryCard extends StatelessWidget {
  final Future<int> Function() loadCount;
  final VoidCallback onTap;

  const _ContractsEntryCard({required this.loadCount, required this.onTap});

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_brandNavy, _slateBlue],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.article_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Contracts",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: loadCount(),
                    builder: (context, snap) {
                      final c = snap.hasData ? snap.data! : null;
                      final text = c == null ? "Loading..." : "$c contract(s) linked to this job";
                      return Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.3,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: _textMuted),
          ],
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final Future<String> Function() getName;
  final String fallback;

  const _ClientRow({required this.getName, required this.fallback});

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getName(),
      builder: (context, snap) {
        final name = snap.hasData ? snap.data! : fallback;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_outline_rounded, size: 18, color: _textMuted),
            const SizedBox(width: 8),
            const Text(
              "Client:",
              style: TextStyle(color: _textMuted, fontWeight: FontWeight.w900, fontSize: 12.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Future<String> freelancerFuture;
  final String freelancerFallback;
  final String statusLabel;
  final Color statusTint;
  final String priceText;
  final String durationText;
  final String createdText;
  final String message;

  const _ApplicationCard({
    required this.freelancerFuture,
    required this.freelancerFallback,
    required this.statusLabel,
    required this.statusTint,
    required this.priceText,
    required this.durationText,
    required this.createdText,
    required this.message,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<String>(
                  future: freelancerFuture,
                  builder: (context, snap) {
                    final name = snap.hasData ? snap.data! : freelancerFallback;
                    return Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.2,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              _MiniChip(
                icon: Icons.verified_outlined,
                label: statusLabel,
                bg: statusTint.withOpacity(0.12),
                fg: statusTint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(icon: Icons.payments_outlined, label: "Price: $priceText", bg: Colors.black.withOpacity(0.03), fg: _textMuted),
              _MiniChip(icon: Icons.timelapse_outlined, label: "Duration: $durationText", bg: Colors.black.withOpacity(0.03), fg: _textMuted),
              _MiniChip(icon: Icons.calendar_today_outlined, label: createdText, bg: Colors.black.withOpacity(0.03), fg: _textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.isNotEmpty ? message : "No message.",
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.6,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w900, fontSize: 12.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

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
            fontSize: 13.8,
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _MiniChip({required this.icon, required this.label, required this.bg, required this.fg});

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

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: _textMuted.withOpacity(0.85)),
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
      ),
    );
  }
}

class _EmptyStateInline extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateInline({required this.icon, required this.title, required this.subtitle});

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 32, color: _textMuted.withOpacity(0.85)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 14.2),
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

class AdminContractsListScreen extends StatelessWidget {
  final String jobId;
  const AdminContractsListScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Contracts", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: Text(
          "Job ID: $jobId",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}