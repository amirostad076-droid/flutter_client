import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsSidebar extends StatelessWidget {
  final List<SettingsSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onClose;
  final String? username;
  final String? avatarUrl;
  final int? avatarColor;

  const SettingsSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.onClose,
    this.username,
    this.avatarUrl,
    this.avatarColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 400,
    color: FluxerColors.backgroundPrimary,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: TextField(
            style: const TextStyle(
              color: FluxerColors.textNormal,
              fontSize: 14,

            ),
            decoration: InputDecoration(
              hintText: 'Search settings...',
              hintStyle: const TextStyle(
                color: FluxerColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 8, right: 4),
                child: PhosphorIcon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: FluxerColors.textMuted,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 20,
              ),
              filled: true,
              fillColor: FluxerColors.backgroundTertiary,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: FluxerColors.divider,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: FluxerColors.divider,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: FluxerColors.divider,
                ),
              ),
            ),
          ),
        ),
        if (username != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 16, 24), 
            child: Row(
              children: [
                UserAvatar(
                  displayName: username!,
                  avatarUrl: avatarUrl,
                  avatarColor: avatarColor,
                  size: 32,
                  showStatus: false,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    username!,
                    style: const TextStyle(
                      color: FluxerColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Fluxeron',
            style: TextStyle(
              color: FluxerColors.textFaintest,
              fontSize: 11,
            ),
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
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(item.label, style: FluxerTextStyles.categoryName),
          ),
      ],
    ),
  );

  Widget _buildItem(
    SettingsSidebarItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color = item.isDestructive
        ? FluxerColors.textDanger
        : isSelected
            ? FluxerColors.channelActive
            : FluxerColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? FluxerColors.backgroundModifierSelected
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                PhosphorIcon(item.icon!, size: 20, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSidebarItem {
  final String label;
  final bool isSeparator;
  final IconData? icon;
  final bool isDestructive;

  const SettingsSidebarItem(
    this.label, {
    this.icon,
    this.isSeparator = false,
    this.isDestructive = false,
  });

  const SettingsSidebarItem.separator([this.label = ''])
      : isSeparator = true,
        icon = null,
        isDestructive = false;
}
