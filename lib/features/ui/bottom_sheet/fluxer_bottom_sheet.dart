import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ---------------------------------------------------------------------------
// FluxerBottomSheet
// ---------------------------------------------------------------------------

/// Builder that receives the sheet's [BuildContext] and a [close] callback.
typedef FluxerBottomSheetBuilder =
    Widget Function(BuildContext context, VoidCallback close);

/// Shows a styled modal bottom sheet with the app's standard appearance.
///
/// The [builder] receives a `close` callback so children can dismiss the sheet
/// without needing their own `Navigator.pop` call.
class FluxerBottomSheet {
  FluxerBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required FluxerBottomSheetBuilder builder, String? title,
    Widget? subtitle,
    Widget? leading,
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
      builder: (sheetContext) {
        void close() => Navigator.of(sheetContext).pop();

        final bottomPadding = MediaQuery.paddingOf(sheetContext).bottom;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: layout.s2),
            const FluxerBottomSheetDragHandle(),
            if (title != null) ...[
              SizedBox(height: layout.s2),
              FluxerBottomSheetHeader(
                title: title,
                subtitle: subtitle,
                leading: leading,
              ),
            ],
            SizedBox(height: layout.s2),
            Flexible(child: builder(sheetContext, close)),
            SizedBox(height: bottomPadding > 0 ? bottomPadding : layout.s4),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Structural widgets
// ---------------------------------------------------------------------------

class FluxerBottomSheetDragHandle extends StatelessWidget {
  const FluxerBottomSheetDragHandle({super.key});

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

class FluxerBottomSheetHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? subtitle;

  const FluxerBottomSheetHeader({
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

class FluxerBottomSheetSubmenuHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const FluxerBottomSheetSubmenuHeader({
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

class FluxerMenuGroup extends StatelessWidget {
  final List<Widget> children;

  const FluxerMenuGroup({required this.children, super.key});

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

class FluxerBottomSheetMenuItem extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isDanger;

  const FluxerBottomSheetMenuItem({
    required this.label,
    required this.onTap,
    super.key,
    this.hint,
    this.icon,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isDanger ? colors.statusDanger : colors.textPrimary;

    return FluxerTappable(
      onTap: onTap,
      builder: (context, states) {
        return Padding(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.textStyles.username.copyWith(color: color),
                    ),
                    if (hint != null)
                      Text(
                        hint!,
                        style: context.textStyles.timestamp.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FluxerBottomSheetSubmenuItem extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onTap;

  const FluxerBottomSheetSubmenuItem({
    required this.label,
    required this.onTap,
    this.hint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FluxerTappable(
      onTap: onTap,
      builder: (context, states) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.textStyles.username.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (hint != null)
                      Text(
                        hint!,
                        style: context.textStyles.timestamp.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 20,
                color: colors.textPrimaryMuted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class FluxerBottomSheetGroupColumn extends StatelessWidget {
  final List<Widget> children;

  const FluxerBottomSheetGroupColumn({required this.children, super.key});

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

class FluxerBottomSheetCheckboxItem extends StatelessWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  const FluxerBottomSheetCheckboxItem({
    required this.label,
    required this.isChecked,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FluxerTappable(
      onTap: onTap,
      builder: (context, states) {
        return Padding(
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
                    ? Center(
                        child: PhosphorIcon(
                          PhosphorIconsBold.check,
                          size: 12,
                          color: colors.textOnBrandPrimary,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
