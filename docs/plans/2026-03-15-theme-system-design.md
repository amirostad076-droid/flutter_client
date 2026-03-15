# Fluxer Theme System Redesign

## Overview

Replace the current static-constant theme system (`FluxerColors`, `FluxerTextStyles`) with a context-aware `ThemeExtension`-based architecture supporting multiple themes (Dark, Light, Coal/AMOLED), a programmatic color generator, global UI scaling, and per-user persistence via Drift.

## Goals

- Parity with the Fluxer web app's 89+ color tokens
- Three theme variants: Dark, Light, Coal
- Programmatic color generation from HSL families (enables future theme editor)
- Global UI scale factor (spacing, radius, text all scale together)
- Per-user theme persistence via Drift (multi-account ready)
- Incremental migration — old statics remain as deprecated aliases

## Architecture

```
lib/core/theme/
  color_generator.dart        — HSL color family → Color token generator
  fluxer_color_theme.dart     — ThemeExtension<FluxerColorTheme> (~90 color tokens)
  fluxer_text_theme.dart      — ThemeExtension<FluxerTextTheme> (text styles referencing color theme)
  fluxer_layout_theme.dart    — ThemeExtension<FluxerLayoutTheme> (scaled spacing, radius, layout dims)
  fluxer_theme.dart           — buildFluxerTheme() assembler
  fluxer_theme_extension.dart — BuildContext extensions (context.colors, context.textStyles, context.spacing, context.radius)
  themes/
    dark.dart                 — Dark theme color definitions
    light.dart                — Light theme color definitions
    coal.dart                 — Coal/AMOLED theme color definitions
```

## Context Access Pattern

```dart
extension FluxerThemeX on BuildContext {
  FluxerColorTheme get colors => Theme.of(this).extension<FluxerColorTheme>()!;
  FluxerTextTheme get textStyles => Theme.of(this).extension<FluxerTextTheme>()!;
  FluxerLayoutTheme get layout => Theme.of(this).extension<FluxerLayoutTheme>()!;
}

// Convenience aliases on FluxerLayoutTheme
extension FluxerLayoutAccessors on FluxerLayoutTheme {
  double get s0 => spacing.s0;   // scaled spacing values
  double get s1 => spacing.s1;
  // ...
  BorderRadius get radiusSm => radius.sm;  // scaled radius values
  // ...
}

// Widget usage:
Container(color: context.colors.backgroundPrimary)
Text('hello', style: context.textStyles.bodySmall)
Padding(padding: EdgeInsets.all(context.layout.s4))
ClipRRect(borderRadius: context.layout.radiusMd)
```

## Color Generator

Mirrors the web app's `GenerateColorSystem.tsx`. Defines color families by HSL parameters and generates color stops along scales with easing curves.

```dart
class ColorFamily {
  final double hue;
  final double saturation;
  // saturationFactor applied at generation time for accessibility
}

class ColorScale {
  final ColorFamily family;
  final double lightnessStart;
  final double lightnessEnd;
  final Curve curve; // Curves.linear, Curves.easeIn, Curves.easeOut, Curves.easeInOut

  Color colorAt(double position, {double saturationFactor = 1.0}) {
    final t = curve.transform(position);
    final lightness = lerpDouble(lightnessStart, lightnessEnd, t)!;
    return HSLColor.fromAHSL(
      1.0,
      family.hue,
      (family.saturation * saturationFactor).clamp(0.0, 1.0),
      lightness.clamp(0.0, 1.0),
    ).toColor();
  }
}
```

### Color Families (from web app)

| Family | Hue | Saturation |
|--------|-----|-----------|
| neutralDark | 220 | 13% |
| neutralLight | 220 | 10% |
| brand | 242 | 70% |
| link | 210 | 100% |
| statusOnline | 142 | 76% |
| statusIdle | 45 | 93% |
| statusDnd | 0 | 84% |
| statusOffline | 218 | 11% |
| statusDanger | 1 | 77% |
| accentPurple | 270 | 80% |
| textCode | 340 | 50% |
| brandIcon | 38 | 92% |

### Theme Scales

- **Dark surfaces:** neutralDark, L 5%→26%, easeOut
- **Dark text:** neutralDark, L 52%→96%, easeInOut
- **Light surfaces:** neutralLight, L 86%→98.5%, easeIn (inverted)
- **Light text:** neutralLight, L 10%→50%, easeInOut (inverted)
- **Coal surfaces:** neutralDark, L 1%→12%, easeOut (ultra-dark)
- **Coal text:** same as dark text

