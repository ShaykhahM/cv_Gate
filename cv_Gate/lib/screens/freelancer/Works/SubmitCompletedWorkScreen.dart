import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/core/styles/colors.dart';
import 'package:file_picker/file_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';


class SubmitCompletedWorkScreen extends StatefulWidget {
  final String contractId;
  final String freelancerId;

  const SubmitCompletedWorkScreen({
    super.key,
    required this.contractId,
    required this.freelancerId,
  });

  @override
  State<SubmitCompletedWorkScreen> createState() => _SubmitCompletedWorkScreenState();
}

class _SubmitCompletedWorkScreenState extends State<SubmitCompletedWorkScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _noteController = TextEditingController();

  bool _submitting = false;
  List<PlatformFile> _pickedFiles = [];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _pickedFiles = result.files;
      });
    } catch (e) {
      debugPrint('SubmitCompletedWorkScreen _pickFiles error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick files.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
    });
  }

  Future<List<Map<String, dynamic>>> _uploadFiles(String submissionId) async {
    final List<Map<String, dynamic>> uploadedFiles = [];

    for (final file in _pickedFiles) {
      final fileName = file.name.trim();
      final storagePath =
          'submissions/${widget.contractId}/$submissionId/$fileName';

      final ref = _storage.ref().child(storagePath);

      UploadTask uploadTask;

      if (file.path != null && file.path!.isNotEmpty) {
        uploadTask = ref.putFile(File(file.path!));
      } else if (file.bytes != null) {
        uploadTask = ref.putData(file.bytes!);
      } else {
        continue;
      }

      final snap = await uploadTask;
      final url = await snap.ref.getDownloadURL();

      uploadedFiles.add({
        'name': fileName,
        'url': url,
        'storagePath': storagePath,
        'size': file.size,
      });
    }

    return uploadedFiles;
  }

  Future<void> _submitWork(Map<String, dynamic> contractData) async {
    final note = _noteController.text.trim();

    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery note.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one file.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() {
        _submitting = true;
      });

      final clientId = (contractData['clientId'] ?? '').toString().trim();
      final jobId = (contractData['jobId'] ?? '').toString().trim();

      final submissionRef = _db.collection('submissions').doc();
      final notifRef = _db.collection('notifications').doc();

      final uploadedFiles = await _uploadFiles(submissionRef.id);

      await submissionRef.set({
        'submissionId': submissionRef.id,
        'contractId': widget.contractId,
        'jobId': jobId,
        'clientId': clientId,
        'freelancerId': widget.freelancerId,
        'note': note,
        'files': uploadedFiles,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('contracts').doc(widget.contractId).update({
        'status': 'submitted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (clientId.isNotEmpty) {
        await notifRef.set({
          'notifId': notifRef.id,
          'recipientId': clientId,
          'type': 'work_submitted',
          'title': 'Completed work submitted',
          'body': 'The freelancer submitted the completed work for your review.',
          'refType': 'submissions',
          'refId': widget.contractId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed work submitted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('SubmitCompletedWorkScreen _submitWork error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit completed work.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
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
          centerTitle: false,
          title: const Text(
            'Submit Work',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _refresh,
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
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _db.collection('contracts').doc(widget.contractId).get(),
        builder: (context, contractSnapshot) {
          if (contractSnapshot.hasError) {
            debugPrint('SubmitCompletedWorkScreen contract error: ${contractSnapshot.error}');
            return _ErrorState(onRetry: _refresh);
          }

          if (!contractSnapshot.hasData) {
            return const _LoadingView();
          }

          if (!contractSnapshot.data!.exists) {
            return const _NotFoundState();
          }

          final contractData = contractSnapshot.data!.data() ?? {};
          final jobId = (contractData['jobId'] ?? '').toString().trim();
          final agreedPrice = contractData['agreedPrice'];
          final currency = (contractData['currency'] ?? 'SAR').toString().trim();
          final duration = (contractData['agreedDurationDays'] ?? '-').toString();
          final status = (contractData['status'] ?? 'draft').toString().trim();

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: jobId.isEmpty ? Future.value(null) : _db.collection('jobs').doc(jobId).get(),
            builder: (context, jobSnapshot) {
              final jobData = jobSnapshot.data?.data() ?? {};
              final jobTitle = (jobData['title'] ?? 'Unknown Job').toString().trim();

              final canSubmit = status.toLowerCase() == 'active';

              return RefreshIndicator(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contract Summary',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _InfoRow(
                                icon: Icons.work_outline_rounded,
                                title: 'Job Title',
                                value: jobTitle,
                                tint: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.payments_outlined,
                                title: 'Agreed Price',
                                value: '$agreedPrice $currency',
                                tint: AppColors.warning,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.schedule_outlined,
                                title: 'Duration',
                                value: '$duration days',
                                tint: AppColors.success,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.flag_outlined,
                                title: 'Status',
                                valueWidget: _StatusChip(status: status),
                                tint: AppColors.info,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Note',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _noteController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'Write a short note about the delivered work...',
                                  filled: true,
                                  fillColor: AppColors.inputFill,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
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
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.45),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload Files',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Upload final deliverables for the client review.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: canSubmit && !_submitting ? _pickFiles : null,
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text(
                                    'Choose Files',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(
                                      color: AppColors.primary.withOpacity(0.25),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_pickedFiles.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.inputBorder),
                                  ),
                                  child: const Text(
                                    'No files selected yet.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: List.generate(_pickedFiles.length, (index) {
                                    final file = _pickedFiles[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index == _pickedFiles.length - 1 ? 0 : 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.inputFill,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.inputBorder),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.10),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.insert_drive_file_outlined,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    file.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                                                    style: const TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _submitting ? null : () => _removeFile(index),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                      sliver: SliverToBoxAdapter(
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Submit Action',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                canSubmit
                                    ? 'When you submit, the contract status will change to submitted and the client will be notified.'
                                    : 'You can submit completed work only when the contract status is active.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: canSubmit && !_submitting
                                        ? AppColors.primaryGradient
                                        : null,
                                    color: canSubmit && !_submitting
                                        ? null
                                        : AppColors.textLight.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: canSubmit && !_submitting
                                        ? () => _submitWork(contractData)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor: Colors.transparent,
                                      disabledForegroundColor: AppColors.textSecondary,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _submitting
                                        ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                        : Text(
                                      'Submit Completed Work',
                                      style: TextStyle(
                                        color: canSubmit && !_submitting
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? valueWidget;
  final Color tint;

  const _InfoRow({
    required this.icon,
    required this.title,
    this.value,
    this.valueWidget,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                title,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    Color bg;
    Color fg;
    String label;

    if (s == 'draft') {
      bg = AppColors.textLight.withOpacity(0.18);
      fg = AppColors.textSecondary;
      label = 'Draft';
    } else if (s == 'active') {
      bg = AppColors.success.withOpacity(0.12);
      fg = AppColors.success;
      label = 'Active';
    } else if (s == 'submitted') {
      bg = AppColors.info.withOpacity(0.12);
      fg = AppColors.info;
      label = 'Submitted';
    } else if (s == 'completed') {
      bg = AppColors.primary.withOpacity(0.12);
      fg = AppColors.primary;
      label = 'Completed';
    } else if (s == 'cancelled') {
      bg = AppColors.error.withOpacity(0.12);
      fg = AppColors.error;
      label = 'Cancelled';
    } else if (s == 'disputed') {
      bg = AppColors.warning.withOpacity(0.12);
      fg = AppColors.warning;
      label = 'Disputed';
    } else {
      bg = AppColors.textLight.withOpacity(0.18);
      fg = AppColors.textSecondary;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        _GlassCard(
          child: SizedBox(height: 130, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 150, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 190, child: _SoftLoadingBox()),
        ),
        SizedBox(height: 12),
        _GlassCard(
          child: SizedBox(height: 120, child: _SoftLoadingBox()),
        ),
      ],
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

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

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
              Icons.search_off_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Contract not found.',
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

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.onRetry,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load submit work screen.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () => onRetry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(120, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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