import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

class FluxerKeybindHint extends StatelessWidget {
  const FluxerKeybindHint({required this.keys, super.key});

  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final colors = context.colors;
    final style = context.textStyles.smallText.copyWith(
      color: colors.textSecondary,
    );

    final children = <Widget>[];
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.s1),
            child: Text('+', style: style),
          ),
        );
      }
      children.add(
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: layout.s1_5,
            vertical: layout.s1,
          ),
          decoration: BoxDecoration(
            color: colors.backgroundTertiary,
            borderRadius: layout.radiusSm,
          ),
          child: Text(keys[i], style: style),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

@FluxerWidgetPreview(name: 'Default', group: 'FluxerKeybindHint')
Widget fluxerKeybindHintPreview() {
  return const FluxerKeybindHint(keys: ['⌘', 'K']);
}
