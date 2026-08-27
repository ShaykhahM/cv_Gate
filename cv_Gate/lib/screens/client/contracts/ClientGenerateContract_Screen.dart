import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/screens/client/contracts/client_contract_pdf_preview_screen.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:cv_gate/shared/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientGenerateContractScreen extends StatefulWidget {
  final String applicationId;
  final String jobId;
  final String freelancerId;

  const ClientGenerateContractScreen({
    super.key,
    required this.applicationId,
    required this.jobId,
    required this.freelancerId,
  });

  @override
  State<ClientGenerateContractScreen> createState() => _ClientGenerateContractScreenState();
}

class _ClientGenerateContractScreenState extends State<ClientGenerateContractScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _clientId = clientId;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  final TextEditingController _paymentTermsController = TextEditingController();
  final TextEditingController _deliverablesController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic> _jobData = {};
  Map<String, dynamic> _freelancerData = {};
  Map<String, dynamic> _clientData = {};
  Map<String, dynamic> _applicationData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    _scopeController.dispose();
    _paymentTermsController.dispose();
    _deliverablesController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final applicationSnap = await _db.collection('applications').doc(widget.applicationId).get();
      final jobSnap = await _db.collection('jobs').doc(widget.jobId).get();
      final freelancerSnap = await _db.collection('users').doc(widget.freelancerId).get();
      final clientSnap = await _db.collection('users').doc(_clientId).get();

      _applicationData = applicationSnap.data() ?? {};
      _jobData = jobSnap.data() ?? {};
      _freelancerData = freelancerSnap.data() ?? {};
      _clientData = clientSnap.data() ?? {};

      _priceController.text = (_applicationData['proposedPrice'] ?? _jobData['budget'] ?? '').toString();
      _durationController.text = (_applicationData['proposedDurationDays'] ?? _jobData['durationDays'] ?? '').toString();
      _scopeController.text = (_jobData['description'] ?? '').toString();
      _paymentTermsController.text = 'Payment after final approval of submitted work.';
      _deliverablesController.text = 'Complete requested deliverables based on project scope.';
      _additionalNotesController.text = '';

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openPreview() async {
    final validPrice = double.tryParse(_priceController.text.trim());
    final validDuration = int.tryParse(_durationController.text.trim());

    if (validPrice == null || validPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid agreed price'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    if (validDuration == null || validDuration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid agreed duration'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => ClientContractPdfPreviewScreen(
    //       jobId: widget.jobId,
    //       contractId: '',
    //       clientName: (_clientData['fullName'] ?? 'Client').toString(),
    //       freelancerName: (_freelancerData['fullName'] ?? 'Freelancer').toString(),
    //       jobTitle: (_jobData['title'] ?? 'Project').toString(),
    //       projectScope: _scopeController.text.trim(),
    //       timeline: '${validDuration.toString()} days',
    //       paymentTerms: _paymentTermsController.text.trim(),
    //       deliverables: _deliverablesController.text.trim(),
    //       additionalNotes: _additionalNotesController.text.trim(),
    //       agreedPrice: validPrice,
    //       currency: (_jobData['currency'] ?? 'SAR').toString(),
    //       isPreviewOnly: true,
    //     ),
    //   ),
    // );
  }

  Future<void> _generateContract() async {
    if (_saving) return;

    final validPrice = double.tryParse(_priceController.text.trim());
    final validDuration = int.tryParse(_durationController.text.trim());

    if (validPrice == null || validPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid agreed price'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    if (validDuration == null || validDuration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid agreed duration'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final now = Timestamp.now();
      final contractRef = _db.collection('contracts').doc();

      final contractData = {
        'contractId': contractRef.id,
        'jobId': widget.jobId,
        'clientId': _clientId,
        'freelancerId': widget.freelancerId,
        'agreedPrice': validPrice,
        'currency': (_jobData['currency'] ?? 'SAR').toString(),
        'agreedDurationDays': validDuration,
        'pdfUrl': '',
        'acceptedAt': now,
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      };

      final batch = _db.batch();

      batch.set(contractRef, contractData);

      batch.update(_db.collection('jobs').doc(widget.jobId), {
        'status': 'contracted',
        'updatedAt': now,
      });

      batch.set(_db.collection('notifications').doc(), {
        'notifId': _db.collection('notifications').doc().id,
        'recipientId': widget.freelancerId,
        'type': 'contract_activated',
        'title': 'Contract Activated',
        'body': 'A contract has been generated and activated for your accepted application.',
        'refType': 'contract',
        'refId': contractRef.id,
        'isRead': false,
        'createdAt': now,
      });

      await batch.commit();

      if (!mounted) return;

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => ClientContractPdfPreviewScreen(
      //       jobId: widget.jobId,
      //       contractId: contractRef.id,
      //       clientName: (_clientData['fullName'] ?? 'Client').toString(),
      //       freelancerName: (_freelancerData['fullName'] ?? 'Freelancer').toString(),
      //       jobTitle: (_jobData['title'] ?? 'Project').toString(),
      //       projectScope: _scopeController.text.trim(),
      //       timeline: '${validDuration.toString()} days',
      //       paymentTerms: _paymentTermsController.text.trim(),
      //       deliverables: _deliverablesController.text.trim(),
      //       additionalNotes: _additionalNotesController.text.trim(),
      //       agreedPrice: validPrice,
      //       currency: (_jobData['currency'] ?? 'SAR').toString(),
      //       isPreviewOnly: false,
      //     ),
      //   ),
      // );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to generate contract'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final freelancerName = (_freelancerData['fullName'] ?? 'Freelancer').toString();
    final freelancerEmail = (_freelancerData['email'] ?? '').toString();
    final jobTitle = (_jobData['title'] ?? 'Project').toString();
    final jobCategory = (_jobData['category'] ?? '').toString();
    final currency = (_jobData['currency'] ?? 'SAR').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Generate Contract',
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
        child: _loading
            ? ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: const [
            _GlassCard(child: SizedBox(height: 140, child: _SoftLoadingBox())),
            SizedBox(height: 14),
            _GlassCard(child: SizedBox(height: 420, child: _SoftLoadingBox())),
          ],
        )
            : ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accepted Freelancer Info',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Name', value: freelancerName),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Email', value: freelancerEmail.isEmpty ? 'Not available' : freelancerEmail),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Related Job Info',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Job Title', value: jobTitle),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Category', value: jobCategory.isEmpty ? 'Not specified' : jobCategory),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contract Setup',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel(label: 'Agreed Price'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _priceController,
                    hint: 'Enter agreed price',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Currency', value: currency),
                  const SizedBox(height: 12),
                  const _FieldLabel(label: 'Agreed Duration'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _durationController,
                    hint: 'Enter duration in days',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel(label: 'Project Scope'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _scopeController,
                    hint: 'Enter project scope',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel(label: 'Payment Terms'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _paymentTermsController,
                    hint: 'Enter payment terms',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel(label: 'Deliverables'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _deliverablesController,
                    hint: 'Enter deliverables',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel(label: 'Additional Notes'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _additionalNotesController,
                    hint: 'Enter additional notes',
                    maxLines: 3,
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
                    'Contract Template Preview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preview the final contract layout before generating and activating it.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openPreview,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text(
                        'Open Preview',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _generateContract,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.description_outlined),
                label: Text(
                  _saving ? 'Generating...' : 'Generate Contract',
                  style: const TextStyle(
                    fontSize: 15,
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 13,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
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
          width: 110,
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