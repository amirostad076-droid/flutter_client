# Theme System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace static `FluxerColors`/`FluxerTextStyles` with a context-aware ThemeExtension system supporting Dark, Light, and Coal themes with programmatic color generation and global UI scaling.

**Architecture:** HSL color generator produces theme variants from family definitions. Three ThemeExtensions (color, text, layout) are accessed via `context.colors`, `context.textStyles`, `context.layout`. Theme preference persisted in Drift with per-user support.

**Tech Stack:** Flutter ThemeExtension, Drift (SQLite), Riverpod code-gen, HSLColor

---

### Task 1: Color Generator

**Files:**
- Create: `lib/core/theme/color_generator.dart`

**Step 1: Create the color generator**

Port the web app's `GenerateColorSystem.tsx` logic to Dart. This is a pure computation module with no Flutter dependencies beyond `dart:ui` for `Color`.

```dart
import 'dart:ui';

import 'package:flutter/animation.dart';

/// Defines a color family by its HSL hue and saturation.
class ColorFamily {
  final double hue;
  final double saturation;
  final bool useSaturationFactor;

  const ColorFamily({
    required this.hue,
    required this.saturation,
    this.useSaturationFactor = true,
  });
}

/// A named stop along a color scale at a specific position [0..1].
class ScaleStop {
  final String name;
  final double position;

  const ScaleStop(this.name, {this.position = -1});
}

/// Defines a lightness gradient along a color family.
class ColorScale {
  final ColorFamily family;
  final double lightnessStart;
  final double lightnessEnd;
  final Curve curve;
  final List<ScaleStop> stops;

  const ColorScale({
    required this.family,
    required this.lightnessStart,
    required this.lightnessEnd,
    required this.curve,
    required this.stops,
  });

  /// Generate a color at a given position [0..1] along this scale.
  Color colorAt(double position, {double saturationFactor = 1.0}) {
    final t = curve.transform(position.clamp(0.0, 1.0));
    final lightness = lightnessStart + (lightnessEnd - lightnessStart) * t;
    final sat = family.useSaturationFactor
        ? family.saturation * saturationFactor
        : family.saturation;
    return HSLColor.fromAHSL(
      1.0,
      family.hue,
      (sat / 100).clamp(0.0, 1.0),
      (lightness / 100).clamp(0.0, 1.0),
    ).toColor();
  }

  /// Build all stops into a name→Color map.
  Map<String, Color> build({double saturationFactor = 1.0}) {
    final lastIndex = (stops.length - 1).clamp(1, stops.length);
    final result = <String, Color>{};
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final pos = stop.position >= 0 ? stop.position : i / lastIndex;
      result[stop.name] = colorAt(pos, saturationFactor: saturationFactor);
    }
    return result;
  }
}

/// Generate a single HSL tone color.
Color generateTone({
  required double hue,
  required double saturation,
  required double lightness,
  double alpha = 1.0,
  double saturationFactor = 1.0,
  bool useSaturationFactor = true,
}) {
  final sat = useSaturationFactor ? saturation * saturationFactor : saturation;
  return HSLColor.fromAHSL(
    alpha,
    hue,
    (sat / 100).clamp(0.0, 1.0),
    (lightness / 100).clamp(0.0, 1.0),
  ).toColor();
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/color_generator.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/color_generator.dart
git commit -m "feat(theme): add HSL color generator ported from web app"
```

---

### Task 2: Color Family Definitions

**Files:**
- Create: `lib/core/theme/color_families.dart`

**Step 1: Define all 12 color families matching the web app**

```dart
import 'package:fluxeron/core/theme/color_generator.dart';

/// Color family definitions matching the Fluxer web app's GenerateColorSystem.
///
/// Each family defines a hue + saturation pair used to generate
/// tokens across dark, light, and coal theme scales.
abstract final class FluxerColorFamilies {
  static const neutralDark = ColorFamily(hue: 220, saturation: 13);
  static const neutralLight = ColorFamily(hue: 220, saturation: 10);
  static const brand = ColorFamily(hue: 242, saturation: 70);
  static const link = ColorFamily(hue: 210, saturation: 100);
  static const accentPurple = ColorFamily(hue: 270, saturation: 80);
  static const statusOnline = ColorFamily(hue: 142, saturation: 76);
  static const statusIdle = ColorFamily(hue: 45, saturation: 93);
  static const statusDnd = ColorFamily(hue: 0, saturation: 84);
  static const statusOffline = ColorFamily(hue: 218, saturation: 11);
  static const statusDanger = ColorFamily(hue: 1, saturation: 77);
  static const textCode = ColorFamily(hue: 340, saturation: 50);
  static const brandIcon = ColorFamily(hue: 38, saturation: 92);
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/color_families.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/color_families.dart
git commit -m "feat(theme): add color family definitions from web app"
```

---

### Task 3: FluxerColorTheme ThemeExtension

**Files:**
- Create: `lib/core/theme/fluxer_color_theme.dart`

**Step 1: Create the ThemeExtension with all ~90 color tokens**

This is the largest file. It defines every semantic color token as a field, implements `copyWith` and `lerp`, and provides no default values — themes supply all values.

