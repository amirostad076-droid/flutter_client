import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// An item in a [FluxerSelect] dropdown.
class FluxerSelectItem<T> {
  const FluxerSelectItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A dropdown select that uses a filled input-style trigger and opens
/// options in a [FluxerBottomSheet].
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
        FluxerTappable(
          enabled: enabled,
          onTap: () => _showOptions(context),
          semanticLabel: label ?? hint ?? 'Select',
          builder: (context, states) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              borderRadius: layout.radiusLg,
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
      ],
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final result = await FluxerBottomSheet.show<T>(
      context,
      builder: (sheetContext, close) {
        final colors = sheetContext.colors;
        final textStyles = sheetContext.textStyles;
        final layout = sheetContext.layout;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.s4),
            child: FluxerMenuGroup(
              children: [
                for (final item in items)
                  FluxerTappable(
                    onTap: () {
                      Navigator.of(sheetContext).pop(item.value);
                    },
                    semanticLabel: item.label,
                    builder: (context, states) {
                      final isSelected = item.value == value;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: isSelected
                            ? colors.brandPrimary.withValues(alpha: 0.1)
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
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                PhosphorIconsBold.check,
                                size: 20,
                                color: colors.brandPrimary,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      onChanged(result);
    }
  }
}
