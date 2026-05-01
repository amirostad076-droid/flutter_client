class GifPreviewPlaybackCandidate {
  const GifPreviewPlaybackCandidate({
    required this.index,
    required this.top,
    required this.bottom,
    required this.left,
  });

  final int index;
  final double top;
  final double bottom;
  final double left;
}

class GifPreviewPlaybackPolicy {
  const GifPreviewPlaybackPolicy({required this.maxActiveVideos});

  final int maxActiveVideos;

  Set<int> allowedVideoIndexes({
    required Iterable<GifPreviewPlaybackCandidate> candidates,
    required double viewportTop,
    required double viewportBottom,
    required bool isScrollActive,
  }) {
    if (isScrollActive || maxActiveVideos <= 0) {
      return <int>{};
    }

    final visibleCandidates =
        candidates
            .where(
              (candidate) =>
                  candidate.bottom >= viewportTop &&
                  candidate.top <= viewportBottom,
            )
            .toList()
          ..sort(_compareCandidatesByPaintOrder);

    return visibleCandidates
        .take(maxActiveVideos)
        .map((candidate) => candidate.index)
        .toSet();
  }

  static int _compareCandidatesByPaintOrder(
    GifPreviewPlaybackCandidate a,
    GifPreviewPlaybackCandidate b,
  ) {
    final topComparison = a.top.compareTo(b.top);
    if (topComparison != 0) {
      return topComparison;
    }
    return a.left.compareTo(b.left);
  }
}
