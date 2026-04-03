import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

class FluxerFieldLabel extends StatelessWidget {
  const FluxerFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textStyles.bodySmall.copyWith(
        color: context.colors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
