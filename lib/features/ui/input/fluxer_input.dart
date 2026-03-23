import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';

/// A styled text input field with an optional label above
/// and theme integration.
///
/// Use [FluxerInput.multiline] for multi-line text areas.
class FluxerInput extends StatelessWidget {
  const FluxerInput({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    super.key,
  });

  const FluxerInput.multiline({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.maxLines,
    this.minLines = 3,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    final Widget? effectiveSuffix = suffixIcon != null && onSuffixTap != null
        ? GestureDetector(onTap: onSuffixTap, child: suffixIcon)
        : suffixIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.only(bottom: layout.s1_5),
            child: Text(
              label!,
              style: textStyles.label.copyWith(color: colors.textSecondary),
            ),
          ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: effectiveSuffix,
            counterText: maxLength != null ? '' : null,
          ),
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
        ),
      ],
    );
  }
}
