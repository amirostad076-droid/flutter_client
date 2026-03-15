import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';

/// Build Fluxer-styled ThemeData from theme extensions.
ThemeData buildFluxerTheme({
  required FluxerColorTheme colorTheme,
  required FluxerTextTheme textTheme,
  required FluxerLayoutTheme layoutTheme,
  Brightness brightness = Brightness.dark,
}) {
  final fontFamily = textTheme.messageText.fontFamily;

  return ThemeData(
    brightness: brightness,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: colorTheme.backgroundPrimary,
    canvasColor: colorTheme.backgroundSecondary,
    cardColor: colorTheme.embedBackground,
    dividerColor: colorTheme.borderColor,
    extensions: [colorTheme, textTheme, layoutTheme],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colorTheme.brandPrimary,
      onPrimary: colorTheme.textOnBrandPrimary,
      secondary: colorTheme.brandSecondary,
      onSecondary: colorTheme.textOnBrandPrimary,
      error: colorTheme.accentDanger,
      onError: colorTheme.textOnBrandPrimary,
      surface: colorTheme.backgroundPrimary,
      onSurface: colorTheme.textPrimary,
      surfaceContainerHighest: colorTheme.backgroundTertiary,
      outline: colorTheme.borderColor,
    ),
    textTheme: TextTheme(
      bodyLarge: textTheme.messageText,
      bodyMedium: textTheme.bodyMedium,
      bodySmall: textTheme.bodySmall,
      titleLarge: textTheme.heading,
      labelSmall: textTheme.smallText,
      labelMedium: textTheme.label,
    ),
    iconTheme: IconThemeData(
      color: colorTheme.interactiveNormal,
      size: 20,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorTheme.backgroundPrimary,
      foregroundColor: colorTheme.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: colorTheme.backgroundFloating,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(colorTheme.scrollbarThumbBg),
      trackColor: WidgetStateProperty.all(colorTheme.scrollbarTrackBg),
      radius: const Radius.circular(4),
      thickness: WidgetStateProperty.all(6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorTheme.buttonPrimaryFill,
        foregroundColor: colorTheme.buttonPrimaryText,
        disabledBackgroundColor:
            colorTheme.buttonPrimaryFill.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: layoutTheme.radiusLg,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorTheme.textLink,
        shape: RoundedRectangleBorder(
          borderRadius: layoutTheme.radiusLg,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorTheme.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: layoutTheme.radiusLg,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorTheme.backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: layoutTheme.radiusLg,
        borderSide: BorderSide(
          color: colorTheme.backgroundModifierAccent,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: layoutTheme.radiusLg,
        borderSide: BorderSide(
          color: colorTheme.backgroundModifierAccent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: layoutTheme.radiusLg,
        borderSide: BorderSide(
          color: colorTheme.brandPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colorTheme.backgroundFloating,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      textStyle: TextStyle(
        fontFamily: fontFamily,
        color: colorTheme.textPrimary,
        fontSize: 14,
      ),
    ),
  );
}
