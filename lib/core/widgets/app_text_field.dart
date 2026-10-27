import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

/// Labelled text input with consistent spacing and validation styling.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscure = false,
    this.maxLines = 1,
    this.enabled = true,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscure;
  final int maxLines;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          enabled: widget.enabled,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
