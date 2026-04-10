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

  static const int _kNearingThreshold = 50;

  @override
  Widget build(BuildContext context) {
    final remaining = max - current;

    final Color color;
    if (remaining < 0) {
      color = context.colors.statusDanger;
    } else if (remaining < _kNearingThreshold) {
      color = context.colors.statusDanger;
    } else {
      color = context.colors.textSecondary;
    }

    return Text(
      '$remaining',
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
