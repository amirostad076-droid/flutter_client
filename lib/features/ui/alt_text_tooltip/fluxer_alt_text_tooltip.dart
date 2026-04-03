import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/tooltip/fluxer_tooltip.dart';

class FluxerAltTextTooltip extends StatelessWidget {
  const FluxerAltTextTooltip({
    required this.altText,
    required this.child,
    this.position = FluxerTooltipPosition.above,
    super.key,
  });

  final String altText;
  final Widget child;
  final FluxerTooltipPosition position;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final colors = context.colors;

    return FluxerTooltip(
      position: position,
      richMessage: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Text(
          altText,
          style: textStyles.bodySmall.copyWith(
            color: colors.textPrimary,
          ),
          softWrap: true,
        ),
      ),
      child: child,
    );
  }
}
