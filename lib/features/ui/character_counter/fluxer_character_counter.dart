import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

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

@FluxerWidgetPreview(name: 'Normal', group: 'FluxerCharacterCounter')
Widget fluxerCharacterCounterNormalPreview() {
  return const FluxerCharacterCounter(current: 24, max: 100);
}

@FluxerWidgetPreview(name: 'Near limit', group: 'FluxerCharacterCounter')
Widget fluxerCharacterCounterWarnPreview() {
  return const FluxerCharacterCounter(current: 85, max: 100);
}

@FluxerWidgetPreview(name: 'Over limit', group: 'FluxerCharacterCounter')
Widget fluxerCharacterCounterOverPreview() {
  return const FluxerCharacterCounter(current: 120, max: 100);
}
