import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

/// Small demuxer cache for tiny looping GIF preview videos.
const int gifPreviewPlayerBufferSize = 4 * 1024 * 1024;

/// Player configuration optimized for muted GIF picker previews.
const PlayerConfiguration gifPreviewPlayerConfiguration = PlayerConfiguration(
  muted: true,
  bufferSize: gifPreviewPlayerBufferSize,
  title: 'Fluxer GIF preview',
);

/// Video controller configuration optimized for the current platform.
mkv.VideoControllerConfiguration gifPreviewVideoControllerConfiguration() =>
    gifPreviewVideoControllerConfigurationFor(defaultTargetPlatform);

/// Video controller configuration optimized for [platform].
mkv.VideoControllerConfiguration gifPreviewVideoControllerConfigurationFor(
  TargetPlatform platform,
) => switch (platform) {
  TargetPlatform.android => const mkv.VideoControllerConfiguration(
    vo: 'gpu',
    hwdec: 'auto-safe',
  ),
  _ => const mkv.VideoControllerConfiguration(),
};
