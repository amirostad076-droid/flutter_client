import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

class FluxerSubsectionLabel extends StatelessWidget {
  const FluxerSubsectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textTertiaryMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

@FluxerWidgetPreview(name: 'Default', group: 'FluxerSubsectionLabel')
Widget fluxerSubsectionLabelPreview() {
  return const FluxerSubsectionLabel('Additional Groups');
}