```dart
import 'dart:ui';

import 'package:flutter/material.dart';

/// All semantic color tokens for the Fluxer theme.
///
/// Access via `context.colors.tokenName`.
class FluxerColorTheme extends ThemeExtension<FluxerColorTheme> {
  // ── Background ──
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundSecondaryAlt;
  final Color backgroundTertiary;
  final Color backgroundTextarea;
  final Color backgroundHeaderPrimary;
  final Color backgroundHeaderPrimaryHover;
  final Color backgroundHeaderSecondary;
  final Color backgroundChannelHeader;
  final Color backgroundFloating;
  final Color guildListForeground;
  final Color backgroundModifierHover;
  final Color backgroundModifierSelected;
  final Color backgroundModifierAccent;
  final Color backgroundModifierAccentFocus;

  // ── Brand ──
  final Color brandPrimary;
  final Color brandSecondary;
  final Color brandPrimaryLight;
  final Color brandPrimaryFill;

  // ── Status ──
  final Color statusOnline;
  final Color statusIdle;
  final Color statusDnd;
  final Color statusOffline;
  final Color statusDanger;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textPrimaryMuted;
  final Color textChat;
  final Color textChatMuted;
  final Color textLink;
  final Color textOnBrandPrimary;
  final Color textTertiaryMuted;
  final Color textTertiarySecondary;
  final Color textWarning;
  final Color textDanger;
  final Color textPositive;
  final Color textCode;

  // ── Border ──
  final Color borderColor;
  final Color borderColorHover;
  final Color borderColorFocus;

  // ── Accent ──
  final Color accentPrimary;
  final Color accentSuccess;
  final Color accentWarning;
  final Color accentDanger;
  final Color accentInfo;
  final Color accentPurple;

  // ── Alert ──
  final Color alertNote;
  final Color alertTip;
  final Color alertImportant;
  final Color alertWarning;
  final Color alertCaution;

  // ── Markup ──
  final Color markupMentionText;
  final Color markupMentionFill;
  final Color markupInteractiveHoverText;
  final Color markupInteractiveHoverFill;

  // ── Button ──
  final Color buttonPrimaryFill;
  final Color buttonPrimaryActiveFill;
  final Color buttonPrimaryText;
  final Color buttonSecondaryFill;
  final Color buttonSecondaryActiveFill;
  final Color buttonSecondaryText;
  final Color buttonSecondaryActiveText;
  final Color buttonDangerFill;
  final Color buttonDangerActiveFill;
  final Color buttonDangerText;
  final Color buttonDangerOutlineBorder;
  final Color buttonDangerOutlineText;
  final Color buttonDangerOutlineActiveFill;
  final Color buttonGhostText;
  final Color buttonInvertedFill;
  final Color buttonInvertedText;
  final Color buttonOutlineBorder;
  final Color buttonOutlineText;
  final Color buttonOutlineActiveFill;

  // ── Content Background ──
  final Color bgCode;
  final Color bgCodeBlock;
  final Color bgBlockquote;
  final Color bgTableHeader;
  final Color bgTableRowOdd;
  final Color bgTableRowEven;

  // ── Interactive Surface ──
  final Color surfaceInteractiveHoverBg;
  final Color surfaceInteractiveSelectedBg;
  final Color surfaceInteractiveSelectedColor;

  // ── Scrollbar ──
  final Color scrollbarThumbBg;
  final Color scrollbarThumbBgHover;
  final Color scrollbarTrackBg;

  // ── UI-specific ──
  final Color chatBackground;
  final Color chatInputBackground;
  final Color serverSidebarBackground;
  final Color serverIconBackground;
  final Color serverIconActive;
  final Color channelSidebarBackground;
  final Color memberListBackground;
  final Color userPanelBackground;
  final Color embedBackground;
  final Color embedBorder;
  final Color mentionBackground;
  final Color spoilerBackground;
  final Color focusPrimary;
  final Color interactiveActive;
  final Color interactiveNormal;
  final Color interactiveHover;
  final Color interactiveMuted;

  const FluxerColorTheme({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundSecondaryAlt,
    required this.backgroundTertiary,
    required this.backgroundTextarea,
    required this.backgroundHeaderPrimary,
    required this.backgroundHeaderPrimaryHover,
    required this.backgroundHeaderSecondary,
    required this.backgroundChannelHeader,
    required this.backgroundFloating,
    required this.guildListForeground,
    required this.backgroundModifierHover,
    required this.backgroundModifierSelected,
    required this.backgroundModifierAccent,
    required this.backgroundModifierAccentFocus,
    required this.brandPrimary,
    required this.brandSecondary,
    required this.brandPrimaryLight,
    required this.brandPrimaryFill,
    required this.statusOnline,
    required this.statusIdle,
    required this.statusDnd,
    required this.statusOffline,
    required this.statusDanger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textPrimaryMuted,
    required this.textChat,
    required this.textChatMuted,
    required this.textLink,
    required this.textOnBrandPrimary,
    required this.textTertiaryMuted,
    required this.textTertiarySecondary,
    required this.textWarning,
    required this.textDanger,
    required this.textPositive,
    required this.textCode,
    required this.borderColor,
    required this.borderColorHover,
    required this.borderColorFocus,
    required this.accentPrimary,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentDanger,
    required this.accentInfo,
    required this.accentPurple,
    required this.alertNote,
    required this.alertTip,
    required this.alertImportant,
    required this.alertWarning,
    required this.alertCaution,
    required this.markupMentionText,
    required this.markupMentionFill,
    required this.markupInteractiveHoverText,
    required this.markupInteractiveHoverFill,
    required this.buttonPrimaryFill,
    required this.buttonPrimaryActiveFill,
    required this.buttonPrimaryText,
    required this.buttonSecondaryFill,
    required this.buttonSecondaryActiveFill,
    required this.buttonSecondaryText,
    required this.buttonSecondaryActiveText,
    required this.buttonDangerFill,
    required this.buttonDangerActiveFill,
    required this.buttonDangerText,
    required this.buttonDangerOutlineBorder,
    required this.buttonDangerOutlineText,
    required this.buttonDangerOutlineActiveFill,
    required this.buttonGhostText,
    required this.buttonInvertedFill,
    required this.buttonInvertedText,
    required this.buttonOutlineBorder,
    required this.buttonOutlineText,
    required this.buttonOutlineActiveFill,
    required this.bgCode,
    required this.bgCodeBlock,
    required this.bgBlockquote,
    required this.bgTableHeader,
    required this.bgTableRowOdd,
    required this.bgTableRowEven,
    required this.surfaceInteractiveHoverBg,
    required this.surfaceInteractiveSelectedBg,
    required this.surfaceInteractiveSelectedColor,
    required this.scrollbarThumbBg,
    required this.scrollbarThumbBgHover,
    required this.scrollbarTrackBg,
    required this.chatBackground,
    required this.chatInputBackground,
    required this.serverSidebarBackground,
    required this.serverIconBackground,
    required this.serverIconActive,
    required this.channelSidebarBackground,
    required this.memberListBackground,
    required this.userPanelBackground,
    required this.embedBackground,
    required this.embedBorder,
    required this.mentionBackground,
    required this.spoilerBackground,
    required this.focusPrimary,
    required this.interactiveActive,
    required this.interactiveNormal,
    required this.interactiveHover,
    required this.interactiveMuted,
  });

  @override
  FluxerColorTheme copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundSecondaryAlt,
    Color? backgroundTertiary,
    Color? backgroundTextarea,
    Color? backgroundHeaderPrimary,
    Color? backgroundHeaderPrimaryHover,
    Color? backgroundHeaderSecondary,
    Color? backgroundChannelHeader,
    Color? backgroundFloating,
    Color? guildListForeground,
    Color? backgroundModifierHover,
    Color? backgroundModifierSelected,
    Color? backgroundModifierAccent,
    Color? backgroundModifierAccentFocus,
    Color? brandPrimary,
    Color? brandSecondary,
    Color? brandPrimaryLight,
    Color? brandPrimaryFill,
    Color? statusOnline,
    Color? statusIdle,
    Color? statusDnd,
    Color? statusOffline,
    Color? statusDanger,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textPrimaryMuted,
    Color? textChat,
    Color? textChatMuted,
    Color? textLink,
    Color? textOnBrandPrimary,
    Color? textTertiaryMuted,
    Color? textTertiarySecondary,
    Color? textWarning,
    Color? textDanger,
    Color? textPositive,
    Color? textCode,
    Color? borderColor,
    Color? borderColorHover,
    Color? borderColorFocus,
    Color? accentPrimary,
    Color? accentSuccess,
    Color? accentWarning,
    Color? accentDanger,
    Color? accentInfo,
    Color? accentPurple,
    Color? alertNote,
    Color? alertTip,
    Color? alertImportant,
    Color? alertWarning,
    Color? alertCaution,
    Color? markupMentionText,
    Color? markupMentionFill,
    Color? markupInteractiveHoverText,
    Color? markupInteractiveHoverFill,
    Color? buttonPrimaryFill,
    Color? buttonPrimaryActiveFill,
    Color? buttonPrimaryText,
    Color? buttonSecondaryFill,
    Color? buttonSecondaryActiveFill,
    Color? buttonSecondaryText,
    Color? buttonSecondaryActiveText,
    Color? buttonDangerFill,
    Color? buttonDangerActiveFill,
    Color? buttonDangerText,
    Color? buttonDangerOutlineBorder,
    Color? buttonDangerOutlineText,
    Color? buttonDangerOutlineActiveFill,
    Color? buttonGhostText,
    Color? buttonInvertedFill,
    Color? buttonInvertedText,
    Color? buttonOutlineBorder,
    Color? buttonOutlineText,
    Color? buttonOutlineActiveFill,
    Color? bgCode,
    Color? bgCodeBlock,
    Color? bgBlockquote,
    Color? bgTableHeader,
    Color? bgTableRowOdd,
    Color? bgTableRowEven,
    Color? surfaceInteractiveHoverBg,
    Color? surfaceInteractiveSelectedBg,
    Color? surfaceInteractiveSelectedColor,
    Color? scrollbarThumbBg,
    Color? scrollbarThumbBgHover,
    Color? scrollbarTrackBg,
    Color? chatBackground,
    Color? chatInputBackground,
    Color? serverSidebarBackground,
    Color? serverIconBackground,
    Color? serverIconActive,
    Color? channelSidebarBackground,
    Color? memberListBackground,
    Color? userPanelBackground,
    Color? embedBackground,
    Color? embedBorder,
    Color? mentionBackground,
    Color? spoilerBackground,
    Color? focusPrimary,
    Color? interactiveActive,
    Color? interactiveNormal,
    Color? interactiveHover,
    Color? interactiveMuted,
  }) {
    return FluxerColorTheme(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundSecondaryAlt: backgroundSecondaryAlt ?? this.backgroundSecondaryAlt,
      backgroundTertiary: backgroundTertiary ?? this.backgroundTertiary,
      backgroundTextarea: backgroundTextarea ?? this.backgroundTextarea,
      backgroundHeaderPrimary: backgroundHeaderPrimary ?? this.backgroundHeaderPrimary,
      backgroundHeaderPrimaryHover: backgroundHeaderPrimaryHover ?? this.backgroundHeaderPrimaryHover,
      backgroundHeaderSecondary: backgroundHeaderSecondary ?? this.backgroundHeaderSecondary,
      backgroundChannelHeader: backgroundChannelHeader ?? this.backgroundChannelHeader,
      backgroundFloating: backgroundFloating ?? this.backgroundFloating,
      guildListForeground: guildListForeground ?? this.guildListForeground,
      backgroundModifierHover: backgroundModifierHover ?? this.backgroundModifierHover,
      backgroundModifierSelected: backgroundModifierSelected ?? this.backgroundModifierSelected,
      backgroundModifierAccent: backgroundModifierAccent ?? this.backgroundModifierAccent,
      backgroundModifierAccentFocus: backgroundModifierAccentFocus ?? this.backgroundModifierAccentFocus,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      brandPrimaryLight: brandPrimaryLight ?? this.brandPrimaryLight,
      brandPrimaryFill: brandPrimaryFill ?? this.brandPrimaryFill,
      statusOnline: statusOnline ?? this.statusOnline,
      statusIdle: statusIdle ?? this.statusIdle,
      statusDnd: statusDnd ?? this.statusDnd,
      statusOffline: statusOffline ?? this.statusOffline,
      statusDanger: statusDanger ?? this.statusDanger,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textPrimaryMuted: textPrimaryMuted ?? this.textPrimaryMuted,
      textChat: textChat ?? this.textChat,
      textChatMuted: textChatMuted ?? this.textChatMuted,
      textLink: textLink ?? this.textLink,
      textOnBrandPrimary: textOnBrandPrimary ?? this.textOnBrandPrimary,
      textTertiaryMuted: textTertiaryMuted ?? this.textTertiaryMuted,
      textTertiarySecondary: textTertiarySecondary ?? this.textTertiarySecondary,
      textWarning: textWarning ?? this.textWarning,
      textDanger: textDanger ?? this.textDanger,
      textPositive: textPositive ?? this.textPositive,
      textCode: textCode ?? this.textCode,
      borderColor: borderColor ?? this.borderColor,
      borderColorHover: borderColorHover ?? this.borderColorHover,
      borderColorFocus: borderColorFocus ?? this.borderColorFocus,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentWarning: accentWarning ?? this.accentWarning,
      accentDanger: accentDanger ?? this.accentDanger,
      accentInfo: accentInfo ?? this.accentInfo,
      accentPurple: accentPurple ?? this.accentPurple,
      alertNote: alertNote ?? this.alertNote,
      alertTip: alertTip ?? this.alertTip,
      alertImportant: alertImportant ?? this.alertImportant,
      alertWarning: alertWarning ?? this.alertWarning,
      alertCaution: alertCaution ?? this.alertCaution,
      markupMentionText: markupMentionText ?? this.markupMentionText,
      markupMentionFill: markupMentionFill ?? this.markupMentionFill,
      markupInteractiveHoverText: markupInteractiveHoverText ?? this.markupInteractiveHoverText,
      markupInteractiveHoverFill: markupInteractiveHoverFill ?? this.markupInteractiveHoverFill,
      buttonPrimaryFill: buttonPrimaryFill ?? this.buttonPrimaryFill,
      buttonPrimaryActiveFill: buttonPrimaryActiveFill ?? this.buttonPrimaryActiveFill,
      buttonPrimaryText: buttonPrimaryText ?? this.buttonPrimaryText,
      buttonSecondaryFill: buttonSecondaryFill ?? this.buttonSecondaryFill,
      buttonSecondaryActiveFill: buttonSecondaryActiveFill ?? this.buttonSecondaryActiveFill,
      buttonSecondaryText: buttonSecondaryText ?? this.buttonSecondaryText,
      buttonSecondaryActiveText: buttonSecondaryActiveText ?? this.buttonSecondaryActiveText,
      buttonDangerFill: buttonDangerFill ?? this.buttonDangerFill,
      buttonDangerActiveFill: buttonDangerActiveFill ?? this.buttonDangerActiveFill,
      buttonDangerText: buttonDangerText ?? this.buttonDangerText,
      buttonDangerOutlineBorder: buttonDangerOutlineBorder ?? this.buttonDangerOutlineBorder,
      buttonDangerOutlineText: buttonDangerOutlineText ?? this.buttonDangerOutlineText,
      buttonDangerOutlineActiveFill: buttonDangerOutlineActiveFill ?? this.buttonDangerOutlineActiveFill,
      buttonGhostText: buttonGhostText ?? this.buttonGhostText,
      buttonInvertedFill: buttonInvertedFill ?? this.buttonInvertedFill,
      buttonInvertedText: buttonInvertedText ?? this.buttonInvertedText,
      buttonOutlineBorder: buttonOutlineBorder ?? this.buttonOutlineBorder,
      buttonOutlineText: buttonOutlineText ?? this.buttonOutlineText,
      buttonOutlineActiveFill: buttonOutlineActiveFill ?? this.buttonOutlineActiveFill,
      bgCode: bgCode ?? this.bgCode,
      bgCodeBlock: bgCodeBlock ?? this.bgCodeBlock,
      bgBlockquote: bgBlockquote ?? this.bgBlockquote,
      bgTableHeader: bgTableHeader ?? this.bgTableHeader,
      bgTableRowOdd: bgTableRowOdd ?? this.bgTableRowOdd,
      bgTableRowEven: bgTableRowEven ?? this.bgTableRowEven,
      surfaceInteractiveHoverBg: surfaceInteractiveHoverBg ?? this.surfaceInteractiveHoverBg,
      surfaceInteractiveSelectedBg: surfaceInteractiveSelectedBg ?? this.surfaceInteractiveSelectedBg,
      surfaceInteractiveSelectedColor: surfaceInteractiveSelectedColor ?? this.surfaceInteractiveSelectedColor,
      scrollbarThumbBg: scrollbarThumbBg ?? this.scrollbarThumbBg,
      scrollbarThumbBgHover: scrollbarThumbBgHover ?? this.scrollbarThumbBgHover,
      scrollbarTrackBg: scrollbarTrackBg ?? this.scrollbarTrackBg,
      chatBackground: chatBackground ?? this.chatBackground,
      chatInputBackground: chatInputBackground ?? this.chatInputBackground,
      serverSidebarBackground: serverSidebarBackground ?? this.serverSidebarBackground,
      serverIconBackground: serverIconBackground ?? this.serverIconBackground,
      serverIconActive: serverIconActive ?? this.serverIconActive,
      channelSidebarBackground: channelSidebarBackground ?? this.channelSidebarBackground,
      memberListBackground: memberListBackground ?? this.memberListBackground,
      userPanelBackground: userPanelBackground ?? this.userPanelBackground,
      embedBackground: embedBackground ?? this.embedBackground,
      embedBorder: embedBorder ?? this.embedBorder,
      mentionBackground: mentionBackground ?? this.mentionBackground,
      spoilerBackground: spoilerBackground ?? this.spoilerBackground,
      focusPrimary: focusPrimary ?? this.focusPrimary,
      interactiveActive: interactiveActive ?? this.interactiveActive,
      interactiveNormal: interactiveNormal ?? this.interactiveNormal,
      interactiveHover: interactiveHover ?? this.interactiveHover,
      interactiveMuted: interactiveMuted ?? this.interactiveMuted,
    );
  }

  @override
  FluxerColorTheme lerp(FluxerColorTheme? other, double t) {
    if (other is! FluxerColorTheme) return this;
    return FluxerColorTheme(
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary: Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      backgroundSecondaryAlt: Color.lerp(backgroundSecondaryAlt, other.backgroundSecondaryAlt, t)!,
      backgroundTertiary: Color.lerp(backgroundTertiary, other.backgroundTertiary, t)!,
      backgroundTextarea: Color.lerp(backgroundTextarea, other.backgroundTextarea, t)!,
      backgroundHeaderPrimary: Color.lerp(backgroundHeaderPrimary, other.backgroundHeaderPrimary, t)!,
      backgroundHeaderPrimaryHover: Color.lerp(backgroundHeaderPrimaryHover, other.backgroundHeaderPrimaryHover, t)!,
      backgroundHeaderSecondary: Color.lerp(backgroundHeaderSecondary, other.backgroundHeaderSecondary, t)!,
      backgroundChannelHeader: Color.lerp(backgroundChannelHeader, other.backgroundChannelHeader, t)!,
      backgroundFloating: Color.lerp(backgroundFloating, other.backgroundFloating, t)!,
      guildListForeground: Color.lerp(guildListForeground, other.guildListForeground, t)!,
      backgroundModifierHover: Color.lerp(backgroundModifierHover, other.backgroundModifierHover, t)!,
      backgroundModifierSelected: Color.lerp(backgroundModifierSelected, other.backgroundModifierSelected, t)!,
      backgroundModifierAccent: Color.lerp(backgroundModifierAccent, other.backgroundModifierAccent, t)!,
      backgroundModifierAccentFocus: Color.lerp(backgroundModifierAccentFocus, other.backgroundModifierAccentFocus, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      brandPrimaryLight: Color.lerp(brandPrimaryLight, other.brandPrimaryLight, t)!,
      brandPrimaryFill: Color.lerp(brandPrimaryFill, other.brandPrimaryFill, t)!,
      statusOnline: Color.lerp(statusOnline, other.statusOnline, t)!,
      statusIdle: Color.lerp(statusIdle, other.statusIdle, t)!,
      statusDnd: Color.lerp(statusDnd, other.statusDnd, t)!,
      statusOffline: Color.lerp(statusOffline, other.statusOffline, t)!,
      statusDanger: Color.lerp(statusDanger, other.statusDanger, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textPrimaryMuted: Color.lerp(textPrimaryMuted, other.textPrimaryMuted, t)!,
      textChat: Color.lerp(textChat, other.textChat, t)!,
      textChatMuted: Color.lerp(textChatMuted, other.textChatMuted, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      textOnBrandPrimary: Color.lerp(textOnBrandPrimary, other.textOnBrandPrimary, t)!,
      textTertiaryMuted: Color.lerp(textTertiaryMuted, other.textTertiaryMuted, t)!,
      textTertiarySecondary: Color.lerp(textTertiarySecondary, other.textTertiarySecondary, t)!,
      textWarning: Color.lerp(textWarning, other.textWarning, t)!,
      textDanger: Color.lerp(textDanger, other.textDanger, t)!,
      textPositive: Color.lerp(textPositive, other.textPositive, t)!,
      textCode: Color.lerp(textCode, other.textCode, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      borderColorHover: Color.lerp(borderColorHover, other.borderColorHover, t)!,
      borderColorFocus: Color.lerp(borderColorFocus, other.borderColorFocus, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      accentDanger: Color.lerp(accentDanger, other.accentDanger, t)!,
      accentInfo: Color.lerp(accentInfo, other.accentInfo, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      alertNote: Color.lerp(alertNote, other.alertNote, t)!,
      alertTip: Color.lerp(alertTip, other.alertTip, t)!,
      alertImportant: Color.lerp(alertImportant, other.alertImportant, t)!,
      alertWarning: Color.lerp(alertWarning, other.alertWarning, t)!,
      alertCaution: Color.lerp(alertCaution, other.alertCaution, t)!,
      markupMentionText: Color.lerp(markupMentionText, other.markupMentionText, t)!,
      markupMentionFill: Color.lerp(markupMentionFill, other.markupMentionFill, t)!,
      markupInteractiveHoverText: Color.lerp(markupInteractiveHoverText, other.markupInteractiveHoverText, t)!,
      markupInteractiveHoverFill: Color.lerp(markupInteractiveHoverFill, other.markupInteractiveHoverFill, t)!,
      buttonPrimaryFill: Color.lerp(buttonPrimaryFill, other.buttonPrimaryFill, t)!,
      buttonPrimaryActiveFill: Color.lerp(buttonPrimaryActiveFill, other.buttonPrimaryActiveFill, t)!,
      buttonPrimaryText: Color.lerp(buttonPrimaryText, other.buttonPrimaryText, t)!,
      buttonSecondaryFill: Color.lerp(buttonSecondaryFill, other.buttonSecondaryFill, t)!,
      buttonSecondaryActiveFill: Color.lerp(buttonSecondaryActiveFill, other.buttonSecondaryActiveFill, t)!,
      buttonSecondaryText: Color.lerp(buttonSecondaryText, other.buttonSecondaryText, t)!,
      buttonSecondaryActiveText: Color.lerp(buttonSecondaryActiveText, other.buttonSecondaryActiveText, t)!,
      buttonDangerFill: Color.lerp(buttonDangerFill, other.buttonDangerFill, t)!,
      buttonDangerActiveFill: Color.lerp(buttonDangerActiveFill, other.buttonDangerActiveFill, t)!,
      buttonDangerText: Color.lerp(buttonDangerText, other.buttonDangerText, t)!,
      buttonDangerOutlineBorder: Color.lerp(buttonDangerOutlineBorder, other.buttonDangerOutlineBorder, t)!,
      buttonDangerOutlineText: Color.lerp(buttonDangerOutlineText, other.buttonDangerOutlineText, t)!,
      buttonDangerOutlineActiveFill: Color.lerp(buttonDangerOutlineActiveFill, other.buttonDangerOutlineActiveFill, t)!,
      buttonGhostText: Color.lerp(buttonGhostText, other.buttonGhostText, t)!,
      buttonInvertedFill: Color.lerp(buttonInvertedFill, other.buttonInvertedFill, t)!,
      buttonInvertedText: Color.lerp(buttonInvertedText, other.buttonInvertedText, t)!,
      buttonOutlineBorder: Color.lerp(buttonOutlineBorder, other.buttonOutlineBorder, t)!,
      buttonOutlineText: Color.lerp(buttonOutlineText, other.buttonOutlineText, t)!,
      buttonOutlineActiveFill: Color.lerp(buttonOutlineActiveFill, other.buttonOutlineActiveFill, t)!,
      bgCode: Color.lerp(bgCode, other.bgCode, t)!,
      bgCodeBlock: Color.lerp(bgCodeBlock, other.bgCodeBlock, t)!,
      bgBlockquote: Color.lerp(bgBlockquote, other.bgBlockquote, t)!,
      bgTableHeader: Color.lerp(bgTableHeader, other.bgTableHeader, t)!,
      bgTableRowOdd: Color.lerp(bgTableRowOdd, other.bgTableRowOdd, t)!,
      bgTableRowEven: Color.lerp(bgTableRowEven, other.bgTableRowEven, t)!,
      surfaceInteractiveHoverBg: Color.lerp(surfaceInteractiveHoverBg, other.surfaceInteractiveHoverBg, t)!,
      surfaceInteractiveSelectedBg: Color.lerp(surfaceInteractiveSelectedBg, other.surfaceInteractiveSelectedBg, t)!,
      surfaceInteractiveSelectedColor: Color.lerp(surfaceInteractiveSelectedColor, other.surfaceInteractiveSelectedColor, t)!,
      scrollbarThumbBg: Color.lerp(scrollbarThumbBg, other.scrollbarThumbBg, t)!,
      scrollbarThumbBgHover: Color.lerp(scrollbarThumbBgHover, other.scrollbarThumbBgHover, t)!,
      scrollbarTrackBg: Color.lerp(scrollbarTrackBg, other.scrollbarTrackBg, t)!,
      chatBackground: Color.lerp(chatBackground, other.chatBackground, t)!,
      chatInputBackground: Color.lerp(chatInputBackground, other.chatInputBackground, t)!,
      serverSidebarBackground: Color.lerp(serverSidebarBackground, other.serverSidebarBackground, t)!,
      serverIconBackground: Color.lerp(serverIconBackground, other.serverIconBackground, t)!,
      serverIconActive: Color.lerp(serverIconActive, other.serverIconActive, t)!,
      channelSidebarBackground: Color.lerp(channelSidebarBackground, other.channelSidebarBackground, t)!,
      memberListBackground: Color.lerp(memberListBackground, other.memberListBackground, t)!,
      userPanelBackground: Color.lerp(userPanelBackground, other.userPanelBackground, t)!,
      embedBackground: Color.lerp(embedBackground, other.embedBackground, t)!,
      embedBorder: Color.lerp(embedBorder, other.embedBorder, t)!,
      mentionBackground: Color.lerp(mentionBackground, other.mentionBackground, t)!,
      spoilerBackground: Color.lerp(spoilerBackground, other.spoilerBackground, t)!,
      focusPrimary: Color.lerp(focusPrimary, other.focusPrimary, t)!,
      interactiveActive: Color.lerp(interactiveActive, other.interactiveActive, t)!,
      interactiveNormal: Color.lerp(interactiveNormal, other.interactiveNormal, t)!,
      interactiveHover: Color.lerp(interactiveHover, other.interactiveHover, t)!,
      interactiveMuted: Color.lerp(interactiveMuted, other.interactiveMuted, t)!,
    );
  }
}
```

