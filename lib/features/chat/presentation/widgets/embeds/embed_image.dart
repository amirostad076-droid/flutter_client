import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/spoiler_overlay.dart';
import 'package:fluxer_app/features/chat/utils/embed_media_viewer_utils.dart';
import 'package:fluxer_app/features/chat/utils/media_dimension_utils.dart';
import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';

/// An inline image / gifv embed
class EmbedImage extends StatelessWidget {
  final Embed embed;
  final MediaDimensionSize dimensionSize;
  final bool isSpoiler;
  final bool revealSpoiler;
  final FluxerSpoilerSyncController? spoilerSyncController;
  final List<String> spoilerSyncKeys;

  const EmbedImage({
    required this.embed,
    this.dimensionSize = MediaDimensionSize.small,
    this.isSpoiler = false,
    this.revealSpoiler = false,
    this.spoilerSyncController,
    this.spoilerSyncKeys = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final media = embed.image ?? embed.thumbnail;
    if (media == null) {
      return const SizedBox.shrink();
    }

    final dimensions = mediaDimensionsForSize(dimensionSize);
    final displaySize = constrainMediaSize(
      dimensions: dimensions,
      width: media.width,
      height: media.height,
    );

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: BoxConstraints(
        maxWidth: dimensions.maxWidth,
        maxHeight: dimensions.maxHeight,
      ),
      child: SpoilerOverlay(
        isSpoiler: isSpoiler,
        initiallyRevealed: revealSpoiler,
        spoilerSyncController: spoilerSyncController,
        syncKeys: spoilerSyncKeys,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: GestureDetector(
            onTap: canOpenEmbedMediaViewer(media)
                ? () => showAttachmentMediaViewer(
                    context,
                    items: [
                      buildEmbedMediaViewerItem(
                        media: media,
                        title: embed.title,
                      ),
                    ],
                  )
                : null,
            child: CachedNetworkImage(
              imageUrl: embedMediaEffectiveUrl(media),
              width: displaySize?.width,
              height: displaySize?.height,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                width: displaySize?.width ?? dimensions.maxWidth,
                height: displaySize?.height ?? 200,
                color: context.colors.backgroundSecondaryAlt,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
