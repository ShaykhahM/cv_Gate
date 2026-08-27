import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Manage%20Users/AdminUserDetails_Screen.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:flutter/material.dart';

class ManageusersScreen extends StatefulWidget {
  const ManageusersScreen({super.key});

  @override
  State<ManageusersScreen> createState() => _ManageusersScreenState();
}

class _ManageusersScreenState extends State<ManageusersScreen> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _db = FirebaseFirestore.instance;

  String _roleFilter = 'all';
  String _activeFilter = 'all';

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = _db.collection('users').where('role',isNotEqualTo: 'admin');

    if (_roleFilter != 'all') {
      q = q.where('role', isEqualTo: _roleFilter);
    }

    if (_activeFilter != 'all') {
      q = q.where('isActive', isEqualTo: _activeFilter == 'active');
    }

    return q.orderBy('createdAt', descending: true).limit(80);
  }

  String _roleLabel(String raw) {
    final r = raw.trim().toLowerCase();
    if (r == 'client' || r == 'job_seeker') return 'Client';
    if (r == 'freelancer' || r == 'technician') return 'Freelancer';
    if (r == 'admin' || r == 'administrator') return 'Admin';
    if (r.isEmpty) return 'Unknown';
    return r[0].toUpperCase() + r.substring(1);
  }

  Color _roleTint(String roleLabel) {
    final s = roleLabel.toLowerCase();
    if (s == 'client') return const Color(0xFF2563EB);
    if (s == 'freelancer') return const Color(0xFF0C4A6E);
    if (s == 'admin') return const Color(0xFF0C4A6E);
    return const Color(0xFF64748B);
  }

  Future<void> _openFilterDialog() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _FilterSheet(
          role: _roleFilter,
          status: _activeFilter,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _roleFilter = result.role;
      _activeFilter = result.status;
    });
  }

  String _filterSummary() {
    String role;
    if (_roleFilter == 'all') role = "All roles";
    else if (_roleFilter == 'client') role = "Client";
    else role = "Freelancer";

    String st;
    if (_activeFilter == 'all') st = "All status";
    else if (_activeFilter == 'active') st = "Active";
    else st = "Suspended";

    return "$role\n$st";
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

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
            "Users",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _openFilterDialog,
              icon: const Icon(Icons.tune_rounded),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                        title: "Failed to load users",
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
                        icon: Icons.people_outline_rounded,
                        title: "No users found",
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
                        final d = docs[i].data();
                        final uid = docs[i].id;

                        final fullName = (d['fullName'] ?? '').toString().trim();
                        final email = (d['email'] ?? '').toString().trim();
                        final roleRaw = (d['role'] ?? '').toString();
                        final isActive = (d['isActive'] is bool) ? d['isActive'] as bool : true;

                        final ratingAvg = d['ratingAvg'];
                        final ratingCount = d['ratingCount'];

                        final role = _roleLabel(roleRaw);
                        final display = fullName.isNotEmpty ? fullName : (email.isNotEmpty ? email : uid);

                        final avg = (ratingAvg is num) ? ratingAvg.toDouble() : 0.0;
                        final cnt = (ratingCount is num) ? ratingCount.toInt() : 0;

                        return _UserTile(
                          uid: uid,
                          name: display,
                          email: email,
                          role: role,
                          isActive: isActive,
                          ratingAvg: avg,
                          ratingCount: cnt,
                          tint: _roleTint(role),
                          onTap: () {
                            GoToScreen(context: context, screen: AdminUserDetailsScreen(uid: uid,));

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
            child: const Icon(Icons.filter_alt_rounded, color: Colors.white),
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
                      "Current Filters",
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
                    const Icon(Icons.badge_outlined, size: 18, color: _textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        summary.split('\n').first,
                        style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18, color: _textMuted),
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
              "Change",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final double ratingAvg;
  final int ratingCount;
  final Color tint;
  final VoidCallback onTap;

  const _UserTile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.ratingAvg,
    required this.ratingCount,
    required this.tint,
    required this.onTap,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.trim().characters.first.toUpperCase() : "U";

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: tint,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.alternate_email_rounded, size: 16, color: _textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniChip(
                      icon: Icons.badge_outlined,
                      label: role,
                      bg: tint.withOpacity(0.12),
                      fg: tint,
                    ),
                    const SizedBox(width: 8),
                    _MiniChip(
                      icon: isActive ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                      label: isActive ? "Active" : "Suspended",
                      bg: isActive
                          ? const Color(0xFF059669).withOpacity(0.14)
                          : const Color(0xFFDC2626).withOpacity(0.14),
                      fg: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                    const Spacer(),
                    if (ratingCount > 0) ...[
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "($ratingCount)",
                        style: TextStyle(
                          color: _textMuted.withOpacity(0.9),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _FilterSheet extends StatefulWidget {
  final String role;
  final String status;

  const _FilterSheet({
    required this.role,
    required this.status,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  late String _role;
  late String _status;

  @override
  void initState() {
    super.initState();
    _role = widget.role;
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
                          "Filter Users",
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
                  _SheetGroupTitle(icon: Icons.badge_outlined, title: "Role"),
                  const SizedBox(height: 10),
                  _SheetChoiceRow(
                    value: _role,
                    items: const [
                      _ChoiceItem(value: 'all', label: 'All'),
                      _ChoiceItem(value: 'client', label: 'Client'),
                      _ChoiceItem(value: 'freelancer', label: 'Freelancer'),
                    ],
                    onChanged: (v) => setState(() => _role = v),
                  ),
                  const SizedBox(height: 16),
                  _SheetGroupTitle(icon: Icons.verified_user_outlined, title: "Status"),
                  const SizedBox(height: 10),
                  _SheetChoiceRow(
                    value: _status,
                    items: const [
                      _ChoiceItem(value: 'all', label: 'All'),
                      _ChoiceItem(value: 'active', label: 'Active'),
                      _ChoiceItem(value: 'suspended', label: 'Suspended'),
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
                              _role = 'all';
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
                            Navigator.pop(context, _FilterResult(role: _role, status: _status));
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

class _FilterResult {
  final String role;
  final String status;
  const _FilterResult({required this.role, required this.status});
}