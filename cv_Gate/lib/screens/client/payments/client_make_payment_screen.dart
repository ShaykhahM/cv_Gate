import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_gate/shared/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientMakePaymentScreen extends StatefulWidget {
  final String contractId;
  final String jobId;
  final String freelancerId;
  final double amount;
  final String currency;

  const ClientMakePaymentScreen({
    super.key,
    required this.contractId,
    required this.jobId,
    required this.freelancerId,
    required this.amount,
    required this.currency,
  });

  @override
  State<ClientMakePaymentScreen> createState() => _ClientMakePaymentScreenState();
}

class _ClientMakePaymentScreenState extends State<ClientMakePaymentScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  String _method = 'card_sim';
  bool _processing = false;

  @override
  void dispose() {
    _holderController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    if (_processing) return;

    if (_method == 'card_sim') {
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final now = Timestamp.now();
      final paymentRef = _db.collection('payments').doc();

      await paymentRef.set({
        'paymentId': paymentRef.id,
        'contractId': widget.contractId,
        'jobId': widget.jobId,
        'clientId': '',
        'freelancerId': widget.freelancerId,
        'amount': widget.amount,
        'currency': widget.currency,
        'method': _method,
        'status': 'initiated',
        'receiptRef': 'RCT-${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': now,
      });

      await _db.collection('payments').doc(paymentRef.id).update({
        'status': 'pending',
      });

      await Future.delayed(const Duration(milliseconds: 900));

      await _db.collection('payments').doc(paymentRef.id).update({
        'status': 'success',
      });

      await _db.collection('contracts').doc(widget.contractId).update({
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      });

      final freelancerNotifRef = _db.collection('notifications').doc();
      final clientNotifRef = _db.collection('notifications').doc();

      final batch = _db.batch();

      batch.set(freelancerNotifRef, {
        'notifId': freelancerNotifRef.id,
        'recipientId': widget.freelancerId,
        'type': 'payment_success',
        'title': 'Payment Successful',
        'body': 'The client completed the payment for the contract.',
        'refType': 'payment',
        'refId': paymentRef.id,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      batch.set(clientNotifRef, {
        'notifId': clientNotifRef.id,
        'recipientId': '',
        'type': 'payment_success',
        'title': 'Payment Successful',
        'body': 'Your payment was completed successfully.',
        'refType': 'payment',
        'refId': paymentRef.id,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment completed successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      final failNotifRef = _db.collection('notifications').doc();

      await failNotifRef.set({
        'notifId': failNotifRef.id,
        'recipientId': '',
        'type': 'payment_failed',
        'title': 'Payment Failed',
        'body': 'The payment could not be completed.',
        'refType': 'contract',
        'refId': widget.contractId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment failed'),
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

  bool get _showCardFields => _method == 'card_sim';

  @override
  Widget build(BuildContext context) {
    final amountText = widget.amount == widget.amount.roundToDouble()
        ? '${widget.amount.toInt()} ${widget.currency}'
        : '${widget.amount.toStringAsFixed(2)} ${widget.currency}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Make Payment',
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
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contract Summary',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Amount', value: amountText),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'Currency', value: widget.currency),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MethodTile(
                      title: 'Card',
                      value: 'card_sim',
                      currentValue: _method,
                      onTap: () => setState(() => _method = 'card_sim'),
                    ),
                    const SizedBox(height: 10),
                    _MethodTile(
                      title: 'STC Pay',
                      value: 'stc_sim',
                      currentValue: _method,
                      onTap: () => setState(() => _method = 'stc_sim'),
                    ),
                    const SizedBox(height: 10),
                    _MethodTile(
                      title: 'Bank Transfer',
                      value: 'bank_sim',
                      currentValue: _method,
                      onTap: () => setState(() => _method = 'bank_sim'),
                    ),
                  ],
                ),
              ),
              if (_showCardFields) ...[
                const SizedBox(height: 14),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card Information',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel(label: 'Card Holder Name'),
                      const SizedBox(height: 8),
                      _AppTextField(
                        controller: _holderController,
                        hint: 'Enter card holder name',
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter card holder name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const _FieldLabel(label: 'Card Number'),
                      const SizedBox(height: 8),
                      _AppTextField(
                        controller: _cardController,
                        hint: '1234 5678 9012 3456',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                          _CardNumberFormatter(),
                        ],
                        validator: (value) {
                          final digits = (value ?? '').replaceAll(' ', '');
                          if (digits.length != 16) {
                            return 'Card number must be 16 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel(label: 'Expiry Date'),
                                const SizedBox(height: 8),
                                _AppTextField(
                                  controller: _expiryController,
                                  hint: 'MM/YY',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryDateFormatter(),
                                  ],
                                  validator: (value) {
                                    if ((value ?? '').trim().length != 5) {
                                      return 'Invalid date';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel(label: 'CVV'),
                                const SizedBox(height: 8),
                                _AppTextField(
                                  controller: _cvvController,
                                  hint: '123',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  validator: (value) {
                                    if ((value ?? '').trim().length != 3) {
                                      return 'Invalid CVV';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _processing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.payments_outlined),
                  label: Text(
                    _processing ? 'Processing...' : 'Confirm Payment',
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
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String value;
  final String currentValue;
  final VoidCallback onTap;

  const _MethodTile({
    required this.title,
    required this.value,
    required this.currentValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == currentValue;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.06) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
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
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
          width: 90,
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

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final isFourth = (i + 1) % 4 == 0;
      if (isFourth && i + 1 != digits.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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