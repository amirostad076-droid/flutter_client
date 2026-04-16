import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

class FluxerSettingsSection extends StatelessWidget {
  const FluxerSettingsSection({
    required this.title,
    required this.children,
    super.key,
    this.description,
    this.isFirst = false,
  });

  final String title;
  final String? description;
  final bool isFirst;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isFirst) ...[
          Divider(color: colors.borderColor),
          SizedBox(height: layout.s8),
        ],
        Text(
          title,
          style: textStyles.heading.copyWith(color: colors.textPrimary),
        ),
        if (description != null) ...[
          SizedBox(height: layout.s1),
          Text(
            description!,
            style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
        SizedBox(height: layout.s4),
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) SizedBox(height: layout.s8),
        ],
        SizedBox(height: layout.s8),
      ],
    );
  }
}

@FluxerWidgetPreview(name: 'Default', group: 'FluxerSettingsSection')
Widget fluxerSettingsSectionPreview() {
  return const FluxerSettingsSection(
    title: 'Connections',
    description: 'Control who can send you friend requests and direct messages',
    isFirst: true,
    children: [Text('Subsection content goes here')],
  );
}
