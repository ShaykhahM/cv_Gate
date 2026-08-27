import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/bloc/admin%20bloc/cubit.dart';
import 'package:cv_gate/screens/splash/Splash_Screen.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:cv_gate/shared/services/local/Cahs_Helper.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {


  const AdminSettingsScreen({
    super.key,

  });

  @override
  Widget build(BuildContext context) {
    return _AdminSettingsBody();
  }
}

class _AdminSettingsBody extends StatefulWidget {


  const _AdminSettingsBody();

  @override
  State<_AdminSettingsBody> createState() => _AdminSettingsBodyState();
}

class _AdminSettingsBodyState extends State<_AdminSettingsBody> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _slateBlue = Color(0xFF0C4A6E);
  static const _bgSlate = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> _showContractTemplateSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ContractTemplateSheet(db: _db),
    );
  }

  Future<void> _sendResetPasswordEmail() async {
    try {
      final doc = await _db.collection('users').doc(adminId).get();

      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin account not found")),
        );
        return;
      }

      final data = doc.data() ?? {};
      final email = (data['email'] ?? '').toString().trim();

      if (email.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin email is not available")),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Reset Password",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Text(
              "A password reset link will be sent to:\n\n$email",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Send Link",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset link sent to $email"),
        ),
      );
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send reset email")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (){
                adminId='';
                CashHelper.removeCash(key: 'token');
                CashHelper.saveCash(key: 'userIndex', value: 0);
                AdminCubit.get(context).currentScreen=2;
                NextWidget(context: context, screen: SplashScreen(0));
              },
              child: const Text(
                "Logout",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _auth.signOut();

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
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
            "Settings",
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(adminId).snapshots(),
        builder: (context, snap) {
          String adminEmail = "No email available";
          String adminName = "Admin Account";

          if (snap.hasData && snap.data!.exists) {
            final data = snap.data!.data() ?? {};
            final email = (data['email'] ?? '').toString().trim();
            final name = (data['fullName'] ?? '').toString().trim();

            if (email.isNotEmpty) adminEmail = email;
            if (name.isNotEmpty) adminName = name;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              children: [
                _GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_brandNavy, _slateBlue],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adminName,
                              style: const TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              adminEmail,
                              style: const TextStyle(
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  child: Column(
                    children: [
                      const _SectionTitle(
                        icon: Icons.settings_outlined,
                        title: "System Settings",
                      ),
                      const SizedBox(height: 14),
                      _SettingTile(
                        icon: Icons.lock_reset_rounded,
                        title: "Change Password",
                        subtitle: "Send a password reset link to admin email",
                        onTap: _sendResetPasswordEmail,
                      ),
                      Divider(height: 18, color: Colors.black.withOpacity(0.06)),
                      _SettingTile(
                        icon: Icons.description_outlined,
                        title: "Contracts Template",
                        subtitle: "Edit the contract placeholder text",
                        onTap: _showContractTemplateSheet,
                      ),
                      Divider(height: 18, color: Colors.black.withOpacity(0.06)),
                      _SettingTile(
                        icon: Icons.logout_rounded,
                        title: "Logout",
                        subtitle: "Sign out from the admin account",
                        danger: true,
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('template').doc('contractTemp').snapshots(),
                  builder: (context, snap) {
                    String title = "Contract Template";
                    String content = "No template saved yet";

                    if (snap.hasData && snap.data!.exists) {
                      final data = snap.data!.data() ?? {};
                      final t = (data['title'] ?? '').toString().trim();
                      final c = (data['content'] ?? '').toString().trim();
                      if (t.isNotEmpty) title = t;
                      if (c.isNotEmpty) content = c;
                    }

                    return _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            icon: Icons.preview_outlined,
                            title: "Template Preview",
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            style: const TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            content,
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.8,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContractTemplateSheet extends StatefulWidget {
  final FirebaseFirestore db;

  const _ContractTemplateSheet({
    required this.db,
  });

  @override
  State<_ContractTemplateSheet> createState() => _ContractTemplateSheetState();
}

class _ContractTemplateSheetState extends State<_ContractTemplateSheet> {
  static const _brandNavy = Color(0xFF0A2A43);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final doc = await widget.db.collection('template').doc('contractTemp').get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _titleController.text = (data['title'] ?? '').toString();
        _contentController.text = (data['content'] ?? '').toString();
      } else {
        _titleController.text = "Standard Contract Template";
        _contentController.text =
        "This contract is made between the client and the freelancer.\n\nProject Scope:\n- [Write project scope here]\n\nTimeline:\n- [Write timeline here]\n\nPayment Terms:\n- [Write payment terms here]\n\nDeliverables:\n- [Write deliverables here]\n\nAdditional Notes:\n- [Write additional notes here]";
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveTemplate() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all template fields")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.db.collection('template').doc('contractTemp').set({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contract template updated successfully")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update template")),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _textMuted.withOpacity(0.8),
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.025),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: _brandNavy, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
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
              child: _loading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              )
                  : Column(
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
                            colors: [_brandNavy, Color(0xFF0C4A6E)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.description_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Contracts Template",
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
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: _inputDecoration(hint: "Template title"),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _contentController,
                            maxLines: 12,
                            decoration: _inputDecoration(
                              hint: "Write contract placeholder text here",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveTemplate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Save Template",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
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

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : _textDark;
    final iconBg = danger
        ? const Color(0xFFDC2626).withOpacity(0.10)
        : Colors.black.withOpacity(0.04);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: danger ? const Color(0xFFDC2626) : _textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: danger ? const Color(0xFFDC2626) : _textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

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
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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