## FluxerColorTheme Tokens (~90)

### Background (12)
- backgroundPrimary, backgroundSecondary, backgroundSecondaryAlt, backgroundTertiary
- backgroundTextarea, backgroundHeaderPrimary, backgroundHeaderPrimaryHover, backgroundHeaderSecondary
- backgroundModifierHover, backgroundModifierSelected, backgroundModifierAccent, backgroundModifierAccentFocus

### Brand (4)
- brandPrimary (blurple), brandSecondary, brandPrimaryLight, brandPrimaryFill

### Status (5)
- statusOnline, statusIdle, statusDnd, statusOffline, statusDanger

### Text (10)
- textPrimary, textSecondary, textTertiary, textPrimaryMuted
- textChat, textChatMuted, textLink, textOnBrandPrimary
- textTertiaryMuted, textTertiarySecondary

### Border (3)
- borderColor, borderColorHover, borderColorFocus

### Accent (6)
- accentPrimary, accentSuccess, accentWarning, accentDanger, accentInfo, accentPurple

### Alert (5)
- alertNote, alertTip, alertImportant, alertWarning, alertCaution

### Markup (4)
- markupMentionText, markupMentionFill
- markupInteractiveHoverText, markupInteractiveHoverFill

### Button (19)
- buttonPrimaryFill, buttonPrimaryActiveFill, buttonPrimaryText
- buttonSecondaryFill, buttonSecondaryActiveFill, buttonSecondaryText, buttonSecondaryActiveText
- buttonDangerFill, buttonDangerActiveFill, buttonDangerText
- buttonDangerOutlineBorder, buttonDangerOutlineText, buttonDangerOutlineActiveFill, buttonDangerOutlineActiveBorder
- buttonGhostText
- buttonInvertedFill, buttonInvertedText
- buttonOutlineBorder, buttonOutlineText, buttonOutlineActiveFill, buttonOutlineActiveBorder

### Content Background (11)
- bgPrimary, bgSecondary, bgTertiary, bgHover, bgActive
- bgCode, bgCodeBlock, bgBlockquote
- bgTableHeader, bgTableRowOdd, bgTableRowEven

### Interactive Surface (3)
- surfaceInteractiveHoverBg, surfaceInteractiveSelectedBg, surfaceInteractiveSelectedColor

### Scrollbar (3)
- scrollbarThumbBg, scrollbarThumbBgHover, scrollbarTrackBg

### Miscellaneous
- focusPrimary, formSurfaceBackground
- embedBackground, embedBorder
- mentionBackground, spoilerBackground
- serverIconBackground, serverIconActive
- chatBackground, chatInputBackground
- channelSidebarBackground, memberListBackground, userPanelBackground

## FluxerTextTheme

Text styles that reference `FluxerColorTheme` for colors. Rebuilt when theme changes.

### Presets
- heading (20px, w600, textPrimary)
- channelName (16px, w600, textPrimary)
- username (16px, w500, textPrimary)
- messageText (16px, w400, textChat, height 1.375)
- bodyMedium (16px, w400, textPrimary)
- bodySmall (14px, w400, textPrimaryMuted)
- label (14px, w500, textPrimary)
- timestamp (12px, w400, textPrimaryMuted)
- smallText (12px, w600, textPrimaryMuted, letterSpacing 0.02)
- categoryName (12px, w600, textPrimaryMuted, letterSpacing 0.5)
- inputText (16px, w400, textChat)
- inputHint (16px, w400, textChatMuted)
- embedTitle (16px, w600, textLink)
- embedDescription (14px, w400, textChat, height 1.3)
- embedFooter (12px, w400, textPrimaryMuted)

## FluxerLayoutTheme (Scaled)

All values multiplied by a user-configurable scale factor (default 1.0). Stored as a ThemeExtension so widgets rebuild when scale changes.

### Spacing Scale (base values × scaleFactor)
| Token | Base | At 1.0x | At 1.25x |
|-------|------|---------|----------|
| s0 | 0 | 0 | 0 |
| s1 | 4 | 4 | 5 |
| s1_5 | 6 | 6 | 7.5 |
| s2 | 8 | 8 | 10 |
| s3 | 12 | 12 | 15 |
| s4 | 16 | 16 | 20 |
| s5 | 20 | 20 | 25 |
| s6 | 24 | 24 | 30 |
| s8 | 32 | 32 | 40 |
| s10 | 40 | 40 | 50 |
| s12 | 48 | 48 | 60 |
| s16 | 64 | 64 | 80 |
| s20 | 80 | 80 | 100 |
| s24 | 96 | 96 | 120 |

