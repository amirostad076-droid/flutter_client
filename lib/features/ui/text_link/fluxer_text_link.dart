import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/ui/tappable/fluxer_tappable.dart';
import 'package:url_launcher/url_launcher_string.dart';

class FluxerTextLink extends StatelessWidget {
  const FluxerTextLink({
    required this.text,
    this.url,
    this.onTap,
    this.style,
    this.selectable = false,
    super.key,
  });

  final String text;
  final String? url;
  final VoidCallback? onTap;
  final TextStyle? style;
  final bool selectable;

  void _handleTap() {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (url != null) {
      unawaited(launchUrlString(url!, mode: LaunchMode.externalApplication));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: style?.color ?? colors.textLink,
    );

    return Semantics(
      link: true,
      linkUrl: url != null ? Uri.tryParse(url!) : null,
      child: FluxerTappable(
        onTap: _handleTap,
        builder: (context, states) {
          final isHovered = states.contains(WidgetState.hovered);
          final linkStyle = baseStyle.copyWith(
            decoration: isHovered
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: baseStyle.color,
          );

          if (selectable) {
            return SelectableText(text, style: linkStyle);
          }

          return Text(text, style: linkStyle);
        },
      ),
    );
  }
}
