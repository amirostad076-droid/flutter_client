import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_motion_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';

extension FluxerThemeX on BuildContext {
  FluxerColorTheme get colors => Theme.of(this).extension<FluxerColorTheme>()!;
  FluxerTextTheme get textStyles =>
      Theme.of(this).extension<FluxerTextTheme>()!;
  FluxerLayoutTheme get layout =>
      Theme.of(this).extension<FluxerLayoutTheme>()!;
  FluxerMotionTheme get motion =>
      Theme.of(this).extension<FluxerMotionTheme>()!;
}
