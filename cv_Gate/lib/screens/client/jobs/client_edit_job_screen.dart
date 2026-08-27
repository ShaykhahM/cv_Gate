import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:flutter/material.dart';

class ClientEditJobScreen extends StatefulWidget {
  final String jobId;

  const ClientEditJobScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ClientEditJobScreen> createState() => _ClientEditJobScreenState();
}

class _ClientEditJobScreenState extends State<ClientEditJobScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String _currency = 'SAR';
  bool _loading = true;
  bool _saving = false;
  String _status = '';

  final List<String> _currencies = ['SAR', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _skillsController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    try {
      final snap = await _db.collection('jobs').doc(widget.jobId).get();
      final data = snap.data() ?? {};

      final skills = (data['skillsRequired'] is List)
          ? List<String>.from(data['skillsRequired'])
          : <String>[];

      _titleController.text = (data['title'] ?? '').toString();
      _descriptionController.text = (data['description'] ?? '').toString();
      _categoryController.text = (data['category'] ?? '').toString();
      _skillsController.text = skills.join(', ');
      _budgetController.text = (data['budget'] ?? '').toString();
      _durationController.text = (data['durationDays'] ?? '').toString();
      _currency = (data['currency'] ?? 'SAR').toString();
      _status = (data['status'] ?? '').toString();

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

  bool get _canEdit => _status != 'contracted' && _status != 'cancelled';

  Future<void> _save() async {
    if (_saving || !_canEdit) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0;
    final durationDays = int.tryParse(_durationController.text.trim()) ?? 0;
    final skillsRequired = _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _saving = true;
    });

    try {
      await _db.collection('jobs').doc(widget.jobId).update({
        'title': title,
        'description': description,
        'category': category,
        'skillsRequired': skillsRequired,
        'budget': budget,
        'currency': _currency,
        'durationDays': durationDays,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update job'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
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
            'Edit Job',
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
        child: _loading
            ? ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: const [
            _GlassCard(
              child: SizedBox(height: 120, child: _SoftLoadingBox()),
            ),
            SizedBox(height: 14),
            _GlassCard(
              child: SizedBox(height: 420, child: _SoftLoadingBox()),
            ),
          ],
        )
            : !_canEdit
            ? ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: const [
            _GlassCard(
              child: _SimpleMessageCard(
                title: 'Job cannot be edited',
                subtitle: 'This job is no longer manageable because it is contracted or cancelled.',
                icon: Icons.lock_outline_rounded,
              ),
            ),
          ],
        )
            : Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Job Details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current status: ${_status.isEmpty ? 'Unknown' : _status.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _GlassCard(
                child: Column(
                  children: [
                    const _FieldLabel(label: 'Job Title'),
                    const SizedBox(height: 8),
                    _AppTextField(
                      controller: _titleController,
                      hint: 'Enter job title',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter the job title';
                        }
                        if ((value ?? '').trim().length < 4) {
                          return 'Title is too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Description'),
                    const SizedBox(height: 8),
                    _AppTextField(
                      controller: _descriptionController,
                      hint: 'Enter full job description',
                      maxLines: 5,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter the description';
                        }
                        if ((value ?? '').trim().length < 10) {
                          return 'Description is too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Category'),
                    const SizedBox(height: 8),
                    _AppTextField(
                      controller: _categoryController,
                      hint: 'Enter category',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter the category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Skills Required'),
                    const SizedBox(height: 8),
                    _AppTextField(
                      controller: _skillsController,
                      hint: 'Example: Flutter, Firebase, UI Design',
                      maxLines: 3,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter at least one skill';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'Budget'),
                              const SizedBox(height: 8),
                              _AppTextField(
                                controller: _budgetController,
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final parsed = double.tryParse(value!.trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Invalid budget';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'Currency'),
                              const SizedBox(height: 8),
                              _CurrencyDropdown(
                                value: _currency,
                                items: _currencies,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _currency = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Duration Days'),
                    const SizedBox(height: 8),
                    _AppTextField(
                      controller: _durationController,
                      hint: 'Enter duration in days',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter duration';
                        }
                        final parsed = int.tryParse(value!.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid duration';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

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
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CurrencyDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SimpleMessageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SimpleMessageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 34, color: AppColors.textSecondary),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
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
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

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
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.2),
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
      child: Container(color: Colors.black.withOpacity(0.03)),
    );
  }
}