import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/features/chat/presentation/widgets/embed_shared.dart';
import 'package:url_launcher/url_launcher.dart';

/// A video embed placeholder (YouTube-style).
class EmbedVideo extends StatelessWidget {
  final Embed embed;

  const EmbedVideo({required this.embed, super.key});

  bool get _hasHeader =>
      embed.providerName != null ||
      embed.author != null ||
      embed.title != null;

  Future<void> _launch() async {
    final url = embed.url;
    if (url == null) {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final sideColor = embed.color != null
        ? Color(0xFF000000 | (embed.color! & 0xFFFFFF))
        : context.colors.backgroundSecondaryAlt;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: context.colors.embedBackground,
        border: Border(left: BorderSide(color: sideColor, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (embed.providerName != null)
                    Text(
                      embed.providerName!,
                      style: context.textStyles.embedFooter
                          .copyWith(fontSize: 12),
                    ),
                  if (embed.author != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: EmbedAuthorRow(author: embed.author!),
                    ),
                  if (embed.title != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: EmbedTitle(
                        title: embed.title!,
                        url: embed.url,
                      ),
                    ),
                ],
              ),
            ),
          GestureDetector(
            onTap: _launch,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: _VideoThumbnail(embed: embed),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final Embed embed;

  const _VideoThumbnail({required this.embed});

  @override
  Widget build(BuildContext context) {
    const maxW = 400.0;
    final video = embed.video;
    final thumb = embed.thumbnail;

    final w = video?.width?.toDouble() ?? thumb?.width?.toDouble();
    final h = video?.height?.toDouble() ?? thumb?.height?.toDouble();
    double displayW = maxW;
    double displayH = 225;
    if (w != null && h != null && w > 0) {
      displayW = w.clamp(0, maxW);
      displayH = h * (displayW / w);
    }

    final thumbUrl = thumb?.proxyUrl ?? thumb?.url;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (thumbUrl != null)
          CachedNetworkImage(
            imageUrl: thumbUrl,
            width: displayW,
            height: displayH,
            fit: BoxFit.cover,
            errorBuilder: (_, e, _s) =>
                _Placeholder(width: displayW, height: displayH),
          )
        else
          _Placeholder(width: displayW, height: displayH),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double width;
  final double height;

  const _Placeholder({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    color: context.colors.backgroundFloating,
  );
}
