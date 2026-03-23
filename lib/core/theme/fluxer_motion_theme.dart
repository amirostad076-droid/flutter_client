import 'package:flutter/material.dart';

class FluxerMotionTheme extends ThemeExtension<FluxerMotionTheme> {
  const FluxerMotionTheme({
    required this.fast,
    required this.normal,
    required this.slow,
    required this.curve,
    required this.emphasizedCurve,
  });

  const FluxerMotionTheme.standard()
    : fast = const Duration(milliseconds: 100),
      normal = const Duration(milliseconds: 150),
      slow = const Duration(milliseconds: 300),
      curve = Curves.easeOut,
      emphasizedCurve = Curves.easeInOut;

  final Duration fast;
  final Duration normal;
  final Duration slow;
  final Curve curve;
  final Curve emphasizedCurve;

  @override
  FluxerMotionTheme copyWith({
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Curve? curve,
    Curve? emphasizedCurve,
  }) => FluxerMotionTheme(
    fast: fast ?? this.fast,
    normal: normal ?? this.normal,
    slow: slow ?? this.slow,
    curve: curve ?? this.curve,
    emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
  );

  @override
  FluxerMotionTheme lerp(FluxerMotionTheme? other, double t) {
    if (other is! FluxerMotionTheme) {
      return this;
    }
    return FluxerMotionTheme(
      fast: _lerpDuration(fast, other.fast, t),
      normal: _lerpDuration(normal, other.normal, t),
      slow: _lerpDuration(slow, other.slow, t),
      curve: t < 0.5 ? curve : other.curve,
      emphasizedCurve: t < 0.5 ? emphasizedCurve : other.emphasizedCurve,
    );
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) => Duration(
    milliseconds: (a.inMilliseconds + (b.inMilliseconds - a.inMilliseconds) * t)
        .round(),
  );
}
