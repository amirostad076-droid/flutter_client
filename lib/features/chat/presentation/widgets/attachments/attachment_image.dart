import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thumbhash/flutter_thumbhash.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/forward_message_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/spoiler_overlay.dart';
import 'package:fluxer_app/features/chat/utils/media_dimension_utils.dart';
import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AttachmentImage extends StatelessWidget {
  static const double _defaultAspectRatio = 16 / 9;

  final Attachment attachment;
  final MediaDimensionSize dimensionSize;
  final bool revealSpoiler;
  final bool wrapWithSpoiler;
  final List<Attachment>? imageGallery;
  final int imageGalleryIndex;
  final String? channelId;
  final String? messageId;

  const AttachmentImage({
    required this.attachment,
    this.dimensionSize = MediaDimensionSize.small,
    this.revealSpoiler = false,
    this.wrapWithSpoiler = true,
    this.imageGallery,
    this.imageGalleryIndex = 0,
    this.channelId,
    this.messageId,
    super.key,
  });

  double _resolveAspectRatio() {
    final int? width = attachment.width;
    final int? height = attachment.height;
    if (width != null && height != null && width > 0 && height > 0) {
      return width / height;
    }
    return _defaultAspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = mediaDimensionsForSize(dimensionSize);
    final List<Attachment> gallery = _buildGallery();
    final image = Container(
      margin: const EdgeInsets.only(top: 4, bottom: 3),
      constraints: BoxConstraints(
        maxWidth: dimensions.maxWidth,
        maxHeight: dimensions.maxHeight,
      ),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondaryAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: gallery.isEmpty
              ? null
              : () => showAttachmentMediaViewer(
                  context,
                  items: gallery.map(_buildMediaViewerItem).toList(),
                  initialIndex: imageGalleryIndex.clamp(0, gallery.length - 1),
                  onForward: (channelId != null && messageId != null)
                      ? (int index) => showForwardMediaSheet(
                          context,
                          sourceChannelId: channelId!,
                          sourceMessageId: messageId!,
                          attachmentIds: <String>[gallery[index].id],
                        )
                      : null,
                ),
          child: AspectRatio(
            aspectRatio: _resolveAspectRatio(),
            child: CachedNetworkImage(
              imageUrl: attachment.url,
              fit: BoxFit.contain,
              placeholder: (context, url) {
                if (attachment.placeholder != null) {
                  return Image(
                    image: ThumbHash.fromBase64(
                      attachment.placeholder!,
                    ).toImage(),
                    fit: BoxFit.contain,
                  );
                }
                return const Skeletonizer(
                  child: SizedBox(
                    height: double.maxFinite,
                    width: double.maxFinite,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    if (!wrapWithSpoiler) {
      return image;
    }
    return SpoilerOverlay(
      isSpoiler: attachment.isSpoiler,
      initiallyRevealed: revealSpoiler,
      child: image,
    );
  }

  List<Attachment> _buildGallery() {
    if (imageGallery != null && imageGallery!.isNotEmpty) {
      return imageGallery!;
    }
    if (attachment.url.isEmpty) {
      return const <Attachment>[];
    }
    return <Attachment>[attachment];
  }

  AttachmentMediaViewerItem _buildMediaViewerItem(Attachment value) {
    return AttachmentMediaViewerItem(
      url: value.url,
      filename: value.filename,
      width: value.width,
      height: value.height,
    );
  }
}
