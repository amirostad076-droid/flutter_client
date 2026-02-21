import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';

/// Build Fluxer-styled ThemeData (dark theme).
ThemeData buildFluxerTheme() {
  final fontFamily = FluxerTextStyles.messageText.fontFamily;

  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: FluxerColors.backgroundPrimary,
    canvasColor: FluxerColors.backgroundSecondary,
    cardColor: FluxerColors.embedBackground,
    dividerColor: FluxerColors.divider,
    colorScheme: const ColorScheme.dark(
      primary: FluxerColors.blurple,
      onPrimary: FluxerColors.textOnBrand,
      secondary: FluxerColors.blurple,
      surface: FluxerColors.backgroundPrimary,
      onSurface: FluxerColors.textNormal,
    ),
    textTheme: TextTheme(
      bodyLarge: FluxerTextStyles.messageText,
      bodyMedium: FluxerTextStyles.messageText,
      titleLarge: FluxerTextStyles.heading,
      labelSmall: FluxerTextStyles.smallText,
    ),
    iconTheme: const IconThemeData(
      color: FluxerColors.interactiveNormal,
      size: 20,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FluxerColors.backgroundPrimary,
      foregroundColor: FluxerColors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: FluxerColors.backgroundFloating,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(FluxerColors.scrollbarThin),
      trackColor: WidgetStateProperty.all(FluxerColors.scrollbarAuto),
      radius: const Radius.circular(4),
      thickness: WidgetStateProperty.all(6),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: const BoxDecoration(
        color: FluxerColors.backgroundFloating,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      textStyle: TextStyle(
        fontFamily: fontFamily,
        color: FluxerColors.textNormal,
        fontSize: 14,
      ),
    ),
  );
}
