import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thumbhash/flutter_thumbhash.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/features/ui/ui.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AttachmentImage extends StatelessWidget {
  static const double _defaultAspectRatio = 16 / 9;

  final Attachment attachment;

  const AttachmentImage({required this.attachment, super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 3),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
          decoration: BoxDecoration(
            color: context.colors.backgroundSecondaryAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: _resolveAspectRatio(),
              // TODO: Add full page preview onTap
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
        if (attachment.expiresAt != null)
          FluxerTextLink(
            text:
                'Expires on ${DateFormat('dd MMM, yyyy').format(attachment.expiresAt!)}',
            url: 'https://help.fluxer.app/en/articles/13984638',
            style: context.textStyles.embedFooter,
          ),
      ],
    );
  }
}
