import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// An inline image/gif embed.
class EmbedImage extends StatelessWidget {
  final Embed embed;

  const EmbedImage({required this.embed, super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 4),
    constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
    decoration: BoxDecoration(
      color: context.colors.backgroundSecondaryAlt,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 400,
            height: 225,
            color: context.colors.backgroundSecondaryAlt,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIconsFill.image,
                  size: 48,
                  color: context.colors.textPrimaryMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  'Image Embed',
                  style: TextStyle(
                    color: context.colors.textPrimaryMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
