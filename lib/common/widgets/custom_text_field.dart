import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isObscure;
  final VoidCallback? onTogglePassword;
  final TextInputType inputType;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isObscure = false,
    this.onTogglePassword,
    this.inputType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colorScheme),
        _buildTextField(colorScheme),
      ],
    );
  }

  Widget _buildLabel(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTextField(ColorScheme colorScheme) {
    Widget? suffixIcon;
    if (isPassword) {
      IconData visibilityIcon;
      if (isObscure) {
        visibilityIcon = Icons.visibility_outlined;
      } else {
        visibilityIcon = Icons.visibility_off_outlined;
      }

      suffixIcon = IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        icon: Icon(visibilityIcon, color: colorScheme.onSurfaceVariant),
        onPressed: onTogglePassword,
      );
    }

    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: inputType,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 20, right: 12),
          child: Icon(icon, color: colorScheme.primary),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
