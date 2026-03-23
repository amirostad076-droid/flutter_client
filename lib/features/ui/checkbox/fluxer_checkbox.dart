import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';

/// A themed checkbox with an optional tappable label.
///
/// Visual styling is handled by the existing [CheckboxTheme]
/// in `buildFluxerTheme()`.
class FluxerCheckbox extends StatelessWidget {
  const FluxerCheckbox({
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: enabled ? onChanged : null),
        if (label != null)
          GestureDetector(
            onTap: enabled ? () => onChanged(!value) : null,
            child: Text(
              label!,
              style: textStyles.bodyMedium.copyWith(
                color: enabled ? colors.textPrimary : colors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
