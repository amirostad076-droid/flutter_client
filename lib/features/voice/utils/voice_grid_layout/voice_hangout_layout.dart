import 'dart:math' as math;

import 'package:fluxer_app/features/voice/utils/voice_grid_layout/voice_grid_layout.dart';

int voiceGridPageCount({required int tileCount, required int tilesPerPage}) {
  if (tileCount <= 0 || tilesPerPage <= 0) {
    return 0;
  }
  return (tileCount / tilesPerPage).ceil();
}

List<List<T>> voiceGridPaginateTiles<T>({
  required List<T> tiles,
  required int tilesPerPage,
}) {
  if (tiles.isEmpty || tilesPerPage <= 0) {
    return <List<T>>[];
  }
  final List<List<T>> pages = <List<T>>[];
  for (int i = 0; i < tiles.length; i += tilesPerPage) {
    final int end = math.min(i + tilesPerPage, tiles.length);
    pages.add(tiles.sublist(i, end));
  }
  return pages;
}

double voiceHangoutFilmstripCrossAxis({required bool compact}) {
  return compact ? 96 : 112;
}

double voiceHangoutFloatingSelfWidth({required bool compact}) {
  return compact ? 108 : 132;
}

double voiceHangoutFloatingSelfHeight({required bool compact}) {
  return voiceHangoutFloatingSelfWidth(compact: compact) /
      voiceGridTileAspectRatio;
}
