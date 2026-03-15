import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A video embed placeholder (YouTube-style).
class EmbedVideo extends StatelessWidget {
  final Embed embed;

  const EmbedVideo({required this.embed, super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 4),
    constraints:
        const BoxConstraints(maxWidth: 400),
    decoration: BoxDecoration(
      color: context.colors.embedBackground,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        if (embed.providerName != null ||
            embed.authorName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              4,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (embed.providerName != null)
                  Text(
                    embed.providerName!,
                    style: context
                        .textStyles.embedFooter
                        .copyWith(fontSize: 12),
                  ),
                if (embed.authorName != null)
                  Text(
                    embed.authorName!,
                    style: TextStyle(
                      color: context
                          .colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        if (embed.title != null)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              4,
              12,
              8,
            ),
            child: Text(
              embed.title!,
              style:
                  context.textStyles.embedTitle,
            ),
          ),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Container(
            width: 400,
            height: 225,
            color: context
                .colors.backgroundFloating,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PhosphorIcon(
                  PhosphorIconsFill.playCircle,
                  size: 64,
                  color:
                      context.colors.textPrimary,
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Text(
                    'Video Embed',
                    style: TextStyle(
                      color: context
                          .colors.textPrimaryMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
