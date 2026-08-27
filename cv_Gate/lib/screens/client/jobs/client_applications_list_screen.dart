import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ClientApplicationsListScreen extends StatefulWidget {
  final String jobId;

  const ClientApplicationsListScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ClientApplicationsListScreen> createState() => _ClientApplicationsListScreenState();
}

class _ClientApplicationsListScreenState extends State<ClientApplicationsListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final Map<String, Map<String, dynamic>> _userCache = {};
  bool _processing = false;

  Future<Map<String, dynamic>> _loadUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    try {
      final userSnap = await _db.collection('users').doc(uid).get();
      final profileSnap = await _db.collection('users').doc(uid).collection('profile').doc('main').get();

      final userData = userSnap.data() ?? {};
      final profileData = profileSnap.data() ?? {};

      final merged = {
        'fullName': (userData['fullName'] ?? '').toString(),
        'photoUrl': (userData['photoUrl'] ?? '').toString(),
        'city': (userData['city'] ?? '').toString(),
        'ratingAvg': userData['ratingAvg'],
        'ratingCount': userData['ratingCount'],
        'title': (profileData['title'] ?? '').toString(),
        'bio': (profileData['bio'] ?? '').toString(),
      };

      _userCache[uid] = merged;
      return merged;
    } catch (_) {
      return {};
    }
  }

  Future<void> _openProfilePreview(String freelancerId) async {
    final userData = await _loadUser(freelancerId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final fullName = (userData['fullName'] ?? 'Freelancer').toString().trim();
        final title = (userData['title'] ?? '').toString().trim();
        final city = (userData['city'] ?? '').toString().trim();
        final bio = (userData['bio'] ?? '').toString().trim();
        final ratingAvg = _toDouble(userData['ratingAvg']);
        final ratingCount = _toInt(userData['ratingCount']);

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlassCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.10),
                          child: Text(
                            _initials(fullName),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName.isEmpty ? 'Freelancer' : fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        if (title.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _InfoRow(label: 'City', value: city.isEmpty ? 'Not specified' : city),
                        const SizedBox(height: 10),
                        _InfoRow(
                          label: 'Rating',
                          value: ratingCount > 0 ? '${ratingAvg.toStringAsFixed(1)} ($ratingCount reviews)' : 'No ratings',
                        ),
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(label: 'Bio', value: bio),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _rejectSingleApplication({
    required String applicationId,
    required String freelancerId,
  }) async {
    if (_processing) return;

    final confirmed = await _confirmDialog(
      title: 'Reject Application',
      message: 'Are you sure you want to reject this application?',
      confirmText: 'Reject',
      confirmColor: AppColors.error,
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      final now = Timestamp.now();
      final batch = _db.batch();

      batch.update(_db.collection('applications').doc(applicationId), {
        'status': 'rejected',
      });

      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'notifId': notifRef.id,
        'recipientId': freelancerId,
        'type': 'application_rejected',
        'title': 'Application Rejected',
        'body': 'Your application for this job has been rejected by the client.',
        'refType': 'job',
        'refId': widget.jobId,
        'isRead': false,
        'createdAt': now,
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Application rejected successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to reject application'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<Map<String, dynamic>> _loadTemplate() async {
    final snap = await _db.collection('template').limit(1).get();
    if (snap.docs.isEmpty) {
      return {
        'title': 'Contract Template',
        'content': 'This contract is made between the client and the freelancer.',
      };
    }
    return snap.docs.first.data();
  }

  String _buildContractContent({
    required String rawTemplate,
    required String clientName,
    required String freelancerName,
    required String jobTitle,
    required String jobDescription,
    required String agreedPrice,
    required String currency,
    required String agreedDuration,
  }) {
    var content = rawTemplate;

    content = content.replaceAll('[Write project scope here]', '$jobTitle\n$jobDescription');
    content = content.replaceAll('[Write timeline here]', '$agreedDuration days');
    content = content.replaceAll('[Write payment terms here]', '$agreedPrice $currency');
    content = content.replaceAll('[Write deliverables here]', 'Deliverables will be submitted by the freelancer based on the agreed job scope.');
    content = content.replaceAll('[Write additional notes here]', 'Client: $clientName\nFreelancer: $freelancerName');

    return content;
  }

  Future<Uint8List> _generateContractPdfBytes({
    required String contractTitle,
    required String templateTitle,
    required String contractBody,
    required String clientName,
    required String freelancerName,
    required String jobTitle,
    required String agreedPrice,
    required String currency,
    required String agreedDuration,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColor.fromInt(0xFF0A2A43), PdfColor.fromInt(0xFF0C4A6E)],
              ),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  contractTitle,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  templateTitle,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF7FAFC),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfInfoRow('Client', clientName),
                _pdfInfoRow('Freelancer', freelancerName),
                _pdfInfoRow('Job Title', jobTitle),
                _pdfInfoRow('Agreed Price', '$agreedPrice $currency'),
                _pdfInfoRow('Duration', '$agreedDuration days'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Contract Content',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 15,
              color: PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            contractBody,
            style: pw.TextStyle(
              fontSize: 12,
              lineSpacing: 4,
              color: PdfColor.fromInt(0xFF334155),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.only(top: 18),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Client Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 22),
                      pw.Container(height: 1, color: PdfColor.fromInt(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.only(top: 18),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Freelancer Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 22),
                      pw.Container(height: 1, color: PdfColor.fromInt(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<String> _uploadContractPdf({
    required String contractId,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref().child('contracts/$contractId.pdf');
    final task = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'application/pdf',
      ),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _showContractCreatedDialog({
    required String freelancerName,
    required String jobTitle,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.60), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contract Created Successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'The contract for "$jobTitle" has been generated and activated successfully with $freelancerName.\n\nYou can now track this project from the Contracts screen and continue the hiring flow from there.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptApplication({
    required String applicationId,
    required String freelancerId,
  }) async {
    if (_processing) return;

    final confirmed = await _confirmDialog(
      title: 'Accept Application',
      message: 'Are you sure you want to accept this application? The system will reject the other applications, generate the contract PDF, activate the contract, and move this job to the contracted status.',
      confirmText: 'Accept',
      confirmColor: AppColors.success,
    );

    if (!confirmed) return;

    setState(() {
      _processing = true;
    });

    try {
      final now = Timestamp.now();

      final jobSnap = await _db.collection('jobs').doc(widget.jobId).get();
      if (!jobSnap.exists) {
        throw Exception();
      }

      final jobData = jobSnap.data() ?? {};
      final clientId = (jobData['clientId'] ?? '').toString().trim();
      final jobTitle = (jobData['title'] ?? '').toString().trim();
      final jobDescription = (jobData['description'] ?? '').toString().trim();
      final currency = (jobData['currency'] ?? 'SAR').toString().trim();

      final acceptedAppSnap = await _db.collection('applications').doc(applicationId).get();
      if (!acceptedAppSnap.exists) {
        throw Exception();
      }

      final acceptedAppData = acceptedAppSnap.data() ?? {};
      final proposedPrice = (acceptedAppData['proposedPrice'] ?? '').toString().trim();
      final proposedDuration = (acceptedAppData['proposedDurationDays'] ?? '').toString().trim();

      final clientUserSnap = await _db.collection('users').doc(clientId).get();
      final freelancerUserSnap = await _db.collection('users').doc(freelancerId).get();

      final clientName = ((clientUserSnap.data() ?? {})['fullName'] ?? 'Client').toString().trim();
      final freelancerName = ((freelancerUserSnap.data() ?? {})['fullName'] ?? 'Freelancer').toString().trim();

      final templateData = await _loadTemplate();
      final templateTitle = (templateData['title'] ?? 'Standard Contract Template').toString().trim();
      final templateContent = (templateData['content'] ?? '').toString();

      final contractId = _db.collection('contracts').doc().id;

      final contractBody = _buildContractContent(
        rawTemplate: templateContent,
        clientName: clientName.isEmpty ? 'Client' : clientName,
        freelancerName: freelancerName.isEmpty ? 'Freelancer' : freelancerName,
        jobTitle: jobTitle.isEmpty ? 'Project' : jobTitle,
        jobDescription: jobDescription.isEmpty ? 'No project description provided.' : jobDescription,
        agreedPrice: proposedPrice.isEmpty ? '0' : proposedPrice,
        currency: currency.isEmpty ? 'SAR' : currency,
        agreedDuration: proposedDuration.isEmpty ? '0' : proposedDuration,
      );

      final pdfBytes = await _generateContractPdfBytes(
        contractTitle: 'CVGATE Service Contract',
        templateTitle: templateTitle.isEmpty ? 'Standard Contract Template' : templateTitle,
        contractBody: contractBody,
        clientName: clientName.isEmpty ? 'Client' : clientName,
        freelancerName: freelancerName.isEmpty ? 'Freelancer' : freelancerName,
        jobTitle: jobTitle.isEmpty ? 'Project' : jobTitle,
        agreedPrice: proposedPrice.isEmpty ? '0' : proposedPrice,
        currency: currency.isEmpty ? 'SAR' : currency,
        agreedDuration: proposedDuration.isEmpty ? '0' : proposedDuration,
      );

      final pdfUrl = await _uploadContractPdf(
        contractId: contractId,
        bytes: pdfBytes,
      );

      final applicationsSnap = await _db
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .get();

      final batch = _db.batch();

      for (final doc in applicationsSnap.docs) {
        final data = doc.data();
        final currentFreelancerId = (data['freelancerId'] ?? '').toString().trim();
        final currentAppId = doc.id;
        final isAcceptedOne = currentAppId == applicationId;

        batch.update(_db.collection('applications').doc(currentAppId), {
          'status': isAcceptedOne ? 'accepted' : 'rejected',
        });

        if (currentFreelancerId.isNotEmpty) {
          final notifRef = _db.collection('notifications').doc();
          batch.set(notifRef, {
            'notifId': notifRef.id,
            'recipientId': currentFreelancerId,
            'type': isAcceptedOne ? 'application_accepted' : 'application_rejected',
            'title': isAcceptedOne ? 'Application Accepted' : 'Application Rejected',
            'body': isAcceptedOne
                ? 'Your application has been accepted and the contract has been generated by the client.'
                : 'Another freelancer was selected for this job.',
            'refType': isAcceptedOne ? 'contract' : 'job',
            'refId': isAcceptedOne ? contractId : widget.jobId,
            'isRead': false,
            'createdAt': now,
          });
        }
      }

      batch.set(_db.collection('contracts').doc(contractId), {
        'contractId': contractId,
        'jobId': widget.jobId,
        'clientId': clientId,
        'freelancerId': freelancerId,
        'agreedPrice': proposedPrice.isEmpty ? 0 : num.tryParse(proposedPrice) ?? proposedPrice,
        'currency': currency.isEmpty ? 'SAR' : currency,
        'agreedDurationDays': proposedDuration.isEmpty ? 0 : int.tryParse(proposedDuration) ?? proposedDuration,
        'pdfUrl': pdfUrl,
        'acceptedAt': now,
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      });

      batch.update(_db.collection('jobs').doc(widget.jobId), {
        'status': 'contracted',
        'updatedAt': now,
      });

      await batch.commit();

      if (!mounted) return;

      await _showContractCreatedDialog(
        freelancerName: freelancerName.isEmpty ? 'the selected freelancer' : freelancerName,
        jobTitle: jobTitle.isEmpty ? 'this project' : jobTitle,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to accept application and generate contract'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appsStream = _db
        .collection('applications')
        .where('jobId', isEqualTo: widget.jobId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Applications',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: appsStream,
          builder: (context, snap) {
            if (!snap.hasData) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const _GlassCard(
                  child: SizedBox(height: 170, child: _SoftLoadingBox()),
                ),
              );
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: const [
                  _GlassCard(
                    child: _EmptyState(
                      icon: Icons.description_outlined,
                      title: 'No applications yet',
                      subtitle: 'Applications from freelancers will appear here.',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final applicationId = doc.id;
                final freelancerId = (data['freelancerId'] ?? '').toString().trim();
                final message = (data['message'] ?? '').toString().trim();
                final proposedPrice = (data['proposedPrice'] ?? '').toString().trim();
                final proposedDuration = (data['proposedDurationDays'] ?? '').toString().trim();
                final status = (data['status'] ?? 'pending').toString().trim();
                final createdAt = data['createdAt'];

                return FutureBuilder<Map<String, dynamic>>(
                  future: _loadUser(freelancerId),
                  builder: (context, userSnap) {
                    final userData = userSnap.data ?? {};
                    final fullName = (userData['fullName'] ?? 'Freelancer').toString().trim();
                    final title = (userData['title'] ?? '').toString().trim();
                    final city = (userData['city'] ?? '').toString().trim();
                    final ratingAvg = _toDouble(userData['ratingAvg']);
                    final ratingCount = _toInt(userData['ratingCount']);

                    return _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(0.10),
                                child: Text(
                                  _initials(fullName),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName.isEmpty ? 'Freelancer' : fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      title.isEmpty ? 'No title' : title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _StatusChip(status: status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _InfoRow(
                            label: 'City',
                            value: city.isEmpty ? 'Not specified' : city,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Rating',
                            value: ratingCount > 0 ? '${ratingAvg.toStringAsFixed(1)} ($ratingCount)' : 'No ratings',
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Proposed Price',
                            value: proposedPrice.isEmpty ? 'Not specified' : proposedPrice,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Proposed Duration',
                            value: proposedDuration.isEmpty ? 'Not specified' : '$proposedDuration days',
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Applied Date',
                            value: _dateLabel(createdAt),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Proposal Message',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message.isEmpty ? 'No message provided.' : message,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.8,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openProfilePreview(freelancerId),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_outline_rounded),
                                  label: const Text(
                                    'Open Profile',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: status == 'pending' && !_processing
                                      ? () => _acceptApplication(
                                    applicationId: applicationId,
                                    freelancerId: freelancerId,
                                  )
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.success.withOpacity(0.45),
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline_rounded),
                                  label: const Text(
                                    'Accept',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: status == 'pending' && !_processing
                                      ? () => _rejectSingleApplication(
                                    applicationId: applicationId,
                                    freelancerId: freelancerId,
                                  )
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.error.withOpacity(0.45),
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text(
                                    'Reject',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

pw.Widget _pdfInfoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 92,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF475569),
              fontSize: 11,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFF0F172A),
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
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
          width: 122,
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();

    late final Color bg;
    late final Color fg;

    if (s == 'pending') {
      bg = AppColors.warning.withOpacity(0.14);
      fg = AppColors.warning;
    } else if (s == 'accepted') {
      bg = AppColors.success.withOpacity(0.14);
      fg = AppColors.success;
    } else if (s == 'rejected') {
      bg = AppColors.error.withOpacity(0.14);
      fg = AppColors.error;
    } else if (s == 'withdrawn') {
      bg = AppColors.textSecondary.withOpacity(0.14);
      fg = AppColors.textSecondary;
    } else {
      bg = AppColors.textSecondary.withOpacity(0.14);
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s.toUpperCase(),
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
      child: Container(color: Colors.black.withOpacity(0.03)),
    );
  }
}

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'F';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _dateLabel(dynamic value) {
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }
  return 'Recently';
}

String _two(int v) => v < 10 ? '0$v' : '$v';