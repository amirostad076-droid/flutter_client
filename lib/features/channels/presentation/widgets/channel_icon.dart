import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/domain/channel.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChannelIcon extends StatelessWidget {
  final ChannelType type;
  final double size;
  final Color? color;

  const ChannelIcon({
    required this.type,
    this.size = 20,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) => PhosphorIcon(
    _icon,
    size: size,
    color: color ?? context.colors.textTertiary,
  );

  PhosphorIconData get _icon {
    switch (type) {
      case ChannelType.text:
        return PhosphorIconsRegular.hash;
      case ChannelType.voice:
        return PhosphorIconsFill.speakerHigh;
      case ChannelType.announcement:
        return PhosphorIconsFill.megaphone;
      case ChannelType.stage:
        return PhosphorIconsFill.broadcast;
      case ChannelType.category:
        return PhosphorIconsFill.folder;
    }
  }
}
