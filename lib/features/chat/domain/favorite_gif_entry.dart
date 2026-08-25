import 'package:flutter/foundation.dart';
import 'package:fluxer_app/features/chat/domain/gif_selection.dart';

@immutable
class FavoriteGifEntry {
  const FavoriteGifEntry({
    required this.url,
    required this.proxyUrl,
    required this.width,
    required this.height,
    this.contentType = '',
    this.placeholder,
  });

  final String url;
  final String proxyUrl;
  final int width;
  final int height;
  final String contentType;
  final String? placeholder;
}

String favoriteGifUrl(GifPickerGif gif) => gif.url;

FavoriteGifEntry favoriteGifEntryFromPickerGif(GifPickerGif gif) {
  final proxyUrl = gif.proxySrc.trim().isNotEmpty
      ? gif.proxySrc
      : gif.src.trim().isNotEmpty
      ? gif.src
      : gif.url;
  return FavoriteGifEntry(
    url: favoriteGifUrl(gif),
    proxyUrl: proxyUrl,
    width: gif.width,
    height: gif.height,
  );
}
