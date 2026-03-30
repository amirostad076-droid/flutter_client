import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

class FluxerRadioItem<T> {
  const FluxerRadioItem({
    required this.value,
    required this.label,
    this.description,
  });

  final T value;
  final String label;
  final String? description;
}

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
    final layout = context.layout;

    return Flex(
      direction: direction,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: layout.s1_5,
      children: [for (final item in items) _buildOption(context, item)],
    );
  }

  Widget _buildOption(BuildContext context, FluxerRadioItem<T> item) {
    final isSelected = value == item.value;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(item.value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _RadioIndicator(isSelected: isSelected),
          ),
          const SizedBox(width: 8),
          if (direction == Axis.vertical)
            Expanded(child: _buildLabel(context, item, isSelected))
          else
            _buildLabel(context, item, isSelected),
        ],
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context,
    FluxerRadioItem<T> item,
    bool isSelected,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: layout.s1,
      children: [
        Text(
          item.label,
          style: textStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: isSelected ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        if (item.description != null)
          Text(
            item.description!,
            style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
      ],
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderDerived = Color.lerp(colors.borderColor, Colors.white, 0.3)!;
    final unselectedFill = Color.lerp(
      colors.backgroundPrimary,
      borderDerived,
      0.45,
    )!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? colors.brandPrimary : unselectedFill,
        border: Border.all(
          color: isSelected ? colors.brandPrimary : borderDerived,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
