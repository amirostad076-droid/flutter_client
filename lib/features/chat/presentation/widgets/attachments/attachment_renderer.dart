import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_audio.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_file_label.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_image.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_render_state.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_video.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/spoiler_overlay.dart';
import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:intl/intl.dart';

class AttachmentRenderer extends StatelessWidget {
  const AttachmentRenderer({
    required this.attachment,
    required this.inlineAttachmentMedia,
    required this.dimensionSize,
    required this.revealSpoilers,
    super.key,
  });

  final Attachment attachment;
  final bool inlineAttachmentMedia;
  final MediaDimensionSize dimensionSize;
  final bool revealSpoilers;

  @override
  Widget build(BuildContext context) {
    final AttachmentRenderState renderState = buildAttachmentRenderState(
      attachment: attachment,
      inlineAttachmentMedia: inlineAttachmentMedia,
    );
    final Widget content = _buildContent(renderState);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SpoilerOverlay(
            isSpoiler: attachment.isSpoiler,
            initiallyRevealed: revealSpoilers,
            child: content,
          ),
          if (attachment.expiresAt != null) _buildExpiryText(context),
        ],
      ),
    );
  }

  Widget _buildContent(AttachmentRenderState renderState) {
    if (renderState.shouldRenderAsFile) {
      return AttachmentFileLabel(attachment: attachment);
    }
    return switch (renderState.type) {
      AttachmentRenderType.image => AttachmentImage(
        attachment: attachment,
        dimensionSize: dimensionSize,
        revealSpoiler: revealSpoilers,
        wrapWithSpoiler: false,
      ),
      AttachmentRenderType.video => AttachmentVideo(
        attachment: attachment,
        dimensionSize: dimensionSize,
      ),
      AttachmentRenderType.audio => AttachmentAudio(attachment: attachment),
      AttachmentRenderType.file => AttachmentFileLabel(attachment: attachment),
    };
  }

  Widget _buildExpiryText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: FluxerTextLink(
        text:
            'Expires on ${DateFormat('dd MMM, yyyy').format(attachment.expiresAt!)}',
        url: 'https://help.fluxer.app/en/articles/13984638',
        color: context.colors.textChatMuted,
        style: context.textStyles.smallText.copyWith(
          fontSize: 10,
          height: 1.2,
        ),
      ),
    );
  }
}
