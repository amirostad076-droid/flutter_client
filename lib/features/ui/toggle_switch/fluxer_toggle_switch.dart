import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';

/// A themed toggle switch with an optional tappable label on the left.
///
/// Visual styling is handled by the existing [SwitchTheme]
/// in `buildFluxerTheme()`.
class FluxerToggleSwitch extends StatelessWidget {
  const FluxerToggleSwitch({
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onChanged(!value) : null,
              child: Text(
                label!,
                style: textStyles.bodyMedium.copyWith(
                  color: enabled ? colors.textPrimary : colors.textTertiary,
                ),
              ),
            ),
          ),
        Switch(value: value, onChanged: enabled ? onChanged : null),
      ],
    );
  }
}
