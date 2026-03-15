import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Holds hue and saturation parameters for a color family.
class ColorFamily {
  const ColorFamily({
    required this.hue,
    required this.saturation,
    this.useSaturationFactor = true,
  });

  final double hue;
  final double saturation;
  final bool useSaturationFactor;
}

/// A named stop along a color scale.
///
/// A position of -1 means the stop will be auto-distributed evenly.
class ScaleStop {
  const ScaleStop({
    required this.name,
    this.position = -1,
  });

  final String name;
  final double position;
}

/// A scale that generates colors by interpolating lightness across stops.
class ColorScale {
  const ColorScale({
    required this.family,
    required this.lightnessStart,
    required this.lightnessEnd,
    required this.curve,
    required this.stops,
  });

  final ColorFamily family;
  final double lightnessStart;
  final double lightnessEnd;
  final Curve curve;
  final List<ScaleStop> stops;

  /// Generates a [Color] at the given [position] (0..1) along the scale.
  Color colorAt(double position, {double saturationFactor = 1.0}) {
    final t = curve.transform(position.clamp(0.0, 1.0));
    final lightness = lightnessStart + (lightnessEnd - lightnessStart) * t;
    final saturation = family.useSaturationFactor
        ? family.saturation * saturationFactor
        : family.saturation;

    return HSLColor.fromAHSL(
      1,
      family.hue % 360,
      (saturation / 100).clamp(0.0, 1.0),
      (lightness / 100).clamp(0.0, 1.0),
    ).toColor();
  }

  /// Builds all stops into a map of stop name to [Color].
  ///
  /// Stops with a position of -1 are auto-distributed evenly.
  Map<String, Color> build({double saturationFactor = 1.0}) {
    final result = <String, Color>{};
    final count = stops.length;

    for (var i = 0; i < count; i++) {
      final stop = stops[i];
      final position = stop.position < 0
          ? (count > 1 ? i / (count - 1) : 0.0)
          : stop.position;

      result[stop.name] = colorAt(position, saturationFactor: saturationFactor);
    }

    return result;
  }
}

/// Generates a single HSL color from the given parameters.
///
/// [hue] is in degrees (0..360), [saturation] and [lightness] are
/// percentages (0..100).
Color generateTone({
  required double hue,
  required double saturation,
  required double lightness,
  double opacity = 1.0,
}) {
  return HSLColor.fromAHSL(
    opacity.clamp(0.0, 1.0),
    hue % 360,
    (saturation / 100).clamp(0.0, 1.0),
    (lightness / 100).clamp(0.0, 1.0),
  ).toColor();
}