Note: This is a large file (~500 lines). The `copyWith` and `lerp` methods are mechanical but required for ThemeExtension to work. Each field maps 1:1 to a web app CSS token.

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/fluxer_color_theme.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/fluxer_color_theme.dart
git commit -m "feat(theme): add FluxerColorTheme ThemeExtension with ~90 tokens"
```

---

### Task 4: Dark Theme Definition

**Files:**
- Create: `lib/core/theme/themes/dark.dart`

**Step 1: Define the dark theme using the color generator**

Use the exact values from `GenerateColorSystem.tsx` CONFIG (root tokens). The dark theme uses:
- `darkSurface` scale: neutralDark, L 5→26%, easeOut
- `darkText` scale: neutralDark, L 52→96%, easeInOut

For scale-generated tokens, use `ColorScale.build()`. For individual tone tokens, use `generateTone()`. For alias tokens (web app uses `var(--other-token)`), reference the already-computed values.

```dart
import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/color_families.dart';
import 'package:fluxeron/core/theme/color_generator.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';

FluxerColorTheme buildDarkColorTheme({double saturationFactor = 1.0}) {
  // ── Generate scale tokens ──
  final darkSurface = ColorScale(
    family: FluxerColorFamilies.neutralDark,
    lightnessStart: 5,
    lightnessEnd: 26,
    curve: Curves.easeOut,
    stops: const [
      ScaleStop('backgroundPrimary', position: 0),
      ScaleStop('backgroundSecondary', position: 0.16),
      ScaleStop('backgroundSecondaryAlt', position: 0.28),
      ScaleStop('backgroundTertiary', position: 0.4),
      ScaleStop('backgroundChannelHeader', position: 0.34),
      ScaleStop('guildListForeground', position: 0.38),
      ScaleStop('backgroundHeaderSecondary', position: 0.5),
      ScaleStop('backgroundHeaderPrimary', position: 0.5),
      ScaleStop('backgroundTextarea', position: 0.68),
      ScaleStop('backgroundHeaderPrimaryHover', position: 0.85),
    ],
  ).build(saturationFactor: saturationFactor);

  final darkText = ColorScale(
    family: FluxerColorFamilies.neutralDark,
    lightnessStart: 52,
    lightnessEnd: 96,
    curve: Curves.easeInOut,
    stops: const [
      ScaleStop('textTertiarySecondary', position: 0),
      ScaleStop('textTertiaryMuted', position: 0.2),
      ScaleStop('textTertiary', position: 0.38),
      ScaleStop('textPrimaryMuted', position: 0.55),
      ScaleStop('textChatMuted', position: 0.55),
      ScaleStop('textSecondary', position: 0.72),
      ScaleStop('textChat', position: 0.82),
      ScaleStop('textPrimary', position: 1),
    ],
  ).build(saturationFactor: saturationFactor);

  // ── Helper for individual tones ──
  Color tone(ColorFamily family, double lightness, {double alpha = 1.0, double? saturation}) {
    return generateTone(
      hue: family.hue,
      saturation: saturation ?? family.saturation,
      lightness: lightness,
      alpha: alpha,
      saturationFactor: saturationFactor,
      useSaturationFactor: family.useSaturationFactor,
    );
  }

  Color toneDirect({required double hue, required double saturation, required double lightness, double alpha = 1.0, bool useSatFactor = true}) {
    return generateTone(
      hue: hue, saturation: saturation, lightness: lightness, alpha: alpha,
      saturationFactor: saturationFactor, useSaturationFactor: useSatFactor,
    );
  }

  final f = FluxerColorFamilies;

  // ── Precompute referenced tokens ──
  final brandPrimary = tone(f.brand, 55);
  final statusOnline = tone(f.statusOnline, 40);
  final statusIdle = tone(f.statusIdle, 50);
  final statusDnd = tone(f.statusDnd, 60);
  final textLink = tone(f.link, 70);

  return FluxerColorTheme(
    // Background
    backgroundPrimary: darkSurface['backgroundPrimary']!,
    backgroundSecondary: darkSurface['backgroundSecondary']!,
    backgroundSecondaryAlt: darkSurface['backgroundSecondaryAlt']!,
    backgroundTertiary: darkSurface['backgroundTertiary']!,
    backgroundTextarea: darkSurface['backgroundTextarea']!,
    backgroundHeaderPrimary: darkSurface['backgroundHeaderPrimary']!,
    backgroundHeaderPrimaryHover: darkSurface['backgroundHeaderPrimaryHover']!,
    backgroundHeaderSecondary: darkSurface['backgroundHeaderSecondary']!,
    backgroundChannelHeader: darkSurface['backgroundChannelHeader']!,
    backgroundFloating: toneDirect(hue: 220, saturation: 13, lightness: 3),
    guildListForeground: darkSurface['guildListForeground']!,
    backgroundModifierHover: toneDirect(hue: 220, saturation: 13, lightness: 100, alpha: 0.05),
    backgroundModifierSelected: toneDirect(hue: 220, saturation: 13, lightness: 100, alpha: 0.1),
    backgroundModifierAccent: toneDirect(hue: 220, saturation: 13, lightness: 80, alpha: 0.15),
    backgroundModifierAccentFocus: toneDirect(hue: 220, saturation: 13, lightness: 80, alpha: 0.22),

    // Brand
    brandPrimary: brandPrimary,
    brandSecondary: tone(f.brand, 49, saturation: 60),
    brandPrimaryLight: toneDirect(hue: 242, saturation: 100, lightness: 84),
    brandPrimaryFill: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),

    // Status
    statusOnline: statusOnline,
    statusIdle: statusIdle,
    statusDnd: statusDnd,
    statusOffline: tone(f.statusOffline, 65),
    statusDanger: tone(f.statusDanger, 55),

    // Text
    textPrimary: darkText['textPrimary']!,
    textSecondary: darkText['textSecondary']!,
    textTertiary: darkText['textTertiary']!,
    textPrimaryMuted: darkText['textPrimaryMuted']!,
    textChat: darkText['textChat']!,
    textChatMuted: darkText['textChatMuted']!,
    textLink: textLink,
    textOnBrandPrimary: toneDirect(hue: 0, saturation: 0, lightness: 98, useSatFactor: false),
    textTertiaryMuted: darkText['textTertiaryMuted']!,
    textTertiarySecondary: darkText['textTertiarySecondary']!,
    textWarning: tone(f.statusIdle, 55),
    textDanger: tone(f.statusDanger, 55),
    textPositive: statusOnline,
    textCode: tone(f.textCode, 90),

    // Border
    borderColor: toneDirect(hue: 220, saturation: 13, lightness: 50, alpha: 0.2),
    borderColorHover: toneDirect(hue: 220, saturation: 13, lightness: 50, alpha: 0.3),
    borderColorFocus: toneDirect(hue: 210, saturation: 90, lightness: 70, alpha: 0.45),

    // Accent
    accentPrimary: brandPrimary,
    accentSuccess: statusOnline,
    accentWarning: statusIdle,
    accentDanger: statusDnd,
    accentInfo: textLink,
    accentPurple: tone(f.accentPurple, 65),

    // Alert
    alertNote: tone(f.link, 70),
    alertTip: tone(f.statusOnline, 45),
    alertImportant: tone(f.accentPurple, 65),
    alertWarning: tone(f.statusIdle, 55),
    alertCaution: toneDirect(hue: 359, saturation: 75, lightness: 60),

    // Markup
    markupMentionText: textLink,
    markupMentionFill: textLink.withValues(alpha: 0.2),
    markupInteractiveHoverText: textLink,
    markupInteractiveHoverFill: textLink.withValues(alpha: 0.3),

    // Button
    buttonPrimaryFill: toneDirect(hue: 139, saturation: 55, lightness: 44),
    buttonPrimaryActiveFill: toneDirect(hue: 136, saturation: 60, lightness: 38),
    buttonPrimaryText: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonSecondaryFill: toneDirect(hue: 0, saturation: 0, lightness: 100, alpha: 0.1, useSatFactor: false),
    buttonSecondaryActiveFill: toneDirect(hue: 0, saturation: 0, lightness: 100, alpha: 0.15, useSatFactor: false),
    buttonSecondaryText: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonSecondaryActiveText: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonDangerFill: toneDirect(hue: 359, saturation: 70, lightness: 54),
    buttonDangerActiveFill: toneDirect(hue: 359, saturation: 65, lightness: 45),
    buttonDangerText: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonDangerOutlineBorder: toneDirect(hue: 359, saturation: 70, lightness: 54),
    buttonDangerOutlineText: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonDangerOutlineActiveFill: toneDirect(hue: 359, saturation: 65, lightness: 48),
    buttonGhostText: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonInvertedFill: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonInvertedText: toneDirect(hue: 0, saturation: 0, lightness: 0, useSatFactor: false),
    buttonOutlineBorder: toneDirect(hue: 0, saturation: 0, lightness: 100, alpha: 0.3, useSatFactor: false),
    buttonOutlineText: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    buttonOutlineActiveFill: toneDirect(hue: 0, saturation: 0, lightness: 100, alpha: 0.15, useSatFactor: false),

    // Content Background
    bgCode: toneDirect(hue: 220, saturation: 13, lightness: 15, alpha: 0.8),
    bgCodeBlock: darkSurface['backgroundSecondaryAlt']!,
    bgBlockquote: darkSurface['backgroundSecondaryAlt']!,
    bgTableHeader: darkSurface['backgroundTertiary']!,
    bgTableRowOdd: darkSurface['backgroundPrimary']!,
    bgTableRowEven: darkSurface['backgroundSecondary']!,

    // Interactive Surface
    surfaceInteractiveHoverBg: toneDirect(hue: 220, saturation: 13, lightness: 100, alpha: 0.05),
    surfaceInteractiveSelectedBg: toneDirect(hue: 220, saturation: 13, lightness: 100, alpha: 0.1),
    surfaceInteractiveSelectedColor: darkText['textPrimary']!,

    // Scrollbar
    scrollbarThumbBg: const Color(0x66797A7C),
    scrollbarThumbBgHover: const Color(0xB3797A7C),
    scrollbarTrackBg: Colors.transparent,

    // UI-specific (aliases)
    chatBackground: darkSurface['backgroundSecondary']!,
    chatInputBackground: darkSurface['backgroundSecondary']!,
    serverSidebarBackground: darkSurface['backgroundSecondary']!,
    serverIconBackground: darkSurface['backgroundTertiary']!,
    serverIconActive: brandPrimary,
    channelSidebarBackground: darkSurface['backgroundSecondary']!,
    memberListBackground: darkSurface['backgroundSecondary']!,
    userPanelBackground: toneDirect(hue: 220, saturation: 13, lightness: 10),
    embedBackground: darkSurface['backgroundSecondary']!,
    embedBorder: toneDirect(hue: 220, saturation: 13, lightness: 50, alpha: 0.2),
    mentionBackground: toneDirect(hue: 220, saturation: 13, lightness: 80, alpha: 0.15),
    spoilerBackground: toneDirect(hue: 220, saturation: 13, lightness: 8),
    focusPrimary: const Color(0xFF00B0F4),
    interactiveActive: toneDirect(hue: 0, saturation: 0, lightness: 100, useSatFactor: false),
    interactiveNormal: darkText['textSecondary']!,
    interactiveHover: darkText['textPrimary']!,
    interactiveMuted: toneDirect(hue: 228, saturation: 10, lightness: 35),
  );
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/themes/dark.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/themes/dark.dart
git commit -m "feat(theme): add dark theme definition using color generator"
```

---

### Task 5: Light Theme Definition

**Files:**
- Create: `lib/core/theme/themes/light.dart`

**Step 1: Define the light theme**

Uses `lightSurface` scale (neutralLight, L 86→98.5%, easeIn) and `lightText` scale (neutralLight, L 15→60%, easeOut). Override tokens from `GenerateColorSystem.tsx` CONFIG.tokens.light. Tokens not overridden in the light section inherit from the root (dark) section — but since we build complete themes, each theme must supply all values.

Follow the exact same pattern as `dark.dart` but with:
- `lightSurface` scale: neutralLight, L 86→98.5%, easeIn, stops from CONFIG lines 134-146
- `lightText` scale: neutralLight, L 15→60%, easeOut, stops from CONFIG lines 153-161
- Override tokens from CONFIG.tokens.light (lines 328-419)
- Status colors adjusted: online L40→L40 sat70, idle L50→L45 sat90, dnd L60→L50 hue359 sat70, offline L65→L55 hue210 sat10
- Text link L70→L45, text code L90→L45
- Button secondary/ghost/inverted/outline all use neutralLight family
- Modifier alphas differ (hover 0.05→0.05, selected 0.1→0.1, accent 0.15→0.22, accentFocus 0.22→0.32)
- Brightness is `Brightness.light`

```dart
import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/color_families.dart';
import 'package:fluxeron/core/theme/color_generator.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';

