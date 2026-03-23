import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';

/// A single item within a [FluxerRadioGroup].
class FluxerRadioItem<T> {
  const FluxerRadioItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A themed radio group that renders [Radio] widgets with tappable labels.
///
/// Uses [RadioGroup] as an ancestor to manage selection state, and [Flex]
/// to support both vertical and horizontal layouts via the [direction]
/// parameter. Visual styling is handled by the existing [RadioTheme]
/// in `buildFluxerTheme()`.
class FluxerRadioGroup<T> extends StatelessWidget {
  const FluxerRadioGroup({
    required this.value,
    required this.items,
    required this.onChanged,
    this.direction = Axis.vertical,
    super.key,
  });

  final T value;
  final List<FluxerRadioItem<T>> items;
  final ValueChanged<T> onChanged;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return RadioGroup<T>(
      groupValue: value,
      onChanged: (v) {
        if (v != null) {
          onChanged(v);
        }
      },
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<T>(value: item.value),
                GestureDetector(
                  onTap: () => onChanged(item.value),
                  child: Text(
                    item.label,
                    style: textStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
