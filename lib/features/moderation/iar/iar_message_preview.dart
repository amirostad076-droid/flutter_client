// Compact preview of the reported subject (message author + snippet).
//
// Shown at the top of the path/category/reason steps so the user knows what
// they're reporting at every step. Web equivalent: `IARModalPreview.tsx`.

import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/moderation/iar/iar_flow.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';

class IarPreview extends StatelessWidget {
  const IarPreview({required this.context, super.key});

  final IarContext context;

  @override
  Widget build(BuildContext ctx) {
    return switch (context) {
      IarMessageContext(:final message) => _MessagePreviewCard(
        authorName: message.authorName,
        authorId: message.authorId,
        authorAvatarColor: message.authorAvatarColor,
        content: message.content,
      ),
    };
  }
}

class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({
    required this.authorName,
    required this.authorId,
    required this.authorAvatarColor,
    required this.content,
  });

  final String authorName;
  final String authorId;
  final int? authorAvatarColor;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return Container(
      padding: EdgeInsets.all(layout.s3),
      decoration: BoxDecoration(
        color: colors.backgroundSecondaryAlt,
        borderRadius: layout.radiusLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluxerAvatar.user(
            fallbackText: authorName,
            avatarColor: authorAvatarColor,
            userId: authorId,
            size: 32,
            showStatus: false,
          ),
          SizedBox(width: layout.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authorName,
                  style: textStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (content.isNotEmpty) ...[
                  SizedBox(height: layout.s1),
                  Text(
                    content,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
