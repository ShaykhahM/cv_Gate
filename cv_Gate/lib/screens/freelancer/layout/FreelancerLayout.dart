import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/bloc/freelancer%20bloc/cubit.dart';
import 'package:cv_gate/screens/Freelancer/Layout/FreelancerNavBar.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/freelancer bloc/states.dart';

class FreelancerLayout extends StatelessWidget {
  const FreelancerLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FreelancerCubit, FreelancerState>(
      listener: (context, state) {},
      builder: (context, state) {
        final cubit = FreelancerCubit.get(context);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(freelancerId).snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data();
            final isActive = data?['isActive'] == true;

            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (data == null) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: _InactiveAccountView(
                  title: 'Account Not Available',
                  message: 'Your account data could not be loaded at the moment.',
                ),
              );
            }

            if (!isActive) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: _InactiveAccountView(
                  title: 'Account Not Active',
                  message: 'Your freelancer account is currently inactive. Please contact the administrator if you think this is a mistake.',
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              body: cubit.freelancerScreens[cubit.currentScreen],
              bottomNavigationBar: FreelancerNavBar(
                currentIndex: cubit.currentScreen,
                onTabChange: (index) {
                  cubit.changeScreen(index);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _InactiveAccountView extends StatelessWidget {
  final String title;
  final String message;

  const _InactiveAccountView({
    required this.title,
    required this.message,
  });

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.60),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.error.withOpacity(0.90),
                            const Color(0xFFF97316),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.20),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}