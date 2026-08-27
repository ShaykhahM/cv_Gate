import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/bloc/client/cubit.dart';
import 'package:cv_gate/screens/client/profile/client_edit_profile_screen.dart';
import 'package:cv_gate/screens/splash/Splash_Screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/components.dart';
import 'package:cv_gate/shared/services/local/Cahs_Helper.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid =>clientId;

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadUser() {
    return _db.collection('users').doc(_uid).get();
  }

  Future<void> _openEditProfile() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientEditProfileScreen(),
      ),
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _showResetPasswordDialog(String email) async {
    bool sending = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Reset Password',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A password reset link will be sent to this email:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                    try {
                      setDialogState(() {
                        sending = true;
                      });

                      await _auth.sendPasswordResetEmail(email: email);

                      if (!mounted) return;
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Password reset email sent successfully'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    } catch (_) {
                      if (!mounted) return;

                      setDialogState(() {
                        sending = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Failed to send reset email'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: sending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showLogoutDialog() async {
    bool loading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                    try {
                      setDialogState(() {
                        loading = true;
                      });

                      await _auth.signOut();
                      clientId='';
                      CashHelper.removeCash(key: 'token');
                      CashHelper.saveCash(key: 'userIndex', value: 0);
                      ClientCubit.get(context).currentScreen=0;
                      NextWidget(context: context, screen: SplashScreen(0));

                    } catch (_) {
                      if (!mounted) return;

                      setDialogState(() {
                        loading = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Failed to logout'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    bool loading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Delete Account Data',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: const Text(
                'This action will remove your account-related data. This cannot be undone.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                    try {
                      setDialogState(() {
                        loading = true;
                      });

                      final uid = _uid;

                      final jobs = await _db.collection('jobs').where('clientId', isEqualTo: uid).get();
                      final applications = await _db.collection('applications').where('clientId', isEqualTo: uid).get();
                      final contracts = await _db.collection('contracts').where('clientId', isEqualTo: uid).get();
                      final payments = await _db.collection('payments').where('clientId', isEqualTo: uid).get();
                      final reviews = await _db.collection('reviews').where('fromUserId', isEqualTo: uid).get();
                      final notifications = await _db.collection('notifications').where('recipientId', isEqualTo: uid).get();
                      final disputes = await _db.collection('disputes').where('clientId', isEqualTo: uid).get();
                      final submissions = await _db.collection('submissions').where('clientId', isEqualTo: uid).get();
                      final credentials = await _db.collection('users').doc(uid).collection('credentials').get();

                      Future<void> deleteInBatches(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
                        const chunkSize = 400;
                        for (int i = 0; i < docs.length; i += chunkSize) {
                          final batch = _db.batch();
                          final chunk = docs.skip(i).take(chunkSize);
                          for (final doc in chunk) {
                            batch.delete(doc.reference);
                          }
                          await batch.commit();
                        }
                      }

                      await deleteInBatches(jobs.docs);
                      await deleteInBatches(applications.docs);
                      await deleteInBatches(contracts.docs);
                      await deleteInBatches(payments.docs);
                      await deleteInBatches(reviews.docs);
                      await deleteInBatches(notifications.docs);
                      await deleteInBatches(disputes.docs);
                      await deleteInBatches(submissions.docs);
                      await deleteInBatches(credentials.docs);

                      await _db.collection('users').doc(uid).delete();

                      if (!mounted) return;
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Firestore account data deleted successfully'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    } catch (_) {
                      if (!mounted) return;

                      setDialogState(() {
                        loading = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Failed to delete account data'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openCredentialsPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Credentials / portfolio screen can be connected here'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

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
          title: const Text(
            'Profile',
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
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _loadUser(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: SizedBox(height: 180, child: _SoftLoadingBox()),
                  ),
                  SizedBox(height: 14),
                  _GlassCard(
                    child: SizedBox(height: 280, child: _SoftLoadingBox()),
                  ),
                ],
              );
            }

            final data = snap.data?.data();

            if (data == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Profile not found',
                      subtitle: 'The client profile data could not be loaded.',
                    ),
                  ),
                ],
              );
            }

            final fullName = (data['fullName'] ?? '').toString().trim();
            final email = (data['email'] ?? '').toString().trim();
            final phone = (data['phone'] ?? '').toString().trim();
            final city = (data['city'] ?? '').toString().trim();
            final role = (data['role'] ?? 'client').toString().trim();
            final isActive = data['isActive'] == true;
            final photoUrl = (data['photoUrl'] ?? '').toString().trim();

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _GlassCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.primary.withOpacity(0.10),
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(
                          _initials(fullName.isEmpty ? 'Client' : fullName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName.isEmpty ? 'Client' : fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email.isEmpty ? 'No email' : email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Full Name', value: fullName.isEmpty ? 'Not specified' : fullName),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Email', value: email.isEmpty ? 'Not specified' : email),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Phone', value: phone.isEmpty ? 'Not specified' : phone),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'City', value: city.isEmpty ? 'Not specified' : city),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Role', value: role.toUpperCase()),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 108,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _AccountStatusChip(
                            isActive: isActive,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ActionButton(
                        title: 'Edit Profile',
                        icon: Icons.edit_outlined,
                        color: AppColors.primary,
                        onTap: _openEditProfile,
                      ),
                      // const SizedBox(height: 10),
                      // _ActionButton(
                      //   title: 'Upload Credentials / Portfolio',
                      //   icon: Icons.folder_open_outlined,
                      //   color: AppColors.accent,
                      //   onTap: _openCredentialsPlaceholder,
                      // ),
                      const SizedBox(height: 10),
                      _ActionButton(
                        title: 'Reset Password',
                        icon: Icons.lock_reset_rounded,
                        color: AppColors.warning,
                        onTap: () => _showResetPasswordDialog(email),
                      ),
                      const SizedBox(height: 10),
                      _ActionButton(
                        title: 'Delete Account Data',
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        onTap: _showDeleteAccountDialog,
                      ),
                      const SizedBox(height: 10),
                      _ActionButton(
                        title: 'Logout',
                        icon: Icons.logout_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: _showLogoutDialog,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountStatusChip extends StatelessWidget {
  final bool isActive;

  const _AccountStatusChip({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? AppColors.success.withOpacity(0.14) : AppColors.error.withOpacity(0.14);
    final fg = isActive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.2,
          letterSpacing: 0.2,
        ),
      ),
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

class _SoftLoadingBox extends StatelessWidget {
  const _SoftLoadingBox();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.black.withOpacity(0.03),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}