import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

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
