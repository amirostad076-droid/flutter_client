import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';

class SettingsSidebar extends StatelessWidget {
  final List<SettingsSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onClose;

  const SettingsSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 218,
    color: FluxerColors.backgroundSecondary,
    child: Column(
      children: [
        const SizedBox(height: 60),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              if (item.isSeparator) {
                return _buildSeparator(item);
              }

              return _buildItem(item, isSelected, () => onSelected(index));
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildSeparator(SettingsSidebarItem item) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: FluxerColors.divider, height: 1),
        if (item.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(item.label, style: FluxerTextStyles.categoryName),
          ),
      ],
    ),
  );

  Widget _buildItem(
    SettingsSidebarItem item,
    bool isSelected,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? FluxerColors.backgroundModifierSelected
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.label,
            style: TextStyle(
              color: isSelected
                  ? FluxerColors.channelActive
                  : FluxerColors.interactiveNormal,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    ),
  );
}

class SettingsSidebarItem {
  final String label;
  final bool isSeparator;

  const SettingsSidebarItem(this.label, {this.isSeparator = false});

  const SettingsSidebarItem.separator([this.label = '']) : isSeparator = true;
}
