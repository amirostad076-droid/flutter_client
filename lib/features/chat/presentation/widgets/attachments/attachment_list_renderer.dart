import 'package:flutter/material.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_image_grid.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_renderer.dart';
import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';

class AttachmentListRenderer extends StatelessWidget {
  const AttachmentListRenderer({
    required this.attachments,
    required this.inlineAttachmentMedia,
    required this.dimensionSize,
    required this.revealSpoilers,
    this.topPadding = 0,
    this.messageId,
    this.messageNonce,
    this.channelId,
    super.key,
  });

  final List<Attachment> attachments;
  final bool inlineAttachmentMedia;
  final MediaDimensionSize dimensionSize;
  final bool revealSpoilers;
  final double topPadding;
  final String? messageId;
  final String? messageNonce;
  final String? channelId;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<Attachment> imageAttachments = attachments
        .where(
          (Attachment attachment) =>
              inlineAttachmentMedia &&
              attachment.isImage &&
              attachment.url.isNotEmpty,
        )
        .toList();
    final bool shouldRenderImageGrid = imageAttachments.length > 1;
    bool hasRenderedGrid = false;
    final List<Widget> children = <Widget>[];
    for (final Attachment attachment in attachments) {
      final bool isImageAttachment =
          inlineAttachmentMedia &&
          attachment.isImage &&
          attachment.url.isNotEmpty;
      if (shouldRenderImageGrid && isImageAttachment) {
        if (!hasRenderedGrid) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AttachmentImageGrid(
                attachments: imageAttachments,
                revealSpoilers: revealSpoilers,
                dimensionSize: dimensionSize,
                channelId: channelId,
                messageId: messageId,
              ),
            ),
          );
          hasRenderedGrid = true;
        }
        continue;
      }
      children.add(
        AttachmentRenderer(
          attachment: attachment,
          inlineAttachmentMedia: inlineAttachmentMedia,
          dimensionSize: dimensionSize,
          revealSpoilers: revealSpoilers,
          imageGallery: imageAttachments,
          imageGalleryIndex: isImageAttachment
              ? imageAttachments.indexOf(attachment)
              : 0,
          messageId: messageId,
          messageNonce: messageNonce,
          channelId: channelId,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
