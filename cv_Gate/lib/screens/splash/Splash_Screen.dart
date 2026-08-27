import 'dart:async';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:cv_gate/screens/Admin/Layout/Admin_Layout.dart';
import 'package:cv_gate/screens/client/layout/clientHome_Layout.dart';
import 'package:cv_gate/screens/freelancer/layout/FreelancerLayout.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:cv_gate/shared/services/local/Cahs_Helper.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  int userTypeIndex;
  SplashScreen(this.userTypeIndex);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _shine;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _logoScale = Tween<double>(begin: .86, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.10, 0.65, curve: Curves.easeOut)),
    );

    _shine = Tween<double>(begin: -1.1, end: 1.1).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.20, 1.0, curve: Curves.easeInOut)),
    );

    _floatY = Tween<double>(begin: 6.0, end: -6.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );

    _c.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      switch(widget.userTypeIndex)
      {
        case 0:
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, anim, __, child) {
                final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(curved),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 520),
            ),
          );
        case 1:
          adminId=CashHelper.getCash(key: 'token');
          NextWidget(context: context, screen: AdminLayout());
        case 2:
          freelancerId=CashHelper.getCash(key: 'token');
          NextWidget(context: context, screen: FreelancerLayout());
        case 3:
          clientId=CashHelper.getCash(key: 'token');
          NextWidget(context: context, screen: ClientLayout());
      }

    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;

    final double logoSize = shortest < 380 ? 110 : (shortest < 500 ? 140 : 170);

    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF071321),
                    Color(0xFF0B1F34),
                    Color(0xFF061723),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),


          Positioned(
            top: -140,
            left: -120,
            child: _GlowBlob(
              size: 320,
              color: AppColors.primary.withOpacity(.30),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -140,
            child: _GlowBlob(
              size: 360,
              color: AppColors.accent.withOpacity(.28),
            ),
          ),
          Positioned(
            top: size.height * .33,
            right: -120,
            child: _GlowBlob(
              size: 260,
              color: const Color(0xFF64B5F6).withOpacity(.18),
            ),
          ),


          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: .06,
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
            ),
          ),


          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  return Opacity(
                    opacity: _logoFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _floatY.value),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            _GlassCard(
                              radius: 30,
                              padding: const EdgeInsets.all(18),
                              child: SizedBox(
                                width: logoSize,
                                height: logoSize,
                                child: Stack(
                                  children: [

                                    Positioned.fill(
                                      child: Image.asset(
                                        'assets/images/appLogo.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),


                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Transform.translate(
                                          offset: Offset(_shine.value * logoSize, 0),
                                          child: Transform.rotate(
                                            angle: -0.35,
                                            child: Container(
                                              width: logoSize * .55,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0.00),
                                                    Colors.white.withOpacity(0.12),
                                                    Colors.white.withOpacity(0.00),
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),


                            ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                colors: [Color(0xFF64B5F6), Color(0xFF00C853)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(rect),
                              child: const Text(
                                "CVGate",
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .4,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Trusted jobs • Verified profiles",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(.70),
                                letterSpacing: .2,
                              ),
                            ),

                            const SizedBox(height: 28),


                            _LoadingPill(
                              width: shortest < 380 ? 170 : 210,
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom tiny label
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(
              child: Text(
                "Powered by CVGate",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ SMALL COMPONENTS ------------------

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withOpacity(.06),
        border: Border.all(
          color: Colors.white.withOpacity(.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingPill extends StatefulWidget {
  final double width;
  final double height;

  const _LoadingPill({required this.width, required this.height});

  @override
  State<_LoadingPill> createState() => _LoadingPillState();
}

class _LoadingPillState extends State<_LoadingPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.10)),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Align(
            alignment: Alignment(-1 + (_c.value * 2), 0),
            child: Container(
              width: widget.width * .42,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF00C853)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------ BACKGROUND PAINTER ------------------

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const step = 42.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------ DUMMY NEXT SCREEN (REMOVE IT) ------------------

class _DummyNext extends StatelessWidget {
  const _DummyNext();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          "Next Screen",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
