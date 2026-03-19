import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/color_generator.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Shows a styled bottom sheet with the app's standard appearance.
Future<T?> showStyledBottomSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
}) {
  final colors = context.colors;
  final layout = context.layout;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.backgroundSecondary,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: layout.radiusXxl.topLeft),
    ),
    builder: builder,
  );
}

// ---------------------------------------------------------------------------
// Structural widgets
// ---------------------------------------------------------------------------

class BottomSheetDragHandle extends StatelessWidget {
  const BottomSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.backgroundModifierAccent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class BottomSheetHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? subtitle;

  const BottomSheetHeader({
    required this.title,
    super.key,
    this.leading,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.s4),
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: layout.s3)],
          Expanded(
            child: Column(
              crossAxisAlignment: leading != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.textStyles.channelName.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[const SizedBox(height: 2), subtitle!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomSheetSubmenuHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const BottomSheetSubmenuHeader({
    required this.title,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsBold.caretLeft,
              size: 20,
              color: colors.textPrimary,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: context.textStyles.channelName.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu group
// ---------------------------------------------------------------------------

class MenuGroup extends StatelessWidget {
  final List<Widget> children;

  const MenuGroup({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final layout = context.layout;

    return Material(
      color: colors.backgroundSecondaryAlt,
      surfaceTintColor: Colors.transparent,
      borderRadius: layout.radiusXl,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _intersperseDividers(children, colors),
      ),
    );
  }
}

List<Widget> _intersperseDividers(List<Widget> items, FluxerColorTheme colors) {
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if (i < items.length - 1) {
      result.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colors.backgroundHeaderSecondary.withValues(alpha: 0.3),
          ),
        ),
      );
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Menu items
// ---------------------------------------------------------------------------

class MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isDanger;

  const MenuItem({
    required this.label,
    required this.onTap,
    super.key,
    this.icon,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isDanger
        ? generateTone(hue: 350, saturation: 90, lightness: 65)
        : colors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: PhosphorIcon(icon!, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: context.textStyles.username.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuSubmenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const MenuSubmenuItem({required this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.textStyles.username.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: 20,
              color: colors.textPrimaryMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class MenuGroupColumn extends StatelessWidget {
  final List<Widget> children;

  const MenuGroupColumn({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class MenuCheckboxItem extends StatelessWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  const MenuCheckboxItem({
    required this.label,
    required this.isChecked,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.textStyles.username.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isChecked
                      ? colors.brandPrimary
                      : colors.backgroundHeaderSecondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
                color: isChecked ? colors.brandPrimary : Colors.transparent,
              ),
              child: isChecked
                  ? const Center(
                      child: PhosphorIcon(
                        PhosphorIconsBold.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
