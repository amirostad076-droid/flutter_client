import 'package:fluxer_app/features/chat/domain/message.dart';

final RegExp _spoilerRegex = RegExp(r'\|\|([\s\S]*?)\|\|');
final RegExp _urlRegex = RegExp(
  r'''https?:\/\/[^\s<>"']+''',
  caseSensitive: false,
);

Set<String> extractSpoileredUrls(String content) {
  final urls = <String>{};
  for (final spoiler in _spoilerRegex.allMatches(content)) {
    final body = spoiler.group(1);
    if (body == null || body.isEmpty) {
      continue;
    }
    for (final url in _urlRegex.allMatches(body)) {
      final normalized = normalizeSpoilerUrl(url.group(0) ?? '');
      if (normalized != null) {
        urls.add(normalized);
      }
    }
  }
  return urls;
}

String? normalizeSpoilerUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return null;
  }
  final normalized = uri.toString();
  return normalized.endsWith('/')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}

bool isEmbedSpoilered(Embed embed, Set<String> spoileredUrls) {
  if (spoileredUrls.isEmpty) {
    return false;
  }

  final candidates = <String?>[
    embed.url,
    embed.image?.url,
    embed.image?.proxyUrl,
    embed.thumbnail?.url,
    embed.thumbnail?.proxyUrl,
    embed.video?.url,
    embed.video?.proxyUrl,
  ];

  for (final candidate in candidates) {
    if (candidate == null) {
      continue;
    }
    final normalized = normalizeSpoilerUrl(candidate);
    if (normalized != null && spoileredUrls.contains(normalized)) {
      return true;
    }
  }

  return false;
}
