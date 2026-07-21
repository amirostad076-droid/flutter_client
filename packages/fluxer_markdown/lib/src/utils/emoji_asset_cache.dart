import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/foundation.dart';

const String _kEmojiAssetUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

const String _kEmojiAssetAcceptHeader =
    'image/svg+xml,image/webp,image/apng,image/*,*/*;q=0.8';

class EmojiAssetCache {
  EmojiAssetCache._();

  static final BaseCacheManager _cacheManager =
      CachedNetworkImageProvider.defaultCacheManager;

  static Future<Uint8List> loadBytes(String url) async {
    final cacheKey = url;
    final cached = await _cacheManager.getFileFromCache(cacheKey);
    if (cached != null) {
      return cached.file.readAsBytes();
    }

    final bytes = await _fetchBytes(url);
    unawaited(_cacheManager.putFile(url, bytes, key: cacheKey));
    return bytes;
  }

  static Future<Uint8List> _fetchBytes(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, _kEmojiAssetUserAgent);
      request.headers.set(HttpHeaders.acceptHeader, _kEmojiAssetAcceptHeader);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Emoji asset load failed: ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }
      final builder = BytesBuilder();
      await response.forEach(builder.add);
      return builder.toBytes();
    } finally {
      client.close();
    }
  }

  @visibleForTesting
  static Future<void> clearCacheForTesting() async {
    await _cacheManager.emptyCache();
  }
}
