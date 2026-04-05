import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';

class FluxerBadge extends StatelessWidget {
  const FluxerBadge.count({required this.count, this.size = 16, super.key})
    : text = null,
      isDot = false;

  const FluxerBadge.dot({this.size = 8, super.key})
    : count = null,
      text = null,
      isDot = true;

  const FluxerBadge.label({required this.text, this.size = 16, super.key})
    : count = null,
      isDot = false;

  final int? count;
  final String? text;
  final double size;
  final bool isDot;

  @override
  Widget build(BuildContext context) {
    if (isDot) {
      return _buildDot(context);
    }
    return _buildPill(context);
  }

  Widget _buildDot(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.textPrimary,
      shape: BoxShape.circle,
    ),
    child: SizedBox(width: size, height: size),
  );

  Widget _buildPill(BuildContext context) {
    final label = text ?? _formattedCount;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: context.colors.statusDanger,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: context.colors.textOnBrandPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
