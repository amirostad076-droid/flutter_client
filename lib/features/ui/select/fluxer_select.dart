import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/popout/fluxer_popout.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// An item in a [FluxerSelect] dropdown.
class FluxerSelectItem<T> {
  const FluxerSelectItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A dropdown select using [FluxerPopout] with an input-styled trigger.
///
/// Displays a trigger that visually matches the input field style, and opens a
/// popout dropdown with selectable items.
class FluxerSelect<T> extends StatelessWidget {
  const FluxerSelect({
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.enabled = true,
    super.key,
  });

  final List<FluxerSelectItem<T>> items;
  final ValueChanged<T> onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    final selectedItem = value != null
        ? items.cast<FluxerSelectItem<T>?>().firstWhere(
            (item) => item!.value == value,
            orElse: () => null,
          )
        : null;

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
        FluxerPopout(
          anchorBuilder: (context, toggle) => FluxerTappable(
            enabled: enabled,
            onTap: toggle,
            semanticLabel: label ?? hint ?? 'Select',
            builder: (context, states) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: layout.radiusLg,
                border: Border.all(color: colors.backgroundModifierAccent),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedItem?.label ?? hint ?? '',
                      style: selectedItem != null
                          ? textStyles.bodySmall.copyWith(
                              color: colors.textPrimary,
                            )
                          : textStyles.bodySmall.copyWith(
                              color: colors.textTertiary,
                            ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: layout.s2),
                  Icon(
                    PhosphorIconsBold.caretDown,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          contentBuilder: (context, close) => ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: layout.s1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  final isSelected = item.value == value;
                  return FluxerTappable(
                    onTap: () {
                      onChanged(item.value);
                      close();
                    },
                    semanticLabel: item.label,
                    builder: (context, states) {
                      final isHovered = states.contains(WidgetState.hovered);
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.s3,
                          vertical: layout.s2,
                        ),
                        color: isHovered
                            ? colors.backgroundModifierHover
                            : Colors.transparent,
                        child: Row(
                          children: [
                            if (item.icon != null) ...[
                              Icon(
                                item.icon,
                                size: 18,
                                color: isSelected
                                    ? colors.brandPrimary
                                    : colors.textSecondary,
                              ),
                              SizedBox(width: layout.s2),
                            ],
                            Expanded(
                              child: Text(
                                item.label,
                                style: textStyles.bodySmall.copyWith(
                                  color: isSelected
                                      ? colors.brandPrimary
                                      : colors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                PhosphorIconsBold.check,
                                size: 16,
                                color: colors.brandPrimary,
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
