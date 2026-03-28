import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

class FluxerStatusIndicator extends StatelessWidget {
  const FluxerStatusIndicator({
    required this.status,
    this.size = 12,
    this.borderColor,
    super.key,
  });

  final String status;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = borderColor ?? colors.backgroundPrimary;
    final borderWidth = size * 0.15;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _statusColor(context),
          shape: BoxShape.circle,
          border: Border.all(color: border, width: borderWidth),
        ),
        child: _buildInner(context),
      ),
    );
  }

  Widget? _buildInner(BuildContext context) {
    if (status == 'dnd') {
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: borderColor ?? context.colors.backgroundPrimary,
            borderRadius: BorderRadius.circular(1),
          ),
          child: SizedBox(width: size * 0.4, height: size * 0.12),
        ),
      );
    }

    if (status == 'idle') {
      return ClipOval(
        child: Align(
          alignment: const Alignment(0.4, -0.4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: borderColor ?? context.colors.backgroundPrimary,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: size * 0.45, height: size * 0.45),
          ),
        ),
      );
    }

    return null;
  }

  Color _statusColor(BuildContext context) {
    final colors = context.colors;
    return switch (status) {
      'online' => colors.statusOnline,
      'idle' => colors.statusIdle,
      'dnd' => colors.statusDnd,
      'streaming' => colors.statusDanger,
      _ => colors.statusOffline,
    };
  }
}
