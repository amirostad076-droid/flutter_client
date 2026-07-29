/// Distance from a loaded edge at which an edge load may fire, in pixels.
double messageListLoadEnterMargin(double viewportHeight) =>
    (viewportHeight * 0.9).clamp(480.0, 900.0);

/// Edge-load trigger: a LEVEL, deliberately stateless.
///
/// Fires whenever the viewport sits inside the enter margin during a
/// user-driven scroll and the edge has more to load. Dedupe lives with the
/// parties that own the facts, not in geometry here:
///   * one request in flight per direction — [isLoading], set synchronously by
///     the view model before its first await;
///   * a cursor that already proved unproductive — the view model's pagination
///     progress ledger, which refuses the parked tuple until something real
///     re-arms it (window progress, a new user gesture, a swap).
///
/// The previous shape kept a per-edge baseline and demanded fresh progress
/// toward the edge before re-firing, re-arming only ~1.4 viewport heights
/// away. Against the hard wall at the loaded newer edge that was a deadlock:
/// a landing that snapped the viewport to the wall ratcheted the baseline to
/// ~0, no geometrically possible position could beat it by the progress
/// delta, and a user scrolling toward newer never retreats far enough to
/// re-arm — a device log shows 8-24s stretches of fling gestures with zero
/// requests, ending with the user bailing out via jump-to-present.
bool shouldRequestEdgeLoad({
  required double distanceFromEdge,
  required double viewportHeight,
  required bool hasMore,
  required bool isLoading,
  required bool isUserDrivenScroll,
  required bool hasActiveJumpTarget,
}) =>
    hasMore &&
    !isLoading &&
    !hasActiveJumpTarget &&
    isUserDrivenScroll &&
    distanceFromEdge <= messageListLoadEnterMargin(viewportHeight);
