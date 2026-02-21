import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/chat/domain/message.dart';

/// A rich embed card -- colored side bar, title, description,
/// fields, thumbnail.
class EmbedRich extends StatelessWidget {
  final Embed embed;

  const EmbedRich({required this.embed, super.key});

  @override
  Widget build(BuildContext context) {
    final sideColor = embed.color != null
        ? Color(embed.color!)
        : FluxerColors.backgroundAccent;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: FluxerColors.embedBackground,
        border: Border(left: BorderSide(color: sideColor, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (embed.providerName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        embed.providerName!,
                        style: FluxerTextStyles.embedFooter.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (embed.authorName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          if (embed.authorIconUrl != null) ...[
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: FluxerColors.backgroundAccent,
                              child: PhosphorIcon(
                                PhosphorIconsFill.person,
                                size: 12,
                                color: FluxerColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            embed.authorName!,
                            style: const TextStyle(
                              color: FluxerColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (embed.title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        embed.title!,
                        style: FluxerTextStyles.embedTitle,
                      ),
                    ),
                  if (embed.description != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        embed.description!,
                        style: FluxerTextStyles.embedDescription,
                      ),
                    ),
                  if (embed.fields.isNotEmpty) _buildFields(),
                  if (embed.footerText != null) _buildFooter(),
                ],
              ),
            ),
            if (embed.thumbnailUrl != null)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: FluxerColors.backgroundAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: PhosphorIcon(
                      PhosphorIconsFill.image,
                      color: FluxerColors.textMuted,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Wrap(
      spacing: 16,
      runSpacing: 8,
      children: embed.fields
          .map(
            (field) => SizedBox(
              width: field.isInline ? 140 : double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.name,
                    style: const TextStyle(
                      color: FluxerColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    field.value,
                    style: const TextStyle(
                      color: FluxerColors.textNormal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _buildFooter() => Row(
    children: [
      if (embed.footerIconUrl != null) ...[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: FluxerColors.backgroundAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const PhosphorIcon(
            PhosphorIconsFill.info,
            size: 10,
            color: FluxerColors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
      ],
      Text(embed.footerText!, style: FluxerTextStyles.embedFooter),
    ],
  );
}
