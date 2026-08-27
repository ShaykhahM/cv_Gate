import 'package:flutter/material.dart';
import '../core/styles/colors.dart';


class AppComponents {
  AppComponents._();

  static void showAppSnack(
      BuildContext context, {
        required String title,
        required String message,
        SnackType type = SnackType.info,
        Duration duration = const Duration(seconds: 3),
      }) {
    final bg = _snackBg(type);
    final icon = _snackIcon(type);

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: _SnackCard(
          bg: bg,
          icon: icon,
          title: title,
          message: message,
        ),
      ),
    );
  }

  static Color _snackBg(SnackType type) {
    switch (type) {
      case SnackType.success:
        return const Color(0xFF0B2B1C);
      case SnackType.error:
        return const Color(0xFF2B0B0B);
      case SnackType.warning:
        return const Color(0xFF2B200B);
      case SnackType.info:
      default:
        return const Color(0xFF0B172B);
    }
  }

  static IconData _snackIcon(SnackType type) {
    switch (type) {
      case SnackType.success:
        return Icons.check_circle_rounded;
      case SnackType.error:
        return Icons.error_rounded;
      case SnackType.warning:
        return Icons.warning_rounded;
      case SnackType.info:
      default:
        return Icons.info_rounded;
    }
  }
}

enum SnackType { success, error, warning, info }

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final bool fullWidth;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.height = 52,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
    )
        : Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .2),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.25),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: child,
        ),
      ),
    );
  }
}
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final bool fullWidth;

  const AppSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.height = 58,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {

    const secondaryGradient = LinearGradient(
      colors: [Color(0xFF0A2A43), Color(0xFF0C4A6E)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );

    final child = loading
        ? const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
    )
        : Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .5, color: Colors.white),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: secondaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A2A43).withOpacity(.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: child,
        ),
      ),
    );
  }
}
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(.55), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error.withOpacity(.9)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error.withOpacity(.9), width: 1.6),
        ),
      ),
    );
  }
}

class _SnackCard extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final String title;
  final String message;

  const _SnackCard({
    required this.bg,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg.withOpacity(.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.28),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(.08)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(color: Colors.white.withOpacity(.78), fontSize: 12.8, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void NextWidget({
  required context,
  required Widget screen,
})
{
  Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (context)=>screen),
          (route) => false);
}

void GoToScreen({
  required context,
  required Widget screen,
})
{
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context)=>screen),
  );
}
