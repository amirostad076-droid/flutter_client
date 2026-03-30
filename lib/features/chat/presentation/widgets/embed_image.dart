import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';

/// An inline image / gifv embed
class EmbedImage extends StatelessWidget {
  final Embed embed;

  const EmbedImage({required this.embed, super.key});

  @override
  Widget build(BuildContext context) {
    final media = embed.image ?? embed.thumbnail;
    if (media == null) {
      return const SizedBox.shrink();
    }

    const maxW = 400.0;
    final w = media.width?.toDouble();
    final h = media.height?.toDouble();
    double? displayW;
    double? displayH;
    if (w != null && h != null && w > 0) {
      displayW = w.clamp(0, maxW);
      displayH = h * (displayW / w);
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxWidth: maxW),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: media.proxyUrl ?? media.url,
          width: displayW,
          height: displayH,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => Container(
            width: displayW ?? maxW,
            height: displayH ?? 200,
            color: context.colors.backgroundSecondaryAlt,
          ),
        ),
      ),
    );
  }
}
