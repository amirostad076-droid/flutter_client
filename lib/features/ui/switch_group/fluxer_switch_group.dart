import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';

class FluxerSwitchGroup extends StatelessWidget {
  const FluxerSwitchGroup({required this.children, super.key});

  final List<Widget> children;

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
        children: _intersperseGroupDividers(children, colors),
      ),
    );
  }
}

class FluxerSwitchGroupItem extends StatelessWidget {
  const FluxerSwitchGroupItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.shortcut,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? shortcut;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return FluxerTappable(
      enabled: enabled,
      onTap: () => onChanged(!value),
      semanticLabel: label,
      builder: (context, states) {
        final isPressed = states.contains(WidgetState.pressed);

        return AnimatedContainer(
          duration: context.motion.fast,
          curve: context.motion.curve,
          color: isPressed
              ? colors.backgroundModifierHover.withValues(alpha: 0.5)
              : Colors.transparent,
          constraints: const BoxConstraints(minHeight: 68),
          padding: EdgeInsets.symmetric(
            horizontal: 0,
            vertical: layout.s3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: textStyles.bodyMedium.copyWith(
                              color: enabled
                                  ? colors.textPrimary
                                  : colors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (shortcut != null) ...[
                          SizedBox(width: layout.s2),
                          shortcut!,
                        ],
                      ],
                    ),
                    if (description != null) ...[
                      SizedBox(height: layout.s1),
                      Text(
                        description!,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textPrimaryMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: layout.s4),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class FluxerSwitchGroupCustomItem extends StatelessWidget {
  const FluxerSwitchGroupCustomItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.extraContent,
    this.onTap,
    this.enabled = true,
    this.tapEnabled = true,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? extraContent;
  final VoidCallback? onTap;
  final bool enabled;
  final bool tapEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: layout.s4,
          vertical: layout.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: FluxerTappable(
                enabled: tapEnabled,
                onTap: onTap,
                semanticLabel: label,
                builder: (context, states) {
                  return Text(
                    label,
                    style: textStyles.bodyMedium.copyWith(
                      color: tapEnabled
                          ? colors.textPrimary
                          : colors.textTertiary,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: layout.s4),
            if (extraContent != null) ...[
              extraContent!,
              SizedBox(width: layout.s2),
            ],
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _intersperseGroupDividers(
  List<Widget> items,
  FluxerColorTheme colors,
) {
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

@FluxerWidgetPreview(name: 'Group', group: 'FluxerSwitchGroup')
Widget fluxerSwitchGroupPreview() {
  return FluxerSwitchGroup(
    children: [
      FluxerSwitchGroupItem(
        label: 'Message previews',
        description: 'Show a short excerpt under muted channels.',
        value: true,
        onChanged: (_) {},
      ),
      FluxerSwitchGroupItem(
        label: 'Link embeds',
        value: false,
        onChanged: (_) {},
      ),
    ],
  );
}

@FluxerWidgetPreview(name: 'Custom item', group: 'FluxerSwitchGroup')
Widget fluxerSwitchGroupCustomPreview() {
  return FluxerSwitchGroup(
    children: [
      FluxerSwitchGroupCustomItem(
        label: 'Beta features',
        value: false,
        onChanged: (_) {},
        extraContent: const Text('Labs'),
      ),
    ],
  );
}
