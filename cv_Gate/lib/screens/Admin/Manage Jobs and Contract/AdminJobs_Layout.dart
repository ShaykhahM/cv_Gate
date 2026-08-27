import 'dart:ui';
import 'package:cv_gate/screens/Admin/Manage%20Jobs%20and%20Contract/AdminContractsListView.dart';
import 'package:cv_gate/screens/Admin/Manage%20Jobs%20and%20Contract/ManageJobs_Screen.dart';
import 'package:flutter/material.dart';

class AdminJobsLayout extends StatefulWidget {
  const AdminJobsLayout({super.key});

  @override
  State<AdminJobsLayout> createState() => _AdminJobsLayoutState();
}

class _AdminJobsLayoutState extends State<AdminJobsLayout> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  int _tab = 0;

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
            "Jobs & Contracts",
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: _SegTab(
                      selected: _tab == 0,
                      title: "Jobs",
                      icon: Icons.work_outline_rounded,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SegTab(
                      selected: _tab == 1,
                      title: "Contracts",
                      icon: Icons.description_outlined,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _tab == 0
                    ? const _KeepAlive(child: ManageJobsScreen(), keyId: "jobs")
                    : const _KeepAlive(child: AdminContractsListView(), keyId: "contracts"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SegTab({
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : _textMuted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
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
          padding: const EdgeInsets.all(12),
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

class _KeepAlive extends StatefulWidget {
  final Widget child;
  final String keyId;
  const _KeepAlive({super.key, required this.child, required this.keyId});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyedSubtree(
      key: ValueKey(widget.keyId),
      child: widget.child,
    );
  }
}