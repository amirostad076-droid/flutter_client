import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/gif_media_selection.dart';
import 'package:fluxer_dart/export.dart' as sdk;

void main() {
  test('parses Tenor media formats from the API payload', () {
    final gif = sdk.TenorGifResponse.fromJson(const {
      'id': 'tenor-1',
      'slug': 'view/excited-ah-gif-1',
      'provider': 'tenor',
      'title': 'Excited ah',
      'url': 'https://tenor.com/view/excited-ah-gif-1',
      'src': 'https://media.tenor.com/excited-ah.webm',
      'proxy_src': 'https://cdn.example/excited-ah.webm',
      'width': 498,
      'height': 498,
      'media': {
        'webm': {
          'src': 'https://media.tenor.com/excited-ah.webm',
          'proxy_src': 'https://cdn.example/excited-ah.webm',
          'width': 498,
          'height': 498,
        },
        'webp': {
          'src': 'https://media.tenor.com/excited-ah.webp',
          'proxy_src': 'https://cdn.example/excited-ah.webp',
          'width': 498,
          'height': 498,
        },
        'tinygif': {
          'src': 'https://media.tenor.com/excited-ah.gif',
          'proxy_src': 'https://cdn.example/excited-ah.gif',
          'width': 165,
          'height': 165,
        },
      },
    });

    expect(gif.media['webp']?.proxySrc, 'https://cdn.example/excited-ah.webp');
  });

  test('prefers WebP image media over video media for Tenor previews', () {
    const gif = sdk.TenorGifResponse(
      id: 'tenor-1',
      title: 'Excited ah',
      url: 'https://tenor.com/view/excited-ah-gif-1',
      src: 'https://media.tenor.com/excited-ah.webm',
      proxySrc: 'https://cdn.example/excited-ah.webm',
      width: 498,
      height: 498,
      media: {
        'webm': sdk.TenorGifMediaResponse(
          src: 'https://media.tenor.com/excited-ah.webm',
          proxySrc: 'https://cdn.example/excited-ah.webm',
          width: 498,
          height: 498,
        ),
        'mp4': sdk.TenorGifMediaResponse(
          src: 'https://media.tenor.com/excited-ah.mp4',
          proxySrc: 'https://cdn.example/excited-ah.mp4',
          width: 498,
          height: 498,
        ),
        'webp': sdk.TenorGifMediaResponse(
          src: 'https://media.tenor.com/excited-ah.webp',
          proxySrc: 'https://cdn.example/excited-ah.webp',
          width: 498,
          height: 498,
        ),
        'tinygif': sdk.TenorGifMediaResponse(
          src: 'https://media.tenor.com/excited-ah-small.gif',
          proxySrc: 'https://cdn.example/excited-ah-small.gif',
          width: 165,
          height: 165,
        ),
      },
    );

    final media = tenorPreviewMediaForPicker(gif);

    expect(media.src, 'https://media.tenor.com/excited-ah.webp');
    expect(media.proxySrc, 'https://cdn.example/excited-ah.webp');
    expect(media.width, 498);
    expect(media.height, 498);
  });

  test('falls back to tiny GIF media before video media', () {
    const gif = sdk.TenorGifResponse(
      id: 'tenor-1',
      title: 'Excited ah',
      url: 'https://tenor.com/view/excited-ah-gif-1',
      src: 'https://media.tenor.com/excited-ah.webm',
      proxySrc: 'https://cdn.example/excited-ah.webm',
      width: 320,
      height: 228,
      media: {
        'tinywebm': sdk.TenorGifMediaResponse(
          src: 'https://media.tenor.com/excited-ah.webm',
          proxySrc: 'https://cdn.example/excited-ah.webm',
          width: 320,
          height: 228,
        ),
        'tinygif': sdk.TenorGifMediaResponse(
          src: 'https://media.tenor.com/excited-ah.gif',
          proxySrc: 'https://cdn.example/excited-ah.gif',
          width: 220,
          height: 157,
        ),
      },
    );

    final media = tenorPreviewMediaForPicker(gif);

    expect(media.src, 'https://media.tenor.com/excited-ah.gif');
    expect(media.width, 220);
    expect(media.height, 157);
  });
}
