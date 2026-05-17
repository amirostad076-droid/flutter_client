import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';

class CachedEmojiImage extends StatelessWidget {
  const CachedEmojiImage({
    required this.emojiId,
    required this.animated,
    required this.requestSize,
    required this.size,
    this.errorBuilder,
    super.key,
  });

  final String emojiId;
  final bool animated;
  final int requestSize;
  final double size;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final url = FluxerMediaUrl.customEmoji(
      id: emojiId,
      animated: animated,
      size: requestSize,
    );

    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: 'emoji_${emojiId}_${animated ? 'a' : 's'}_$requestSize',
      width: size,
      height: size,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      fit: BoxFit.contain,
      placeholder: (_, _) => SizedBox(width: size, height: size),
      errorBuilder: errorBuilder != null
          ? (ctx, _, _) => errorBuilder!(ctx)
          : (_, _, _) => SizedBox(width: size, height: size),
    );
  }
}
