import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';

void main() {
  test('FavoriteMeme decodes persisted JSON and exposes media metadata', () {
    final meme = FavoriteMeme.fromRow(
      db.FavoriteMemesTableData(id: '123', data: jsonEncode(_memeJson())),
    );

    expect(meme.id, '123');
    expect(meme.name, 'Wave Cat');
    expect(meme.tags, ['cat', 'wave']);
    expect(meme.mediaType, FavoriteMemeMediaType.gif);
    expect(meme.isVideoLike, isTrue);
    expect(meme.shareUrl, 'https://klipy.com/gifs/wave-cat');
  });

  test('FavoriteMeme falls back to CDN URL for regular saved media', () {
    final meme = FavoriteMeme.fromJson({
      ..._memeJson(),
      'id': '456',
      'content_type': 'image/png',
      'is_gifv': false,
      'klipy_slug': null,
      'tenor_slug_id': null,
      'url': 'https://cdn.example/image.png',
    });

    expect(meme.mediaType, FavoriteMemeMediaType.image);
    expect(meme.isVideoLike, isFalse);
    expect(meme.shareUrl, 'https://cdn.example/image.png');
  });

  test('FavoriteMeme builds Tenor share URLs from slug ids', () {
    final meme = FavoriteMeme.fromJson({
      ..._memeJson(),
      'klipy_slug': null,
      'tenor_slug_id': 'view/funny-cat-123',
    });

    expect(meme.shareUrl, 'https://tenor.com/view/funny-cat-123');
  });
}

Map<String, Object?> _memeJson() => {
  'id': '123',
  'user_id': 'user-1',
  'name': 'Wave Cat',
  'alt_text': 'A waving cat',
  'tags': ['cat', 'wave'],
  'attachment_id': 'attachment-1',
  'filename': 'wave-cat.mp4',
  'content_type': 'video/mp4',
  'content_hash': 'hash',
  'size': 1024,
  'width': 320,
  'height': 180,
  'duration': 1.2,
  'is_gifv': true,
  'url': 'https://cdn.example/wave-cat.mp4',
  'klipy_slug': 'wave-cat',
  'tenor_slug_id': null,
};