FluxerColorTheme buildLightColorTheme({double saturationFactor = 1.0}) {
  // Follow same structure as dark.dart but with lightSurface/lightText scales
  // and all overrides from CONFIG.tokens.light
  // ... (implement using exact values from GenerateColorSystem.tsx lines 328-419)
}
```

The implementing agent should reference the dark theme file and `GenerateColorSystem.tsx` lines 130-162 (light scales) and 328-419 (light overrides) to build the complete theme.

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/themes/light.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/themes/light.dart
git commit -m "feat(theme): add light theme definition"
```

---

### Task 6: Coal Theme Definition

**Files:**
- Create: `lib/core/theme/themes/coal.dart`

**Step 1: Define the coal theme**

Coal uses `coalSurface` scale (neutralDark, L 1→12%, easeOut) with dark text scale unchanged. Override tokens from CONFIG.tokens.coal (lines 421-471). Key differences from dark:
- Surface range is much narrower and darker (1-12% vs 5-26%)
- `backgroundSecondary` aliased to `backgroundPrimary` (flat surfaces)
- Modifier alphas are lower (hover 0.04, selected 0.08)
- Button secondary fills are even more transparent (0.04, 0.07)
- Scrollbar colors adjusted for higher contrast on dark bg

The implementing agent should reference `GenerateColorSystem.tsx` lines 98-113 (coalSurface scale) and 421-471 (coal overrides).

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/themes/coal.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/themes/coal.dart
git commit -m "feat(theme): add coal/AMOLED theme definition"
```

---

### Task 7: FluxerTextTheme ThemeExtension

**Files:**
- Create: `lib/core/theme/fluxer_text_theme.dart`

**Step 1: Create the text theme extension**

Text styles reference colors from `FluxerColorTheme`, so they must be built per-theme. Font family and sizes stay constant; only colors change.

```dart
import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FluxerTextTheme extends ThemeExtension<FluxerTextTheme> {
  final TextStyle heading;
  final TextStyle channelName;
  final TextStyle username;
  final TextStyle messageText;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle timestamp;
  final TextStyle smallText;
  final TextStyle categoryName;
  final TextStyle inputText;
  final TextStyle inputHint;
  final TextStyle embedTitle;
  final TextStyle embedDescription;
  final TextStyle embedFooter;

  const FluxerTextTheme({
    required this.heading,
    required this.channelName,
    required this.username,
    required this.messageText,
    required this.bodyMedium,
    required this.bodySmall,
    required this.label,
    required this.timestamp,
    required this.smallText,
    required this.categoryName,
    required this.inputText,
    required this.inputHint,
    required this.embedTitle,
    required this.embedDescription,
    required this.embedFooter,
  });

  /// Build a text theme from the given color theme.
  factory FluxerTextTheme.fromColors(FluxerColorTheme colors) {
    final fontFamily = GoogleFonts.ibmPlexSans().fontFamily!;

    return FluxerTextTheme(
      heading: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary),
      channelName: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
      username: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: colors.textPrimary),
      messageText: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textChat, height: 1.375),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimaryMuted),
      label: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
      timestamp: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textPrimaryMuted),
      smallText: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimaryMuted, letterSpacing: 0.02),
      categoryName: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimaryMuted, letterSpacing: 0.5),
      inputText: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textChat),
      inputHint: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textChatMuted),
      embedTitle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: colors.textLink),
      embedDescription: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textChat, height: 1.3),
      embedFooter: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textPrimaryMuted),
    );
  }

  @override
  FluxerTextTheme copyWith({
    TextStyle? heading,
    TextStyle? channelName,
    TextStyle? username,
    TextStyle? messageText,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? timestamp,
    TextStyle? smallText,
    TextStyle? categoryName,
    TextStyle? inputText,
    TextStyle? inputHint,
    TextStyle? embedTitle,
    TextStyle? embedDescription,
    TextStyle? embedFooter,
  }) {
    return FluxerTextTheme(
      heading: heading ?? this.heading,
      channelName: channelName ?? this.channelName,
      username: username ?? this.username,
      messageText: messageText ?? this.messageText,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
      timestamp: timestamp ?? this.timestamp,
      smallText: smallText ?? this.smallText,
      categoryName: categoryName ?? this.categoryName,
      inputText: inputText ?? this.inputText,
      inputHint: inputHint ?? this.inputHint,
      embedTitle: embedTitle ?? this.embedTitle,
      embedDescription: embedDescription ?? this.embedDescription,
      embedFooter: embedFooter ?? this.embedFooter,
    );
  }

  @override
  FluxerTextTheme lerp(FluxerTextTheme? other, double t) {
    if (other is! FluxerTextTheme) return this;
    return FluxerTextTheme(
      heading: TextStyle.lerp(heading, other.heading, t)!,
      channelName: TextStyle.lerp(channelName, other.channelName, t)!,
      username: TextStyle.lerp(username, other.username, t)!,
      messageText: TextStyle.lerp(messageText, other.messageText, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      timestamp: TextStyle.lerp(timestamp, other.timestamp, t)!,
      smallText: TextStyle.lerp(smallText, other.smallText, t)!,
      categoryName: TextStyle.lerp(categoryName, other.categoryName, t)!,
      inputText: TextStyle.lerp(inputText, other.inputText, t)!,
      inputHint: TextStyle.lerp(inputHint, other.inputHint, t)!,
      embedTitle: TextStyle.lerp(embedTitle, other.embedTitle, t)!,
      embedDescription: TextStyle.lerp(embedDescription, other.embedDescription, t)!,
      embedFooter: TextStyle.lerp(embedFooter, other.embedFooter, t)!,
    );
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/fluxer_text_theme.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/fluxer_text_theme.dart
git commit -m "feat(theme): add FluxerTextTheme ThemeExtension with expanded presets"
```

---

### Task 8: FluxerLayoutTheme (Spacing, Radius, Layout Dimensions)

**Files:**
- Create: `lib/core/theme/fluxer_layout_theme.dart`

**Step 1: Create the layout theme extension with scaled values**

```dart
import 'package:flutter/material.dart';

/// Scaled spacing, radius, and layout dimension tokens.
///
/// All base values are multiplied by [scaleFactor] at construction time.
/// Access via `context.layout`.
class FluxerLayoutTheme extends ThemeExtension<FluxerLayoutTheme> {
  final double scaleFactor;

  // ── Spacing ──
  final double s0;
  final double s1;
  final double s1_5;
  final double s2;
  final double s3;
  final double s4;
  final double s5;
  final double s6;
  final double s8;
  final double s10;
  final double s12;
  final double s16;
  final double s20;
  final double s24;

  // ── Radius ──
  final BorderRadius radiusSm;
  final BorderRadius radiusMd;
  final BorderRadius radiusLg;
  final BorderRadius radiusXl;
  final BorderRadius radiusXxl;
  final BorderRadius radiusFull;
  final BorderRadius radiusMedia;

  // ── Layout Dimensions ──
  final double sidebarWidth;
  final double headerHeight;
  final double guildIconSize;
  final double guildListWidth;
  final double mobileBottomNavHeight;
  final double userAreaHeight;

  const FluxerLayoutTheme({
    required this.scaleFactor,
    required this.s0,
    required this.s1,
    required this.s1_5,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.s5,
    required this.s6,
    required this.s8,
    required this.s10,
    required this.s12,
    required this.s16,
    required this.s20,
    required this.s24,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusXxl,
    required this.radiusFull,
    required this.radiusMedia,
    required this.sidebarWidth,
    required this.headerHeight,
    required this.guildIconSize,
    required this.guildListWidth,
    required this.mobileBottomNavHeight,
    required this.userAreaHeight,
  });

  /// Build a layout theme with the given scale factor.
  factory FluxerLayoutTheme.scaled({double scaleFactor = 1.0}) {
    double s(double base) => base * scaleFactor;
    BorderRadius r(double base) => BorderRadius.all(Radius.circular(base * scaleFactor));

    return FluxerLayoutTheme(
      scaleFactor: scaleFactor,
      s0: 0,
      s1: s(4),
      s1_5: s(6),
      s2: s(8),
      s3: s(12),
      s4: s(16),
      s5: s(20),
      s6: s(24),
      s8: s(32),
      s10: s(40),
      s12: s(48),
      s16: s(64),
      s20: s(80),
      s24: s(96),
      radiusSm: r(4),
      radiusMd: r(6),
      radiusLg: r(8),
      radiusXl: r(12),
      radiusXxl: r(16),
      radiusFull: r(9999),
      radiusMedia: r(4),
      sidebarWidth: s(270),
      headerHeight: s(56),
      guildIconSize: s(44),
      guildListWidth: s(72),
      mobileBottomNavHeight: s(60),
      userAreaHeight: s(72),
    );
  }

  @override
  FluxerLayoutTheme copyWith({double? scaleFactor}) {
    if (scaleFactor != null && scaleFactor != this.scaleFactor) {
      return FluxerLayoutTheme.scaled(scaleFactor: scaleFactor);
    }
    return this;
  }

  @override
  FluxerLayoutTheme lerp(FluxerLayoutTheme? other, double t) {
    if (other is! FluxerLayoutTheme) return this;
    final newScale = (scaleFactor + (other.scaleFactor - scaleFactor) * t);
    return FluxerLayoutTheme.scaled(scaleFactor: newScale);
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/fluxer_layout_theme.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/fluxer_layout_theme.dart
git commit -m "feat(theme): add FluxerLayoutTheme with scaled spacing, radius, and layout dimensions"
```

---

### Task 9: Context Extension + Theme Assembler

**Files:**
- Create: `lib/core/theme/fluxer_theme_extension.dart`
- Modify: `lib/core/theme/fluxer_theme.dart`

**Step 1: Create the context extension**

```dart
import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';

extension FluxerThemeX on BuildContext {
  FluxerColorTheme get colors => Theme.of(this).extension<FluxerColorTheme>()!;
  FluxerTextTheme get textStyles => Theme.of(this).extension<FluxerTextTheme>()!;
  FluxerLayoutTheme get layout => Theme.of(this).extension<FluxerLayoutTheme>()!;
}
```

**Step 2: Rewrite `fluxer_theme.dart` to accept theme parameters**

Replace the existing `buildFluxerTheme()` with a version that takes a `FluxerColorTheme`, `FluxerTextTheme`, and `FluxerLayoutTheme`:

```dart
import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';

/// Build Fluxer-styled ThemeData from the given theme extensions.
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
      secondary: colorTheme.brandPrimary,
      onSecondary: colorTheme.textOnBrandPrimary,
      surface: colorTheme.backgroundPrimary,
      onSurface: colorTheme.textChat,
      error: colorTheme.accentDanger,
      onError: colorTheme.textOnBrandPrimary,
    ),
    textTheme: TextTheme(
      bodyLarge: textTheme.messageText,
      bodyMedium: textTheme.bodyMedium,
      titleLarge: textTheme.heading,
      labelSmall: textTheme.smallText,
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
        backgroundColor: colorTheme.brandPrimary,
        foregroundColor: colorTheme.textOnBrandPrimary,
        disabledBackgroundColor: colorTheme.brandPrimary.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: layoutTheme.radiusLg),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorTheme.textLink,
        shape: RoundedRectangleBorder(borderRadius: layoutTheme.radiusLg),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorTheme.textChat,
        shape: RoundedRectangleBorder(borderRadius: layoutTheme.radiusLg),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorTheme.backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: layoutTheme.radiusLg,
        borderSide: BorderSide(color: colorTheme.backgroundModifierAccent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: layoutTheme.radiusLg,
        borderSide: BorderSide(color: colorTheme.backgroundModifierAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: layoutTheme.radiusLg,
        borderSide: BorderSide(color: colorTheme.brandPrimary),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: layoutTheme.s3,
        vertical: layoutTheme.s2 + 2,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colorTheme.backgroundFloating,
        borderRadius: layoutTheme.radiusSm,
      ),
      textStyle: textTheme.bodySmall.copyWith(color: colorTheme.textChat),
    ),
  );
}
```

**Step 3: Verify both files compile**

Run: `flutter analyze lib/core/theme/fluxer_theme_extension.dart lib/core/theme/fluxer_theme.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/core/theme/fluxer_theme_extension.dart lib/core/theme/fluxer_theme.dart
git commit -m "feat(theme): add context extension and update theme assembler"
```

---

### Task 10: FluxerThemeMode Enum + Wire Into App

**Files:**
- Create: `lib/core/theme/fluxer_theme_mode.dart`
- Modify: `lib/app.dart:24`

**Step 1: Create the theme mode enum**

```dart
enum FluxerThemeMode {
  dark,
  light,
  coal,
}
```

**Step 2: Update `app.dart` to use the new theme system**

Replace line 24 (`theme: buildFluxerTheme()`) with the new system. For now, hardcode dark theme — persistence comes in Task 12.

```dart
// In app.dart, replace the import:
// OLD: import 'package:fluxeron/core/theme/fluxer_theme.dart';
// NEW:
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/core/theme/themes/dark.dart';

// Replace line 24:
// OLD: theme: buildFluxerTheme(),
// NEW:
theme: () {
  final colorTheme = buildDarkColorTheme();
  return buildFluxerTheme(
    colorTheme: colorTheme,
    textTheme: FluxerTextTheme.fromColors(colorTheme),
    layoutTheme: FluxerLayoutTheme.scaled(),
  );
}(),
```

**Step 3: Verify the app compiles and runs**

Run: `flutter analyze`
Expected: No issues in new theme files (existing files may have warnings from old FluxerColors usage — that's expected)

**Step 4: Commit**

```bash
git add lib/core/theme/fluxer_theme_mode.dart lib/app.dart
git commit -m "feat(theme): wire new theme system into app with dark theme default"
```

---

### Task 11: Color Utilities + Accent Color

**Files:**
- Create: `lib/core/theme/color_utils.dart`

**Step 1: Create the color utility and accent color helper**

```dart
import 'dart:ui';

/// Port of the web app's ColorUtils.tsx + AccentColorUtils.tsx.
abstract final class ColorUtils {
  /// Convert a 24-bit integer color (0xRRGGBB) to a Color.
  static Color fromInt(int colorInt) {
    final r = (colorInt >> 16) & 0xFF;
    final g = (colorInt >> 8) & 0xFF;
    final b = colorInt & 0xFF;
    return Color.fromARGB(255, r, g, b);
  }

  /// WCAG luminance calculation. Returns black or white for best contrast.
  static Color bestContrastColor(int colorInt) {
    final r = ((colorInt >> 16) & 0xFF) / 255;
    final g = ((colorInt >> 8) & 0xFF) / 255;
    final b = (colorInt & 0xFF) / 255;
    final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    return luminance > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  /// Dim a color by multiplying RGB by (1 - amount).
  static Color dim(Color color, double amount) {
    final factor = (1 - amount).clamp(0.0, 1.0);
    return Color.fromARGB(
      color.alpha.toInt(),
      (color.r * factor * 255).round().clamp(0, 255),
      (color.g * factor * 255).round().clamp(0, 255),
      (color.b * factor * 255).round().clamp(0, 255),
    );
  }
}

/// Default avatar color palette (matches web app).
abstract final class AccentColorUtils {
  static const defaultPalette = [
    Color(0xFF5865F2),
    Color(0xFF57F287),
    Color(0xFFFEE75C),
    Color(0xFFEB459E),
    Color(0xFFED4245),
  ];

  /// Resolve accent color with fallback chain:
  /// profileAccentColor → avatarColor → defaultColorByUserId
  static Color resolve({
    int? profileAccentColor,
    int? avatarColor,
    required String userId,
  }) {
    if (profileAccentColor != null) {
      return ColorUtils.fromInt(profileAccentColor);
    }
    if (avatarColor != null) {
      return ColorUtils.fromInt(avatarColor);
    }
    final index = userId.hashCode.abs() % defaultPalette.length;
    return defaultPalette[index];
  }
}
```

**Step 2: Verify it compiles**

Run: `flutter analyze lib/core/theme/color_utils.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/color_utils.dart
git commit -m "feat(theme): add ColorUtils and AccentColorUtils"
```

---

### Task 12: Drift UserPreferences Table + DAO

**Files:**
- Create: `lib/core/database/tables/user_preferences.dart`
- Create: `lib/core/database/daos/user_preferences_dao.dart`
- Modify: `lib/core/database/fluxer_database.dart:32-56` (add table + DAO)
- Modify: `lib/core/database/fluxer_database.dart:64` (schema version 2 → 3)
- Modify: `lib/core/database/fluxer_database.dart:69-107` (add migration)

**Step 1: Create the table**

```dart
import 'package:drift/drift.dart';

class UserPreferencesTable extends Table {
  TextColumn get userId => text()();
  TextColumn get theme => text().withDefault(const Constant('dark'))();
  RealColumn get scaleFactor => real().withDefault(const Constant(1.0))();

  @override
  String get tableName => 'user_preferences';

  @override
  Set<Column> get primaryKey => {userId};
}
```

**Step 2: Create the DAO**

```dart
import 'package:drift/drift.dart';
import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/database/tables/user_preferences.dart';

part 'user_preferences_dao.g.dart';

@DriftAccessor(tables: [UserPreferencesTable])
class UserPreferencesDao extends DatabaseAccessor<FluxerDatabase>
    with _$UserPreferencesDaoMixin {
  UserPreferencesDao(super.attachedDatabase);

  Future<UserPreference?> getPreferences(String userId) =>
      (select(userPreferencesTable)..where((t) => t.userId.equals(userId)))
          .getSingleOrNull();

  Future<void> savePreferences(UserPreferencesTableCompanion prefs) =>
      into(userPreferencesTable).insertOnConflictUpdate(prefs);
}
```

**Step 3: Add table and DAO to `fluxer_database.dart`**

Add `UserPreferencesTable` to the `tables` list and `UserPreferencesDao` to the `daos` list. Bump `schemaVersion` to 3. Add migration:

```dart
if (from < 3) {
  await m.createTable(userPreferencesTable);
}
```

**Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `fluxer_database.g.dart`, `user_preferences_dao.g.dart`

**Step 5: Verify it compiles**

Run: `flutter analyze`
Expected: No issues in database files

**Step 6: Commit**

```bash
git add lib/core/database/tables/user_preferences.dart lib/core/database/daos/user_preferences_dao.dart lib/core/database/fluxer_database.dart lib/core/database/fluxer_database.g.dart lib/core/database/daos/user_preferences_dao.g.dart
git commit -m "feat(theme): add UserPreferences Drift table and DAO for theme persistence"
```

---

### Task 13: Theme Preference Provider

**Files:**
- Create: `lib/core/theme/providers/theme_preference_provider.dart`

**Step 1: Create the Riverpod provider**

```dart
import 'package:drift/drift.dart';
import 'package:fluxeron/core/database/tables/user_preferences.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme_mode.dart';
import 'package:fluxeron/core/theme/themes/coal.dart';
import 'package:fluxeron/core/theme/themes/dark.dart';
import 'package:fluxeron/core/theme/themes/light.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_preference_provider.g.dart';

class ThemePreferenceState {
  final FluxerThemeMode mode;
  final double scaleFactor;

  const ThemePreferenceState({
    this.mode = FluxerThemeMode.dark,
    this.scaleFactor = 1.0,
  });

  FluxerColorTheme get colorTheme {
    return switch (mode) {
      FluxerThemeMode.dark => buildDarkColorTheme(),
      FluxerThemeMode.light => buildLightColorTheme(),
      FluxerThemeMode.coal => buildCoalColorTheme(),
    };
  }

  FluxerTextTheme get textTheme => FluxerTextTheme.fromColors(colorTheme);
  FluxerLayoutTheme get layoutTheme => FluxerLayoutTheme.scaled(scaleFactor: scaleFactor);

  ThemePreferenceState copyWith({
    FluxerThemeMode? mode,
    double? scaleFactor,
  }) {
    return ThemePreferenceState(
      mode: mode ?? this.mode,
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
  }
}

@Riverpod(keepAlive: true)
class ThemePreference extends _$ThemePreference {
  String? _userId;

  @override
  ThemePreferenceState build() => const ThemePreferenceState();

  Future<void> load(String userId) async {
    _userId = userId;
    final db = ref.read(fluxerDatabaseProvider);
    final prefs = await db.userPreferencesDao.getPreferences(userId);
    if (prefs != null) {
      state = ThemePreferenceState(
        mode: FluxerThemeMode.values.firstWhere(
          (m) => m.name == prefs.theme,
          orElse: () => FluxerThemeMode.dark,
        ),
        scaleFactor: prefs.scaleFactor,
      );
    }
  }

  Future<void> setTheme(FluxerThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _persist();
  }

  Future<void> setScaleFactor(double factor) async {
    state = state.copyWith(scaleFactor: factor);
    await _persist();
  }

  Future<void> _persist() async {
    if (_userId == null) return;
    final db = ref.read(fluxerDatabaseProvider);
    await db.userPreferencesDao.savePreferences(
      UserPreferencesTableCompanion(
        userId: Value(_userId!),
        theme: Value(state.mode.name),
        scaleFactor: Value(state.scaleFactor),
      ),
    );
  }
}
```

**Step 2: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `theme_preference_provider.g.dart`

**Step 3: Verify it compiles**

Run: `flutter analyze lib/core/theme/providers/`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/core/theme/providers/theme_preference_provider.dart lib/core/theme/providers/theme_preference_provider.g.dart
git commit -m "feat(theme): add ThemePreference Riverpod provider with Drift persistence"
```

---

### Task 14: Wire Theme Provider Into App

**Files:**
- Modify: `lib/app.dart`

**Step 1: Update app.dart to watch the theme provider**

Replace the hardcoded dark theme from Task 10 with the provider:

```dart
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/core/theme/providers/theme_preference_provider.dart';

// In build():
final themePref = ref.watch(themePreferenceProvider);

return MaterialApp.router(
  title: 'Fluxer',
  debugShowCheckedModeBanner: false,
  theme: buildFluxerTheme(
    colorTheme: themePref.colorTheme,
    textTheme: themePref.textTheme,
    layoutTheme: themePref.layoutTheme,
    brightness: themePref.mode == FluxerThemeMode.light
        ? Brightness.light
        : Brightness.dark,
  ),
  routerConfig: router,
  // ... rest unchanged
);
```

**Step 2: Load theme preference during app startup**

Find where `appStartupProvider` sets the auth state and add theme loading after user is authenticated. The theme preference should be loaded with the userId from the restored session.

**Step 3: Verify the app compiles**

Run: `flutter analyze`
Expected: No issues in app.dart

**Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat(theme): wire ThemePreference provider into MaterialApp"
```

---

### Task 15: Deprecate Old Statics

**Files:**
- Modify: `lib/core/theme/fluxer_colors.dart`
- Modify: `lib/core/theme/fluxer_text_styles.dart`

**Step 1: Add deprecation notices to FluxerColors**

Add `@Deprecated('Use context.colors.tokenName instead')` to every static member in `FluxerColors`. Keep the values intact so existing code continues to work.

**Step 2: Add deprecation notices to FluxerTextStyles**

Same treatment — add `@Deprecated` to every static member in `FluxerTextStyles`.

**Step 3: Verify it compiles**

Run: `flutter analyze`
Expected: Deprecation warnings in files that use FluxerColors/FluxerTextStyles (expected and desired — they guide migration)

**Step 4: Commit**

```bash
git add lib/core/theme/fluxer_colors.dart lib/core/theme/fluxer_text_styles.dart
git commit -m "chore(theme): deprecate FluxerColors and FluxerTextStyles statics"
```

---

### Task 16: Update UserSettingsViewModel

**Files:**
- Modify: `lib/features/settings/providers/user_settings_view_model.dart`

**Step 1: Replace isDarkTheme with ThemePreference integration**

Remove `isDarkTheme` and `toggleTheme()` from `UserSettingsViewState`/`UserSettingsViewModel`. Theme is now managed by `ThemePreference` provider. The appearance settings UI should read/write via `ref.read(themePreferenceProvider.notifier).setTheme(mode)`.

Update `UserSettingsViewState` to remove `isDarkTheme` field and `toggleTheme()` method. Keep `messageDisplayCompact` as-is.

**Step 2: Verify it compiles**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze`
Expected: May need to update `user_appearance.dart` if it references `isDarkTheme`

**Step 3: Commit**

```bash
git add lib/features/settings/providers/user_settings_view_model.dart lib/features/settings/providers/user_settings_view_model.g.dart
git commit -m "refactor(settings): remove isDarkTheme, use ThemePreference provider"
```

---

### Task 17: Update Appearance Settings UI

**Files:**
- Modify: `lib/features/settings/presentation/widgets/user_appearance.dart`

**Step 1: Update the appearance tab to use ThemePreference**

Replace the dark/light toggle with a three-way selector (Dark, Light, Coal) that calls `ref.read(themePreferenceProvider.notifier).setTheme(mode)`. Add the scale factor slider wired to `setScaleFactor()`.

Read the current file first to understand its structure before modifying.

**Step 2: Verify it compiles and runs**

Run: `flutter analyze lib/features/settings/presentation/widgets/user_appearance.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/settings/presentation/widgets/user_appearance.dart
git commit -m "feat(settings): update appearance tab with 3-theme selector and scale slider"
```

---

### Task 18: Final Verification

**Step 1: Run full analysis**

Run: `flutter analyze`
Expected: No errors. Deprecation warnings in files using old FluxerColors/FluxerTextStyles statics (expected — migration is incremental).

**Step 2: Verify the app builds**

Run: `flutter build linux --debug` (or appropriate platform)
Expected: Successful build

**Step 3: Commit any remaining fixes**

```bash
git add -A
git commit -m "fix(theme): resolve any remaining analysis issues"
```
