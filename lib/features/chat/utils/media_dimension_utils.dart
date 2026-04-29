import 'dart:math' as math;
import 'dart:ui';

import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';

class FluxerMediaDimensions {
  const FluxerMediaDimensions({
    required this.maxWidth,
    required this.maxHeight,
  });

  final double maxWidth;
  final double maxHeight;
}

const FluxerMediaDimensions compactMediaDimensions = FluxerMediaDimensions(
  maxWidth: 400,
  maxHeight: 300,
);
const FluxerMediaDimensions comfortableMediaDimensions = FluxerMediaDimensions(
  maxWidth: 550,
  maxHeight: 400,
);

FluxerMediaDimensions mediaDimensionsForSize(MediaDimensionSize size) {
  return switch (size) {
    MediaDimensionSize.small => compactMediaDimensions,
    MediaDimensionSize.large => comfortableMediaDimensions,
  };
}

Size? constrainMediaSize({
  required FluxerMediaDimensions dimensions,
  required int? width,
  required int? height,
}) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }

  final sourceWidth = width.toDouble();
  final sourceHeight = height.toDouble();
  final scale = math.min(
    1,
    math.min(
      dimensions.maxWidth / sourceWidth,
      dimensions.maxHeight / sourceHeight,
    ),
  );

  return Size(sourceWidth * scale, sourceHeight * scale);
}