### Radius Scale (base values × scaleFactor)
| Token | Base | Description |
|-------|------|-------------|
| sm | 4px | Embeds, tags, badges |
| md | 6px | Small elements |
| lg | 8px | Buttons, cards, inputs |
| xl | 12px | Larger elements |
| xxl | 16px | Modals, sheets |
| full | 9999px | Circles, pills |
| media | 4px | Images, video |

### Layout Dimensions (base values × scaleFactor)
| Token | Base | Description |
|-------|------|-------------|
| sidebarWidth | 270 | Channel/DM sidebar |
| headerHeight | 56 | Top bar |
| guildIconSize | 44 | Server icon |
| guildListWidth | 72 | Server sidebar |
| mobileBottomNavHeight | 60 | Mobile navigation |
| userAreaHeight | 72 | Bottom user panel |

## User Accent Color Utility

Centralized fallback chain for user profile colors:

```dart
abstract final class AccentColorUtils {
  /// Returns the user's accent color with fallback chain:
  /// profileAccentColor → avatarColor → defaultColorByUserId
  static Color resolveAccentColor({
    int? profileAccentColor,
    int? avatarColor,
    required String userId,
  }) { ... }

  static const defaultPalette = [
    Color(0xFF5865F2), Color(0xFF57F287),
    Color(0xFFFEE75C), Color(0xFFEB459E), Color(0xFFED4245),
  ];
}
```

## Color Utilities

Port of the web app's `ColorUtils.tsx`:

```dart
abstract final class ColorUtils {
  static Color fromInt(int colorInt) { ... }
  static Color bestContrastColor(int colorInt) { ... }  // WCAG luminance → black or white
  static Color dim(Color color, double amount) { ... }
}
```

## Theme Persistence

### Drift Table

```dart
class UserPreferences extends Table {
  TextColumn get userId => text()();
  TextColumn get theme => text().withDefault(const Constant('dark'))(); // dark, light, coal
  RealColumn get scaleFactor => real().withDefault(const Constant(1.0))();
  // Future: compactMode, fontSize, notificationPrefs, etc.

  @override
  Set<Column> get primaryKey => {userId};
}
```

### Riverpod Provider

```dart
@Riverpod(keepAlive: true)
class ThemePreference extends _$ThemePreference {
  @override
  FluxerThemeMode build() => FluxerThemeMode.dark; // default until loaded

  Future<void> load(String userId) async { ... }
  Future<void> setTheme(FluxerThemeMode mode) async { ... }
  Future<void> setScaleFactor(double factor) async { ... }
}
```

### App Integration

```dart
// In app.dart
MaterialApp.router(
  theme: buildFluxerTheme(
    colorTheme: ref.watch(themePreferenceProvider).colorTheme,
    textTheme: ref.watch(themePreferenceProvider).textTheme,
    layoutTheme: ref.watch(themePreferenceProvider).layoutTheme,
  ),
  // ...
)
```

## Migration Strategy

1. New system coexists with old `FluxerColors`/`FluxerTextStyles` statics
2. Old statics are marked `@Deprecated` and point to dark theme values
3. Features migrate incrementally (one feature folder per PR)
4. Old statics deleted once all references are gone

## Phases

### Phase 1 — Foundation
- Color generator (`color_generator.dart`)
- `FluxerColorTheme` ThemeExtension with all ~90 tokens
- `FluxerTextTheme` ThemeExtension with expanded presets
- `FluxerLayoutTheme` ThemeExtension (spacing, radius, layout dimensions)
- Context extensions (`context.colors`, `context.textStyles`, `context.layout`)
- Dark theme definition using generator
- `buildFluxerTheme()` assembler updated
- Wire into `app.dart`

### Phase 2 — Parity with Web App
- Light theme definition
- Coal/AMOLED theme definition
- User accent color utility
- Color utilities (fromInt, contrast, dim)
- Interactive surface tokens
- Full button token set
- Alert and markup tokens
- Content background tokens
- Drift `UserPreferences` table + migration
- `ThemePreference` Riverpod provider
- Scale factor support in `FluxerLayoutTheme`
- Deprecate old `FluxerColors`/`FluxerTextStyles`

### Deferred
- Syntax highlighting tokens (with markdown feature)
- System theme detection
- Theme editor UI
- Theme sharing/import
- Saturation factor accessibility knob
- Custom CSS-like override system
