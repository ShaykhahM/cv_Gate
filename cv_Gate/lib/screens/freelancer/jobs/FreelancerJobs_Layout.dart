import 'dart:ui';

import 'package:cv_gate/core/styles/colors.dart';
import 'package:cv_gate/screens/freelancer/jobs/AvailableJobsScreen.dart';
import 'package:cv_gate/screens/freelancer/jobs/MyApplicationsScreen.dart';
import 'package:flutter/material.dart';



class FreelancerJobsLayout extends StatefulWidget {
  final String freelancerId;

  const FreelancerJobsLayout({
    super.key,
    required this.freelancerId,
  });

  @override
  State<FreelancerJobsLayout> createState() => _FreelancerJobsLayoutState();
}

class _FreelancerJobsLayoutState extends State<FreelancerJobsLayout> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
          title: const Text(
            "Jobs",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
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
                      title: "Available Jobs",
                      icon: Icons.work_outline_rounded,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SegTab(
                      selected: _tab == 1,
                      title: "My Applications",
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
                    ? _KeepAlive(
                  keyId: "available_jobs",
                  child: AvailableJobsScreen(
                    freelancerId: widget.freelancerId,
                  ),
                )
                    : _KeepAlive(
                  keyId: "my_applications",
                  child: MyApplicationsScreen(
                    freelancerId: widget.freelancerId,
                  ),
                ),
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
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.black.withOpacity(0.03),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
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

class _KeepAlive extends StatefulWidget {
  final Widget child;
  final String keyId;

  const _KeepAlive({
    super.key,
    required this.child,
    required this.keyId,
  });

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
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

class FreelancerMyApplicationsPlaceholder extends StatelessWidget {
  final String freelancerId;

  const FreelancerMyApplicationsPlaceholder({
    super.key,
    required this.freelancerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey("applications_placeholder"),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 38,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                "My Applications screen will be implemented next.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}