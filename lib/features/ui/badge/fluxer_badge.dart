import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

class FluxerBadge extends StatelessWidget {
  const FluxerBadge.count({required this.count, this.cutoutColor, super.key})
    : text = null,
      size = 20,
      isDot = false;

  const FluxerBadge.dot({this.size = 8, super.key})
    : count = null,
      text = null,
      cutoutColor = null,
      isDot = true;

  const FluxerBadge.label({required this.text, this.cutoutColor, super.key})
    : count = null,
      size = 20,
      isDot = false;

  final int? count;
  final String? text;
  final double size;
  final bool isDot;

  /// Renders a hard 3px ring outside the badge in this color, creating a
  /// "cutout" notch when the badge is overlaid on an avatar or icon. Set to
  /// the surface color the badge sits on (e.g. the sidebar background).
  final Color? cutoutColor;

  @override
  Widget build(BuildContext context) {
    if (isDot) {
      return _buildDot(context);
    }
    return _buildPill(context);
  }

  Widget _buildDot(BuildContext context) => ExcludeSemantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.textPrimary,
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size),
    ),
  );

  Widget _buildPill(BuildContext context) {
    final label = text ?? _formattedCount;
    return Container(
      height: 20,
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: context.colors.statusDanger,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.colors.backgroundSecondary,
          width: 3,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: context.colors.textOnBrandPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }

  String get _formattedCount {
    final c = count ?? 0;
    return c > 99 ? '99+' : '$c';
  }
}

@FluxerWidgetPreview(name: 'Dot', group: 'FluxerBadge')
Widget fluxerBadgeDotPreview() {
  return const FluxerBadge.dot();
}

@FluxerWidgetPreview(name: 'Count', group: 'FluxerBadge')
Widget fluxerBadgeCountPreview() {
  return const FluxerBadge.count(count: 12);
}

@FluxerWidgetPreview(name: 'Label', group: 'FluxerBadge')
Widget fluxerBadgeLabelPreview() {
  return const FluxerBadge.label(text: 'NEW');
}
