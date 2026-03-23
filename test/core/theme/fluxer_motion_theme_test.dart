import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxeron/core/theme/fluxer_motion_theme.dart';

void main() {
  group('FluxerMotionTheme', () {
    test('default creates expected durations', () {
      const theme = FluxerMotionTheme.standard();
      expect(theme.fast, const Duration(milliseconds: 100));
      expect(theme.normal, const Duration(milliseconds: 150));
      expect(theme.slow, const Duration(milliseconds: 300));
      expect(theme.curve, Curves.easeOut);
      expect(theme.emphasizedCurve, Curves.easeInOut);
    });

    test('copyWith preserves unchanged values', () {
      const theme = FluxerMotionTheme.standard();
      final copied = theme.copyWith(fast: const Duration(milliseconds: 50));
      expect(copied.fast, const Duration(milliseconds: 50));
      expect(copied.normal, const Duration(milliseconds: 150));
    });

    test('lerp interpolates durations', () {
      const a = FluxerMotionTheme.standard();
      final b = a.copyWith(fast: const Duration(milliseconds: 200));
      final lerped = a.lerp(b, 0.5);
      expect(lerped.fast, const Duration(milliseconds: 150));
    });
  });
}
