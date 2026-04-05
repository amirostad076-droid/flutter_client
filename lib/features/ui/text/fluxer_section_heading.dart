import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

class FluxerSectionHeading extends StatelessWidget {
  const FluxerSectionHeading({
    required this.title,
    super.key,
    this.description,
  });

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
    );
  }
}

@FluxerWidgetPreview(name: 'Title only', group: 'FluxerSectionHeading')
Widget fluxerSectionHeadingTitlePreview() {
  return const FluxerSectionHeading(title: 'Section title');
}

@FluxerWidgetPreview(name: 'With description', group: 'FluxerSectionHeading')
Widget fluxerSectionHeadingDescriptionPreview() {
  return const FluxerSectionHeading(
    title: 'Appearance',
    description: 'Customize how Fluxer looks on your device.',
  );
}
