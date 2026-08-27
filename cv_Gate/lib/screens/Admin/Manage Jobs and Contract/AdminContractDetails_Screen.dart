import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminContractDetailsScreen extends StatefulWidget {
  final String contractId;
  const AdminContractDetailsScreen({super.key, required this.contractId});

  @override
  State<AdminContractDetailsScreen> createState() => _AdminContractDetailsScreenState();
}

class _AdminContractDetailsScreenState extends State<AdminContractDetailsScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  final Map<String, String> _nameCache = {};
  final Map<String, Future<String>> _nameFutures = {};

  Stream<DocumentSnapshot<Map<String, dynamic>>> _contractStream() {
    return _db.collection('contracts').doc(widget.contractId).snapshots();
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
    if (s == 'draft') return 'Draft';
    if (s == 'active') return 'Active';
    if (s == 'submitted') return 'Submitted';
    if (s == 'completed') return 'Completed';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'disputed') return 'Disputed';
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _statusTint(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'active') return const Color(0xFF059669);
    if (s == 'completed') return const Color(0xFF2563EB);
    if (s == 'submitted') return const Color(0xFFF59E0B);
    if (s == 'disputed') return const Color(0xFFDC2626);
    if (s == 'cancelled') return const Color(0xFF64748B);
    if (s == 'draft') return const Color(0xFF0C4A6E);
    return const Color(0xFF64748B);
  }

  String _fmtDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      final h = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return "$y-$m-$day  $h:$min";
    }
    return "—";
  }

  String _moneyText(dynamic price, String currency) {
    if (price is num) {
      final v = price.toDouble();
      final str = (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
      return "${currency.isNotEmpty ? currency : ''} $str".trim();
    }
    return "—";
  }

  Future<void> _openPdf(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) {
      _toast("Invalid PDF link");
      return;
    }
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok) _toast("Could not open PDF");
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _brandNavy,
      ),
    );
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
            "Contract Details",
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
        stream: _contractStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const _EmptyState(
              icon: Icons.error_outline_rounded,
              title: "Failed to load contract",
              subtitle: "Please try again later",
            );
          }

          if (!snap.hasData) {
            return const Center(
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            );
          }

          if (!snap.data!.exists) {
            return const _EmptyState(
              icon: Icons.article_outlined,
              title: "Contract not found",
              subtitle: "This contract may have been removed",
            );
          }

          final c = snap.data!.data() ?? {};

          final contractId = (c['contractId'] ?? snap.data!.id).toString().trim();
          final jobId = (c['jobId'] ?? '').toString().trim();

          final clientId = (c['clientId'] ?? '').toString().trim();
          final freelancerId = (c['freelancerId'] ?? '').toString().trim();

          final currency = (c['currency'] ?? '').toString().trim();
          final agreedPrice = c['agreedPrice'];
          final agreedDurationDays = c['agreedDurationDays'];

          final statusRaw = (c['status'] ?? '').toString().trim();
          final pdfUrl = (c['pdfUrl'] ?? '').toString().trim();

          final createdAt = c['createdAt'];
          final updatedAt = c['updatedAt'];
          final acceptedAt = c['acceptedAt'];

          final statusLabel = _statusLabel(statusRaw);
          final statusTint = _statusTint(statusRaw);

          final priceText = _moneyText(agreedPrice, currency);
          final durationText = (agreedDurationDays is num) ? "${agreedDurationDays.toInt()} days" : "—";

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contractId.isNotEmpty ? contractId : "Contract",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MiniChip(
                      icon: Icons.verified_outlined,
                      label: statusLabel,
                      bg: statusTint.withOpacity(0.12),
                      fg: statusTint,
                    ),
                    const SizedBox(height: 14),
                    _KeyValueRow(
                      icon: Icons.work_outline_rounded,
                      label: "Job ID",
                      value: jobId.isNotEmpty ? jobId : "—",
                    ),
                    _UserRow(
                      icon: Icons.person_outline_rounded,
                      label: "Client",
                      uid: clientId,
                      loadName: () => _getUserName(clientId),
                      fallback: _shortId(clientId),
                    ),
                    _UserRow(
                      icon: Icons.engineering_outlined,
                      label: "Freelancer",
                      uid: freelancerId,
                      loadName: () => _getUserName(freelancerId),
                      fallback: _shortId(freelancerId),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniChip(
                          icon: Icons.payments_outlined,
                          label: "Price: $priceText",
                          bg: Colors.black.withOpacity(0.03),
                          fg: _textMuted,
                        ),
                        _MiniChip(
                          icon: Icons.timelapse_outlined,
                          label: "Duration: $durationText",
                          bg: Colors.black.withOpacity(0.03),
                          fg: _textMuted,
                        ),
                        _MiniChip(
                          icon: Icons.attach_money_outlined,
                          label: currency.isNotEmpty ? currency : "Currency",
                          bg: Colors.black.withOpacity(0.03),
                          fg: _textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SectionTitle(icon: Icons.schedule_rounded, title: "Timeline"),
                    const SizedBox(height: 10),
                    _KeyValueRow(
                      icon: Icons.calendar_today_outlined,
                      label: "Created At",
                      value: _fmtDate(createdAt),
                    ),
                    _KeyValueRow(
                      icon: Icons.update_rounded,
                      label: "Updated At",
                      value: _fmtDate(updatedAt),
                    ),
                    _KeyValueRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: "Accepted At",
                      value: _fmtDate(acceptedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(icon: Icons.picture_as_pdf_outlined, title: "Contract PDF"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pdfUrl.isNotEmpty ? pdfUrl : "No PDF link",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: pdfUrl.isNotEmpty ? () => _openPdf(pdfUrl) : null,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text("Open", style: TextStyle(fontWeight: FontWeight.w900)),
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

class _UserRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String uid;
  final Future<String> Function() loadName;
  final String fallback;

  const _UserRow({
    required this.icon,
    required this.label,
    required this.uid,
    required this.loadName,
    required this.fallback,
  });

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: loadName(),
      builder: (context, snap) {
        final name = snap.hasData ? snap.data! : (uid.isNotEmpty ? fallback : "—");
        return Row(
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

class _KeyValueRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _KeyValueRow({required this.icon, required this.label, required this.value});

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
          Flexible(
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