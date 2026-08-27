import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/components.dart';
import '../freelancer/complete_freelancer_profile_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;
  bool _hideConfirm = true;

  String _role = "client";

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        AppComponents.showAppSnack(
          context,
          title: "Sign up failed",
          message: "Missing user session.",
          type: SnackType.error,
        );
        setState(() => _loading = false);
        return;
      }

      final now = FieldValue.serverTimestamp();

      final userDoc = <String, dynamic>{
        "uid": uid,
        "role": _role,
        "fullName": _fullName.text.trim(),
        "email": _email.text.trim().toLowerCase(),
        "phone": _phone.text.trim(),
        "photoUrl": "",
        "city": _city.text.trim(),
        "createdAt": now,
        "isActive": true,
      };

      if (_role == "freelancer") {
        userDoc["ratingAvg"] = 0.0;
        userDoc["ratingCount"] = 0;
      }

      await FirebaseFirestore.instance.collection("users").doc(uid).set(userDoc);

      AppComponents.showAppSnack(
        context,
        title: "Account created",
        message: _role == "freelancer"
            ? "Welcome • Please complete your freelancer profile."
            : "Welcome • Account created successfully.",
        type: SnackType.success,
      );

      if (!mounted) return;

      if (_role == "freelancer") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteFreelancerProfileScreen()),
        );
      } else {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      AppComponents.showAppSnack(
        context,
        title: "Sign up failed",
        message: _friendlyAuthError(e.code),
        type: SnackType.error,
      );
    } catch (_) {
      AppComponents.showAppSnack(
        context,
        title: "Sign up failed",
        message: "Something went wrong.",
        type: SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case "email-already-in-use":
        return "This email is already used.";
      case "invalid-email":
        return "Invalid email address.";
      case "weak-password":
        return "Password is too weak.";
      case "network-request-failed":
        return "Network error. Check your connection.";
      default:
        return "Sign up failed. Try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _bgSlate,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                height: size.height * 0.36,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_brandNavy, _slateBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -60,
              child: _GlowCircle(size: 320, color: _slateBlue.withOpacity(0.08)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    _topBar(context),
                    const SizedBox(height: 20),
                    _titleBlock(),
                    const SizedBox(height: 26),
                    _glassCard(context),
                    const SizedBox(height: 18),
                    _footer(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      //  const Spacer(),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Image.asset(
            "assets/images/appLogo.png",
            height: 36,
            width: 36,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _titleBlock() {
    return Column(
      children: [
        const Text(
          "Create Account",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Choose account type and enter your information",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.82),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _glassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Account Type",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _textDark),
                ),
                const SizedBox(height: 10),
                _roleSelector(),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _fullName,
                  label: "Full Name",
                  hint: "Your full name",
                  prefixIcon: const Icon(Icons.person_rounded, color: _brandNavy, size: 20),
                  validator: (v) => (v ?? "").trim().isEmpty ? "Full name is required" : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _email,
                  label: "Email Address",
                  hint: "user@gmail.com",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: _brandNavy, size: 20),
                  validator: (v) {
                    final s = (v ?? "").trim();
                    if (s.isEmpty) return "Email is required";
                    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(s);
                    if (!ok) return "Enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phone,
                  label: "Phone",
                  hint: "05xxxxxxxx",
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_rounded, color: _brandNavy, size: 20),
                  validator: (v) => (v ?? "").trim().isEmpty ? "Phone is required" : null,

                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _city,
                  label: "City",
                  hint: "Your city",
                  prefixIcon: const Icon(Icons.location_on_rounded, color: _brandNavy, size: 20),
                  validator: (v) => (v ?? "").trim().isEmpty ? "City is required" : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _pass,
                  label: "Password",
                  hint: "••••••••",
                  obscureText: _hidePass,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: _brandNavy, size: 20),
                  suffixIcon: IconButton(
                    onPressed: _loading ? null : () => setState(() => _hidePass = !_hidePass),
                    icon: Icon(
                      _hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: _brandNavy,
                    ),
                  ),
                  validator: (v) => (v ?? "").length < 6 ? "Minimum 6 characters" : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirm,
                  label: "Confirm Password",
                  hint: "••••••••",
                  obscureText: _hideConfirm,
                  prefixIcon: const Icon(Icons.lock_rounded, color: _brandNavy, size: 20),
                  suffixIcon: IconButton(
                    onPressed: _loading ? null : () => setState(() => _hideConfirm = !_hideConfirm),
                    icon: Icon(
                      _hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: _brandNavy,
                    ),
                  ),
                  validator: (v) {
                    if ((v ?? "").isEmpty) return "Confirm password is required";
                    if (v != _pass.text) return "Passwords do not match";
                    return null;
                  },
                  onFieldSubmitted: (_) => _loading ? null : _createAccount(),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [_brandNavy, _slateBlue],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brandNavy.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    child: AppSecondaryButton(
                      text: "CREATE ACCOUNT",
                      loading: _loading,
                      onPressed: _loading ? null : _createAccount,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RolePill(
              active: _role == "client",
              title: "Client",
              icon: Icons.work_outline_rounded,
              onTap: _loading ? null : () => setState(() => _role = "client"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RolePill(
              active: _role == "freelancer",
              title: "Freelancer",
              icon: Icons.build_circle_outlined,
              onTap: _loading ? null : () => setState(() => _role = "freelancer"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account?",
          style: TextStyle(color: _textMuted, fontWeight: FontWeight.w500),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text(
            "Sign In",
            style: TextStyle(color: _brandNavy, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  final bool active;
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _RolePill({
    required this.active,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: active
              ? const LinearGradient(
            colors: [Color(0xFF0A2A43), Color(0xFF0C4A6E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          )
              : null,
          color: active ? null : Colors.white,
          border: Border.all(color: active ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : const Color(0xFF0A2A43)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : const Color(0xFF0A2A43),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(size.width * 0.2, size.height, size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(size.width * 0.8, size.height - 80, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    );
  }
}
