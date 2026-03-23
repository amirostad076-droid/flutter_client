import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/ui/tappable/fluxer_tappable.dart';

class FluxerTab {
  const FluxerTab({required this.label, this.icon});
  final String label;
  final IconData? icon;
}

class FluxerTabs extends StatelessWidget {
  const FluxerTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<FluxerTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++)
          _FluxerTabItem(
            tab: tabs[i],
            isSelected: i == selectedIndex,
            onTap: () => onChanged(i),
          ),
      ],
    );
  }
}

class _FluxerTabItem extends StatelessWidget {
  const _FluxerTabItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final FluxerTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final motion = context.motion;

    return FluxerTappable(
      onTap: onTap,
      builder: (context, states) {
        return AnimatedContainer(
          duration: motion.normal,
          curve: motion.curve,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? colors.brandPrimaryLight
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: layout.s2,
            vertical: layout.s1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.icon != null) ...[
                Icon(
                  tab.icon,
                  size: 16,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
                SizedBox(width: layout.s1),
              ],
              AnimatedDefaultTextStyle(
                duration: motion.normal,
                curve: motion.curve,
                style: textStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
                child: Text(tab.label),
              ),
            ],
          ),
        );
      },
    );
  }
}
