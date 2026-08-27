import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class FreelancerNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const FreelancerNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: GNav(
                  gap: 8,
                  rippleColor: _brandNavy.withOpacity(0.08),
                  hoverColor: _brandNavy.withOpacity(0.06),
                  haptic: true,
                  tabBorderRadius: 18,
                  curve: Curves.easeOutCubic,
                  duration: const Duration(milliseconds: 320),
                  iconSize: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  backgroundColor: Colors.transparent,
                  color: _textMuted,
                  activeColor: Colors.white,
                  tabBackgroundGradient: const LinearGradient(
                    colors: [_brandNavy, _slateBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  tabs: const [


                    GButton(
                      icon: Icons.assignment_turned_in_outlined,
                      text: 'Work',
                    ),
                    GButton(
                      icon: Icons.work_outline_rounded,
                      text: 'Jobs',
                    ),
                    GButton(
                      icon: Icons.dashboard_outlined,
                      text: 'Dashboard',
                    ),
                    GButton(
                      icon: Icons.payments_outlined,
                      text: 'Payments',
                    ),
                    GButton(
                      icon: Icons.star_outline_rounded,
                      text: 'Reviews',
                    ),
                  ],
                  selectedIndex: currentIndex,
                  onTabChange: onTabChange,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}