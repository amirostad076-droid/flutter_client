class VoiceGridLayoutMetrics {
  const VoiceGridLayoutMetrics({
    required this.columns,
    required this.rows,
    required this.gap,
    required this.sidePadding,
    required this.verticalPadding,
    required this.availableWidth,
    required this.availableHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.contentWidth,
    required this.contentHeight,
  });

  final int columns;
  final int rows;
  final double gap;
  final double sidePadding;
  final double verticalPadding;
  final double availableWidth;
  final double availableHeight;
  final double tileWidth;
  final double tileHeight;
  final double contentWidth;
  final double contentHeight;
}

class VoiceGridPackedLayoutMetrics {
  const VoiceGridPackedLayoutMetrics({
    required this.metrics,
    required this.visibleTileCount,
  });

  final VoiceGridLayoutMetrics metrics;
  final int visibleTileCount;
}

class VoiceGridMinTileSize {
  const VoiceGridMinTileSize({
    required this.minTileWidth,
    required this.minTileHeight,
  });

  final double minTileWidth;
  final double minTileHeight;
}
