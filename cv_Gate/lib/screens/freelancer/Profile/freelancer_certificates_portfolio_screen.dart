import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FreelancerCertificatesPortfolioScreen extends StatefulWidget {
  final freelancerId;
  const FreelancerCertificatesPortfolioScreen({required this.freelancerId,super.key});

  @override
  State<FreelancerCertificatesPortfolioScreen> createState() => _FreelancerCertificatesPortfolioScreenState();
}

class _FreelancerCertificatesPortfolioScreenState extends State<FreelancerCertificatesPortfolioScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _refreshing = false;

  // String? get freelancerId => _auth.currentUser?.uid;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  Future<void> _openUrl(String url) async {
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null) {
      _showSnack('Invalid file URL.', AppColors.error);
      return;
    }

    final ok = await launchUrl(
      parsed,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      _showSnack('Could not open the file link.', AppColors.error);
    }
  }

  Future<void> _showAddCertificateSheet() async {
    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final issueDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool saving = false;
    PlatformFile? pickedFile;
    String selectedFileName = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickCertificateFile() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  withData: false,
                  type: FileType.custom,
                  allowedExtensions: [
                    'pdf',
                    'png',
                    'jpg',
                    'jpeg',
                    'doc',
                    'docx',
                  ],
                );

                if (result == null || result.files.isEmpty) return;

                final file = result.files.first;
                if (file.path == null || file.path!.trim().isEmpty) {
                  _showSnack('Failed to read selected file.', AppColors.error);
                  return;
                }

                setModalState(() {
                  pickedFile = file;
                  selectedFileName = file.name;
                });
              } catch (_) {
                _showSnack('Failed to pick file.', AppColors.error);
              }
            }

            Future<String> uploadCertificateFile(String uid) async {
              if (pickedFile == null || pickedFile!.path == null) {
                throw Exception('No file selected');
              }

              final file = File(pickedFile!.path!);
              final extension = pickedFile!.extension ?? 'file';
              final safeName = DateTime.now().millisecondsSinceEpoch.toString();

              final ref = _storage.ref().child(
                'users/$uid/certificates/cert_$safeName.$extension',
              );

              await ref.putFile(file);
              return await ref.getDownloadURL();
            }

            Future<void> saveCertificate() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              if (pickedFile == null) {
                _showSnack('Please choose certificate file first.', AppColors.warning);
                return;
              }

              final uid = widget.freelancerId;
              if (uid == null) return;

              setModalState(() => saving = true);

              try {
                final fileUrl = await uploadCertificateFile(uid);

                final certRef = _db
                    .collection('users')
                    .doc(uid)
                    .collection('certificates')
                    .doc();

                await certRef.set({
                  'certId': certRef.id,
                  'name': nameController.text.trim(),
                  'issuer': issuerController.text.trim(),
                  'issueDate': issueDateController.text.trim(),
                  'fileUrl': fileUrl,
                  'verifyStatus': 'pending',
                  'verifyNote': '',
                  'verifiedBy': null,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                _showSnack('Certificate added successfully.', AppColors.success);
                setState(() {});
              } catch (_) {
                setModalState(() => saving = false);
                _showSnack('Failed to add certificate.', AppColors.error);
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium_outlined,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add Certificate',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add a new professional certificate to your profile',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _AppField(
                              controller: nameController,
                              label: 'Certificate Name',
                              hint: 'e.g. Flutter Development Certificate',
                              icon: Icons.badge_outlined,
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return 'Certificate name is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AppField(
                              controller: issuerController,
                              label: 'Issuer',
                              hint: 'e.g. Google, Coursera',
                              icon: Icons.business_outlined,
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return 'Issuer is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AppField(
                              controller: issueDateController,
                              label: 'Issue Date',
                              hint: 'e.g. 2026-03-15',
                              icon: Icons.date_range_outlined,
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return 'Issue date is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Certificate File',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedFileName.isEmpty
                                              ? 'No file selected'
                                              : selectedFileName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: saving ? null : pickCertificateFile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.info,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        icon: const Icon(Icons.attach_file_rounded),
                                        label: const Text(
                                          'Choose',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Allowed: PDF, PNG, JPG, JPEG, DOC, DOCX',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: saving ? null : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 50),
                                      side: BorderSide(
                                        color: AppColors.textLight.withOpacity(0.6),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: saving ? null : saveCertificate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        minimumSize: const Size(double.infinity, 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        saving ? 'Saving...' : 'Add',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
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
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    issuerController.dispose();
    issueDateController.dispose();
  }

  Future<void> _showAddPortfolioLinkSheet(List<Map<String, dynamic>> currentLinks) async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveLink() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final uid = widget.freelancerId;
              if (uid == null) return;

              setModalState(() => saving = true);

              try {
                final updatedLinks = List<Map<String, dynamic>>.from(currentLinks)
                  ..add({
                    'title': titleController.text.trim(),
                    'url': urlController.text.trim(),
                  });

                await _db
                    .collection('users')
                    .doc(uid)
                    .collection('profile')
                    .doc('main')
                    .set({
                  'portfolioLinks': updatedLinks,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);
                _showSnack('Portfolio link added successfully.', AppColors.success);
                setState(() {});
              } catch (_) {
                setModalState(() => saving = false);
                _showSnack('Failed to add portfolio link.', AppColors.error);
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.link_rounded,
                                    color: AppColors.info,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add Portfolio Link',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add title and link for your previous work',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _AppField(
                              controller: titleController,
                              label: 'Link Title',
                              hint: 'e.g. GitHub Profile',
                              icon: Icons.title_rounded,
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return 'Link title is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AppField(
                              controller: urlController,
                              label: 'Link URL',
                              hint: 'https://github.com/yourname',
                              icon: Icons.link_rounded,
                              keyboardType: TextInputType.url,
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'Link URL is required';
                                final uri = Uri.tryParse(value);
                                final ok = uri != null &&
                                    uri.hasScheme &&
                                    (uri.scheme == 'http' || uri.scheme == 'https');
                                if (!ok) return 'Enter a valid URL';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: saving ? null : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 50),
                                      side: BorderSide(
                                        color: AppColors.textLight.withOpacity(0.6),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: saving ? null : saveLink,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        minimumSize: const Size(double.infinity, 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        saving ? 'Saving...' : 'Add',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
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
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    urlController.dispose();
  }

  Future<void> _removePortfolioLink(List<Map<String, dynamic>> currentLinks, int index) async {
    final uid = widget.freelancerId;
    if (uid == null) return;

    try {
      final updated = List<Map<String, dynamic>>.from(currentLinks)..removeAt(index);

      await _db
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('main')
          .set({
        'portfolioLinks': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showSnack('Portfolio link removed.', AppColors.success);
      setState(() {});
    } catch (_) {
      _showSnack('Failed to remove portfolio link.', AppColors.error);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> _extractPortfolioLinks(dynamic value) {
    final result = <Map<String, dynamic>>[];

    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final title = (item['title'] ?? '').toString().trim();
          final url = (item['url'] ?? '').toString().trim();
          if (url.isNotEmpty) {
            result.add({
              'title': title.isEmpty ? 'Portfolio Link' : title,
              'url': url,
            });
          }
        } else {
          final url = item.toString().trim();
          if (url.isNotEmpty) {
            result.add({
              'title': 'Portfolio Link',
              'url': url,
            });
          }
        }
      }
      return result;
    }

    if (value is Map) {
      value.forEach((key, val) {
        final title = key.toString().trim();
        final url = val.toString().trim();
        if (url.isNotEmpty) {
          result.add({
            'title': title.isEmpty ? 'Portfolio Link' : title,
            'url': url,
          });
        }
      });
    }

    return result;
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'verified') return AppColors.success;
    if (s == 'rejected') return AppColors.error;
    return AppColors.warning;
  }

  String _formatStatus(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'verified') return 'Verified';
    if (s == 'rejected') return 'Rejected';
    if (s == 'pending') return 'Pending';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.freelancerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _NotLoggedInState(),
      );
    }

    final certsQuery = _db
        .collection('users')
        .doc(widget.freelancerId)
        .collection('certificates')
        .orderBy('createdAt', descending: true);

    final profileDoc = _db
        .collection('users')
        .doc(widget.freelancerId)
        .collection('profile')
        .doc('main');

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
            'Certificates & Portfolio',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _refreshing ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A2A43),
                  Color(0xFF0C4A6E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCertificateSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Certificate',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.folder_open_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Certificates & Portfolio',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add your certificates, check verification status, and manage your portfolio links',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Certificates',
                  subtitle: 'Your uploaded certificates and verification result',
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: certsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: _ErrorCard(
                        text: 'Failed to load certificates.',
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: _GlassCard(
                        child: Column(
                          children: const [
                            SizedBox(
                              height: 120,
                              child: _SoftLoadingBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyCard(
                        icon: Icons.workspace_premium_outlined,
                        title: 'No certificates yet',
                        subtitle: 'Add your professional certificates to increase trust.',
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  sliver: SliverList.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final name = (data['name'] ?? '-').toString().trim();
                      final issuer = (data['issuer'] ?? '-').toString().trim();
                      final issueDate = (data['issueDate'] ?? '-').toString().trim();
                      final fileUrl = (data['fileUrl'] ?? '').toString().trim();
                      final verifyStatus = (data['verifyStatus'] ?? 'pending').toString().trim();
                      final verifyNote = (data['verifyNote'] ?? '').toString().trim();

                      return _CertificateCard(
                        name: name,
                        issuer: issuer,
                        issueDate: issueDate,
                        fileUrl: fileUrl,
                        verifyStatus: _formatStatus(verifyStatus),
                        verifyColor: _statusColor(verifyStatus),
                        verifyNote: verifyNote,
                        onOpenFile: fileUrl.isEmpty ? null : () => _openUrl(fileUrl),
                      );
                    },
                  ),
                );
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Portfolio Links',
                  subtitle: 'Manage links to your previous work and public profiles',
                ),
              ),
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: profileDoc.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: _ErrorCard(
                        text: 'Failed to load portfolio links.',
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: _GlassCard(
                        child: const SizedBox(
                          height: 120,
                          child: _SoftLoadingBox(),
                        ),
                      ),
                    ),
                  );
                }

                final profileData = snapshot.data!.data() ?? {};
                final links = _extractPortfolioLinks(profileData['portfolioLinks']);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _GlassCard(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAddPortfolioLinkSheet(links),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(double.infinity, 52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text(
                                    'Add Portfolio Link',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (links.isEmpty)
                          const _EmptyCard(
                            icon: Icons.link_rounded,
                            title: 'No portfolio links yet',
                            subtitle: 'Add GitHub, Behance, LinkedIn, or portfolio website links.',
                          ),
                        if (links.isNotEmpty)
                          ...List.generate(
                            links.length,
                                (index) => Padding(
                              padding: EdgeInsets.only(bottom: index == links.length - 1 ? 0 : 12),
                              child: _PortfolioCard(
                                title: (links[index]['title'] ?? 'Portfolio Link').toString(),
                                url: (links[index]['url'] ?? '').toString(),
                                onOpen: () => _openUrl((links[index]['url'] ?? '').toString()),
                                onDelete: () => _removePortfolioLink(links, index),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final String name;
  final String issuer;
  final String issueDate;
  final String fileUrl;
  final String verifyStatus;
  final Color verifyColor;
  final String verifyNote;
  final VoidCallback? onOpenFile;

  const _CertificateCard({
    required this.name,
    required this.issuer,
    required this.issueDate,
    required this.fileUrl,
    required this.verifyStatus,
    required this.verifyColor,
    required this.verifyNote,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issuer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: verifyStatus,
                color: verifyColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            tint: AppColors.info,
            label: 'Issue Date',
            value: issueDate,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.insert_drive_file_outlined,
            tint: AppColors.primary,
            label: 'Certificate File',
            valueWidget: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Open uploaded file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (fileUrl.isNotEmpty)
                  InkWell(
                    onTap: onOpenFile,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.open_in_new_rounded,
                        color: AppColors.info,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.info_outline_rounded,
            tint: verifyColor,
            label: 'Verification Note',
            value: verifyNote.isEmpty ? 'No note yet.' : verifyNote,
          ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _PortfolioCard({
    required this.title,
    required this.url,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: AppColors.info,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.success,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailRow({
    required this.icon,
    required this.tint,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: tint,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              valueWidget ??
                  Text(
                    value ?? '-',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AppField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF0A2A43),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.4,
          ),
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

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String text;

  const _ErrorCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
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

class _NotLoggedInState extends StatelessWidget {
  const _NotLoggedInState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(22),
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'You need to login first.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}