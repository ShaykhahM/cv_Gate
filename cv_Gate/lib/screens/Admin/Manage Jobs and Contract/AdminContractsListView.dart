import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Manage%20Jobs%20and%20Contract/AdminContractDetails_Screen.dart';
import 'package:flutter/material.dart';

class AdminContractsListView extends StatefulWidget {
  const AdminContractsListView({super.key});

  @override
  State<AdminContractsListView> createState() => _AdminContractsListViewState();
}

class _AdminContractsListViewState extends State<AdminContractsListView> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  String _statusFilter = 'all';
  final TextEditingController _search = TextEditingController();

  final Map<String, String> _nameCache = {};
  final Map<String, Future<String>> _nameFutures = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
      final cur = currency.isNotEmpty ? currency : '';
      return "$cur $str".trim();
    }
    return "—";
  }

  Future<void> _openFilterDialog() async {
    final result = await showModalBottomSheet<_ContractsFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ContractsFilterSheet(status: _statusFilter),
    );

    if (result == null) return;

    setState(() {
      _statusFilter = result.status;
    });
  }

  String _filterSummary() {
    if (_statusFilter == 'all') return "All status";
    return _statusLabel(_statusFilter);
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q = _db.collection('contracts');

    if (_statusFilter != 'all') {
      q = q.where('status', isEqualTo: _statusFilter);
    }

    return q.orderBy('createdAt', descending: true).limit(120);
  }

  bool _matchesSearch(Map<String, dynamic> c) {
    final s = _search.text.trim().toLowerCase();
    if (s.isEmpty) return true;

    final contractId = (c['contractId'] ?? '').toString().toLowerCase();
    final jobId = (c['jobId'] ?? '').toString().toLowerCase();

    return contractId.contains(s) || jobId.contains(s);
  }

  void _openDetails(String contractId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminContractDetailsScreen(contractId: contractId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _baseQuery();

    return Container(
      color: _bgSlate,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Column(
          children: [
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: "Search by Contract ID or Job ID",
                            hintStyle: TextStyle(
                              color: _textMuted.withOpacity(0.9),
                              fontWeight: FontWeight.w800,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded),
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
                              borderSide: BorderSide(color: _brandNavy.withOpacity(0.35)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _openFilterDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
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
                          child: const Icon(Icons.tune_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: _textMuted),
                      const SizedBox(width: 6),
                      const Text(
                        "Current Filter:",
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _filterSummary(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.8,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openFilterDialog,
                        child: const Text("Change", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
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
                        title: "Failed to load contracts",
                        subtitle: "Please try again later",
                      );
                    }

                    if (!snap.hasData) {
                      return const Center(
                        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                      );
                    }

                    final allDocs = snap.data!.docs;
                    final docs = allDocs.where((d) => _matchesSearch(d.data())).toList();

                    if (docs.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.article_outlined,
                        title: "No contracts found",
                        subtitle: "Try changing filters or search",
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
                        final data = docs[i].data();
                        final docId = docs[i].id;

                        final contractId = (data['contractId'] ?? docId).toString().trim();
                        final jobId = (data['jobId'] ?? '').toString().trim();

                        final clientId = (data['clientId'] ?? '').toString().trim();
                        final freelancerId = (data['freelancerId'] ?? '').toString().trim();

                        final statusRaw = (data['status'] ?? '').toString().trim();
                        final currency = (data['currency'] ?? '').toString().trim();
                        final agreedPrice = data['agreedPrice'];
                        final agreedDurationDays = data['agreedDurationDays'];
                        final acceptedAt = data['acceptedAt'];

                        final statusLabel = _statusLabel(statusRaw);
                        final statusTint = _statusTint(statusRaw);

                        final priceText = _moneyText(agreedPrice, currency);
                        final durationText = (agreedDurationDays is num) ? "${agreedDurationDays.toInt()} days" : "—";
                        final acceptedText = _fmtDate(acceptedAt);

                        return _ContractTile(
                          contractId: contractId,
                          jobId: jobId,
                          statusLabel: statusLabel,
                          statusTint: statusTint,
                          priceText: priceText,
                          durationText: durationText,
                          acceptedText: acceptedText,
                          clientNameFuture: _getUserName(clientId),
                          freelancerNameFuture: _getUserName(freelancerId),
                          clientFallback: _shortId(clientId),
                          freelancerFallback: _shortId(freelancerId),
                          onTap: () => _openDetails(contractId),
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

class _ContractTile extends StatelessWidget {
  final String contractId;
  final String jobId;

  final String statusLabel;
  final Color statusTint;

  final String priceText;
  final String durationText;
  final String acceptedText;

  final Future<String> clientNameFuture;
  final Future<String> freelancerNameFuture;
  final String clientFallback;
  final String freelancerFallback;

  final VoidCallback onTap;

  const _ContractTile({
    required this.contractId,
    required this.jobId,
    required this.statusLabel,
    required this.statusTint,
    required this.priceText,
    required this.durationText,
    required this.acceptedText,
    required this.clientNameFuture,
    required this.freelancerNameFuture,
    required this.clientFallback,
    required this.freelancerFallback,
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
            child: Icon(Icons.description_outlined, color: statusTint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contractId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(
                      icon: Icons.verified_outlined,
                      label: statusLabel,
                      bg: statusTint.withOpacity(0.12),
                      fg: statusTint,
                    ),
                    _MiniChip(
                      icon: Icons.work_outline_rounded,
                      label: jobId.isNotEmpty ? jobId : "Job —",
                      bg: Colors.black.withOpacity(0.03),
                      fg: _textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FutureBuilder<String>(
                  future: clientNameFuture,
                  builder: (context, s1) {
                    final clientName = s1.hasData ? s1.data! : clientFallback;
                    return _InfoLine(
                      icon: Icons.person_outline_rounded,
                      label: "Client",
                      value: clientName,
                    );
                  },
                ),
                const SizedBox(height: 6),
                FutureBuilder<String>(
                  future: freelancerNameFuture,
                  builder: (context, s2) {
                    final freName = s2.hasData ? s2.data! : freelancerFallback;
                    return _InfoLine(
                      icon: Icons.engineering_outlined,
                      label: "Freelancer",
                      value: freName,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(
                      icon: Icons.payments_outlined,
                      label: priceText.isNotEmpty ? priceText : "—",
                      bg: Colors.black.withOpacity(0.03),
                      fg: _textMuted,
                    ),
                    _MiniChip(
                      icon: Icons.timelapse_outlined,
                      label: durationText,
                      bg: Colors.black.withOpacity(0.03),
                      fg: _textMuted,
                    ),
                    _MiniChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: acceptedText,
                      bg: Colors.black.withOpacity(0.03),
                      fg: _textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: _textMuted),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({required this.icon, required this.label, required this.value});

  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _textMuted),
        const SizedBox(width: 6),
        Text(
          "$label:",
          style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w900, fontSize: 12.2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w800, fontSize: 12.2),
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

class _ContractsFilterSheet extends StatefulWidget {
  final String status;
  const _ContractsFilterSheet({required this.status});

  @override
  State<_ContractsFilterSheet> createState() => _ContractsFilterSheetState();
}

class _ContractsFilterSheetState extends State<_ContractsFilterSheet> {
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
                          "Filter Contracts",
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
                  _SheetGroupTitle(icon: Icons.verified_outlined, title: "Status"),
                  const SizedBox(height: 10),
                  _SheetChoiceRow(
                    value: _status,
                    items: const [
                      _ChoiceItem(value: 'all', label: 'All'),
                      _ChoiceItem(value: 'draft', label: 'Draft'),
                      _ChoiceItem(value: 'active', label: 'Active'),
                      _ChoiceItem(value: 'submitted', label: 'Submitted'),
                      _ChoiceItem(value: 'completed', label: 'Completed'),
                      _ChoiceItem(value: 'cancelled', label: 'Cancelled'),
                      _ChoiceItem(value: 'disputed', label: 'Disputed'),
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
                          onPressed: () {
                            setState(() {
                              _status = 'all';
                            });
                          },
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
                            Navigator.pop(context, _ContractsFilterResult(status: _status));
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

class _ContractsFilterResult {
  final String status;
  const _ContractsFilterResult({required this.status});
}

