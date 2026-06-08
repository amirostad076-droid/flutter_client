import 'package:fluxer_app/features/chat/domain/chat_video_source.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const double kDefaultChatVideoAspectRatio = 16 / 9;

double resolveChatVideoAspectRatio({int? width, int? height}) {
  if (width != null && height != null && width > 0 && height > 0) {
    return width / height;
  }
  return kDefaultChatVideoAspectRatio;
}

bool isYouTubeUrl(String url) {
  final String host = Uri.tryParse(url)?.host ?? '';
  return host.contains('youtube.com') || host.contains('youtu.be');
}

Future<String> resolveYouTubeStreamUrl(String pageUrl) async {
  final YoutubeExplode yt = YoutubeExplode();
  try {
    final VideoId videoId = VideoId(pageUrl);
    final StreamManifest manifest = await yt.videos.streamsClient.getManifest(
      videoId,
    );
    final StreamInfo stream = manifest.muxed.withHighestBitrate();
    return stream.url.toString();
  } finally {
    yt.close();
  }
}

Future<String> resolvePlaybackUrl(ChatVideoSource source) async {
  final String? directMediaUrl = source.directMediaUrl;
  if (directMediaUrl != null && !isYouTubeUrl(directMediaUrl)) {
    return directMediaUrl;
  }
  final String? youtubeUrl = _resolveYouTubePageUrl(source);
  if (youtubeUrl != null) {
    return resolveYouTubeStreamUrl(youtubeUrl);
  }
  if (directMediaUrl != null) {
    return directMediaUrl;
  }
  throw StateError('No playable video URL available');
}

String? _resolveYouTubePageUrl(ChatVideoSource source) {
  final String? pageUrl = source.pageUrl;
  if (pageUrl != null && isYouTubeUrl(pageUrl)) {
    return pageUrl;
  }
  final String? directMediaUrl = source.directMediaUrl;
  if (directMediaUrl != null && isYouTubeUrl(directMediaUrl)) {
    return directMediaUrl;
  }
  return null;
}
