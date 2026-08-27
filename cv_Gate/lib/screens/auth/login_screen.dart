import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/Admin/Layout/Admin_Layout.dart';
import 'package:cv_gate/screens/client/layout/clientHome_Layout.dart';
import 'package:cv_gate/screens/freelancer/layout/FreelancerLayout.dart';
import 'package:cv_gate/shared/services/local/Cahs_Helper.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/app_colors.dart';
import '../../shared/components.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;

  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _email.text.trim());
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    await showDialog(
      context: context,
      barrierDismissible: !sending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_brandNavy, _slateBlue],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _brandNavy.withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your email address and we will send you a password reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.8,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !sending,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Email is required';
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'alex@company.com',
                    prefixIcon: const Icon(
                      Icons.alternate_email_rounded,
                      color: _brandNavy,
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _brandNavy, width: 1.2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: sending ? null : () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textMuted,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: sending
                            ? null
                            : () async {
                          final valid = formKey.currentState?.validate() ?? false;
                          if (!valid) return;

                          final email = emailController.text.trim();

                          setDialogState(() {
                            sending = true;
                          });

                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                            if (!mounted) return;
                            Navigator.pop(dialogContext);

                            await _showResetSuccessDialog(email);
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              sending = false;
                            });

                            if (!mounted) return;

                            AppComponents.showAppSnack(
                              context,
                              title: 'Reset failed',
                              message: _friendlyResetError(e.code),
                              type: SnackType.error,
                            );
                          } catch (_) {
                            setDialogState(() {
                              sending = false;
                            });

                            if (!mounted) return;

                            AppComponents.showAppSnack(
                              context,
                              title: 'Reset failed',
                              message: 'Something went wrong. Please try again.',
                              type: SnackType.error,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandNavy,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _brandNavy.withOpacity(0.55),
                          minimumSize: const Size.fromHeight(48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: sending
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Send Link',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  Future<void> _showResetSuccessDialog(String email) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.success,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Check Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'We sent a password reset link to:\n$email\n\nPlease open your email and follow the link to create a new password.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12.8,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void simpleLogin(String email, String password) {
    FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password).then((value) {
      FirebaseFirestore.instance.collection('users').doc(value.user!.uid).get().then((userData) {
        final userEmail = userData['fullName'];
      });
    }).catchError((error) {});
  }

  Future<void> _login() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        AppComponents.showAppSnack(context, title: "Login failed", message: "Missing user ID.", type: SnackType.error);
        setState(() => _loading = false);
        return;
      }

      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      final role = _normalizeRole((data['role'] ?? '').toString().trim().toLowerCase());

      CashHelper.saveCash(key: 'token', value: uid);

      switch (role) {
        case 'Admin':
          adminId = uid;
          CashHelper.saveCash(key: 'userIndex', value: 1);
          NextWidget(context: context, screen: AdminLayout());
          break;
        case 'Freelancer':
          freelancerId = uid;
          CashHelper.saveCash(key: 'userIndex', value: 2);
          NextWidget(context: context, screen: FreelancerLayout());
          break;
        case 'Client':
          clientId = uid;
          CashHelper.saveCash(key: 'userIndex', value: 3);
          NextWidget(context: context, screen: ClientLayout());
          break;
        default:
          await FirebaseAuth.instance.signOut();
          AppComponents.showAppSnack(context, title: "Login failed", message: "Unknown account role.", type: SnackType.error);
      }
    } on FirebaseAuthException catch (e) {
      AppComponents.showAppSnack(context, title: "Login error", message: _friendlyAuthError(e.code), type: SnackType.error);
    } catch (_) {
      AppComponents.showAppSnack(context, title: "Login error", message: "Something went wrong.", type: SnackType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _normalizeRole(String r) {
    if (r == 'client' || r == 'job_seeker') return 'Client';
    if (r == 'freelancer' || r == 'technician') return 'Freelancer';
    if (r == 'admin' || r == 'administrator') return 'Admin';
    return r.isEmpty ? 'Unknown' : r[0].toUpperCase() + r.substring(1);
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return "No account found.";
      case 'wrong-password':
        return "Wrong password.";
      case 'invalid-email':
        return "Invalid email address.";
      case 'invalid-credential':
        return "Invalid email or password.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      default:
        return "Login failed.";
    }
  }

  String _friendlyResetError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Could not send reset link.';
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
                height: size.height * 0.4,
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
              bottom: -100,
              right: -50,
              child: _GlowCircle(size: 300, color: _slateBlue.withOpacity(0.08)),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.07),
                  _buildBrandHeader(),
                  const SizedBox(height: 55),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildGlassCard(context),
                  ),
                  const SizedBox(height: 30),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Image.asset(
            'assets/images/appLogo.png',
            height: 75,
            width: 75,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "CVGate",
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
        ),
        Text(
          "Connect with trusted talent",
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Sign In", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textDark)),
                const SizedBox(height: 8),
                const Text("Enter your credentials to continue", style: TextStyle(color: _textMuted, fontSize: 14)),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _email,
                  label: "Email Address",
                  hint: "alex@company.com",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: _brandNavy, size: 20),
                  validator: (v) => (v ?? '').isEmpty ? "Email is required" : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _password,
                  label: "Password",
                  hint: "••••••••",
                  obscureText: _hidePass,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: _brandNavy, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _hidePass = !_hidePass),
                    icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: _brandNavy),
                  ),
                  onFieldSubmitted: (_) => _login(),
                  validator: (v) => (v ?? '').length < 6 ? "Minimum 6 characters" : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _showForgotPasswordDialog,
                    child: const Text("Forgot Password?", style: TextStyle(color: _brandNavy, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
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
                      BoxShadow(color: _brandNavy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
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
                      text: "LOGIN",
                      loading: _loading,
                      onPressed: _loading ? null : _login,
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

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?", style: TextStyle(color: _textMuted, fontWeight: FontWeight.w500)),
        TextButton(
          onPressed: _loading
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(color: _brandNavy, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
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