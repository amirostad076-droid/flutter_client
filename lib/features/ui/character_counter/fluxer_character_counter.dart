import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';

class FluxerCharacterCounter extends StatelessWidget {
  const FluxerCharacterCounter({
    required this.current,
    required this.max,
    super.key,
  });

  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? current / max : 0.0;

    final Color color;
    if (ratio > 1.0) {
      color = context.colors.statusDanger;
    } else if (ratio >= 0.8) {
      color = context.colors.accentWarning;
    } else {
      color = context.colors.textSecondary;
    }

    return Text(
      '$current/$max',
      style: context.textStyles.smallText.copyWith(color: color),
      textAlign: TextAlign.right,
    );
  }
}
