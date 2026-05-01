import 'package:fluxer_dart/export.dart' as sdk;

const _kPreferredTenorPreviewFormats = <String>[
  'webp',
  'gif',
  'tinygif',
  'nanogif',
  'mp4',
  'webm',
  'tinymp4',
  'tinywebm',
];

sdk.TenorGifMediaResponse tenorPreviewMediaForPicker(sdk.TenorGifResponse gif) {
  for (final format in _kPreferredTenorPreviewFormats) {
    final media = gif.media[format];
    if (media != null && _hasUsableUrl(media)) {
      return media;
    }
  }

  return sdk.TenorGifMediaResponse(
    src: gif.src,
    proxySrc: gif.proxySrc,
    width: gif.width,
    height: gif.height,
  );
}

bool _hasUsableUrl(sdk.TenorGifMediaResponse media) =>
    media.src.isNotEmpty || media.proxySrc.isNotEmpty;
