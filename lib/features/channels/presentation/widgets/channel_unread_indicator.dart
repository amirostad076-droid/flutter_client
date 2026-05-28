import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

class ChannelUnreadIndicator extends StatelessWidget {
  const ChannelUnreadIndicator({this.faded = false, super.key});

  final bool faded;
  @override
  Widget build(BuildContext context) {
    final Widget indicator = Container(
      width: 4,
      height: 8,
      decoration: BoxDecoration(
        color: context.colors.textPrimary,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(9999),
          bottomRight: Radius.circular(9999),
        ),
      ),
    );
    if (!faded) {
      return indicator;
    }
    return Opacity(opacity: 0.4, child: indicator);
  }
}
