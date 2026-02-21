import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/chat/domain/message.dart';

/// A link preview card.
class EmbedLink extends StatelessWidget {
  final Embed embed;

  const EmbedLink({required this.embed, super.key});

  @override
  Widget build(BuildContext context) {
    final sideColor = embed.color != null
        ? Color(embed.color!)
        : FluxerColors.backgroundAccent;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxWidth: 432),
      decoration: BoxDecoration(
        color: FluxerColors.embedBackground,
        border: Border(left: BorderSide(color: sideColor, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (embed.providerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  embed.providerName!,
                  style: FluxerTextStyles.embedFooter.copyWith(fontSize: 12),
                ),
              ),
            if (embed.authorName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  embed.authorName!,
                  style: const TextStyle(
                    color: FluxerColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (embed.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(embed.title!, style: FluxerTextStyles.embedTitle),
              ),
            if (embed.description != null)
              Text(
                embed.description!,
                style: FluxerTextStyles.embedDescription,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            if (embed.footerText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  embed.footerText!,
                  style: FluxerTextStyles.embedFooter,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
