import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

class FluxerStatusIndicator extends StatelessWidget {
  const FluxerStatusIndicator({
    required this.status,
    this.size = 15,
    this.borderColor,
    super.key,
  });

  final String status;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = borderColor ?? colors.backgroundSecondary;
    final borderWidth = size * 0.05;

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
    final cutoutColor = borderColor ?? context.colors.backgroundSecondary;

    if (status == 'dnd') {
      final barHeight = size * 0.2;
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cutoutColor,
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
          child: SizedBox(width: size * 0.55, height: barHeight),
        ),
      );
    }

    if (status == 'idle') {
      return ClipOval(
        child: Align(
          alignment: const Alignment(0.4, -0.4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cutoutColor,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: size * 0.45, height: size * 0.45),
          ),
        ),
      );
    }

    if (status == 'offline' || status == 'invisible') {
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: cutoutColor, shape: BoxShape.circle),
          child: SizedBox(width: size * 0.4, height: size * 0.4),
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

@FluxerWidgetPreview(name: 'Online', group: 'FluxerStatusIndicator')
Widget fluxerStatusOnlinePreview() {
  return const FluxerStatusIndicator(status: 'online');
}

@FluxerWidgetPreview(name: 'Idle', group: 'FluxerStatusIndicator')
Widget fluxerStatusIdlePreview() {
  return const FluxerStatusIndicator(status: 'idle');
}

@FluxerWidgetPreview(name: 'DND', group: 'FluxerStatusIndicator')
Widget fluxerStatusDndPreview() {
  return const FluxerStatusIndicator(status: 'dnd');
}

@FluxerWidgetPreview(name: 'Offline', group: 'FluxerStatusIndicator')
Widget fluxerStatusOfflinePreview() {
  return const FluxerStatusIndicator(status: 'offline');
}
