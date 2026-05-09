import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/attachment_display_utils.dart';
import 'package:fluxer_app/shared/external_links/external_link_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AttachmentFileLabel extends StatelessWidget {
  const AttachmentFileLabel({required this.attachment, super.key});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizeLabel = formatAttachmentByteSize(attachment.size);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: attachment.url.isEmpty
          ? null
          : () => unawaited(handleExternalLinkTap(context, attachment.url)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.backgroundSecondaryAlt.withValues(alpha: 0.45),
          border: Border.all(color: colors.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.paperclip,
              size: 20,
              color: colors.textPrimaryMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.filename,
                    style: context.textStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sizeLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sizeLabel,
                      style: context.textStyles.smallText.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
