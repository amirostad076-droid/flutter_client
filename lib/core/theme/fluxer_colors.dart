import 'package:flutter/material.dart';

/// Fluxer color palette — derived from the fluxer color-system.yaml
/// (dark theme, "darkSurface" + "darkText" scales).
///
/// Families:
///   neutralDark  hue 220  sat 13
///   brand        hue 242  sat 70
///   link         hue 210  sat 100
///   statusOnline hue 142  sat 76
///   statusIdle   hue  45  sat 93
///   statusDnd    hue   0  sat 84
///   statusOffline hue 218 sat 11
///   statusDanger hue   1  sat 77
///   brandIcon    hue  38  sat 92
///   accentPurple hue 270  sat 80
///   textCode     hue 340  sat 50
abstract final class FluxerColors {
  // ── darkSurface scale (neutralDark, L 5..26, easeOut) ──

  /// --background-primary  pos 0    L=5%
  @Deprecated('Use context.colors instead')
  static const backgroundPrimary = Color(0xFF0B0C0E);

  /// --background-secondary  pos 0.16  L≈11%
  @Deprecated('Use context.colors instead')
  static const backgroundSecondary = Color(0xFF181B20);

  /// --background-secondary-lighter  pos 0.22  L≈13%
  @Deprecated('Use context.colors instead')
  static const backgroundSecondaryLighter = Color(0xFF1D2026);

  /// --background-secondary-alt  pos 0.28  L≈15%
  @Deprecated('Use context.colors instead')
  static const backgroundSecondaryAlt = Color(0xFF21242B);

  /// --background-channel-header  pos 0.34  L≈17%
  @Deprecated('Use context.colors instead')
  static const backgroundChannelHeader = Color(0xFF252930);

  /// --guild-list-foreground  pos 0.38  L≈18%
  @Deprecated('Use context.colors instead')
  static const guildListForeground = Color(0xFF272B33);

  /// --background-tertiary  pos 0.4  L≈18%
  @Deprecated('Use context.colors instead')
  static const backgroundTertiary = Color(0xFF282C35);

  /// --background-header-secondary / --background-header-primary  pos 0.5
  @Deprecated('Use context.colors instead')
  static const backgroundHeaderPrimary = Color(0xFF2E323B);

  /// --background-textarea  pos 0.68  L≈24%
  @Deprecated('Use context.colors instead')
  static const backgroundTextarea = Color(0xFF343A44);

  /// --background-header-primary-hover  pos 0.85  L≈25%
  @Deprecated('Use context.colors instead')
  static const backgroundHeaderPrimaryHover = Color(0xFF383E49);

  /// --background-floating (deep dark, used for tooltips / popups)
  /// Approximated: neutralDark L≈3%
  @Deprecated('Use context.colors instead')
  static const backgroundFloating = Color(0xFF070809);

  // ── Modifiers ──

  /// --background-modifier-hover  white @ 5%
  @Deprecated('Use context.colors instead')
  static const backgroundModifierHover = Color(0x0CFFFFFF);

  /// --background-modifier-selected  white @ 10%
  @Deprecated('Use context.colors instead')
  static const backgroundModifierSelected = Color(0x19FFFFFF);

  /// --background-modifier-accent  neutralDark L=80 @ 15%
  @Deprecated('Use context.colors instead')
  static const backgroundModifierAccent = Color(0x26C5C9D2);

  // ── Aliases used across widgets ──

  /// Chat area background
  @Deprecated('Use context.colors instead')
  static const chatBackground = Color(0xFF1D2026);

  /// Chat input background
  @Deprecated('Use context.colors instead')
  static const chatInputBackground = Color(0xFF1D2026);

  /// Message hover tint (= backgroundModifierHover)
  @Deprecated('Use context.colors instead')
  static const Color messageHover = backgroundModifierHover;

  /// Server sidebar
  @Deprecated('Use context.colors instead')
  static const serverSidebarBackground = Color(0xFF191B20);

  /// Server icon default background
  @Deprecated('Use context.colors instead')
  static const serverIconBackground = Color(0xFF282C34);

  /// Server icon selected / hovered background
  @Deprecated('Use context.colors instead')
  static const serverIconActive = Color(0xFF4441D8);

  /// Channel sidebar
  @Deprecated('Use context.colors instead')
  static const channelSidebarBackground = Color(0xFF191B20);

  /// Member list sidebar
  @Deprecated('Use context.colors instead')
  static const memberListBackground = Color(0xFF1D2026);

  /// User panel background
  @Deprecated('Use context.colors instead')
  static const userPanelBackground = Color(0xFF1C1E24);

  /// Accent background (= backgroundSecondaryAlt)
  @Deprecated('Use context.colors instead')
  static const Color backgroundAccent = backgroundSecondaryAlt;

  // ── Brand ──

  /// --brand-primary  hue 242  sat 70  L 55
  @Deprecated('Use context.colors instead')
  static const blurple = Color(0xFF413BDC);

  /// --brand-secondary  hue 242  sat 60  L 49
  @Deprecated('Use context.colors instead')
  static const blurpleDark = Color(0xFF3631C7);

  /// --brand-primary-light  hue 242  sat 100  L 84
  @Deprecated('Use context.colors instead')
  static const blurpleLight = Color(0xFFB0ADFE);

  // ── Status ──

  /// --status-online  hue 142  sat 76  L 40
  @Deprecated('Use context.colors instead')
  static const online = Color(0xFF18B351);

  /// --status-idle  hue 45  sat 93  L 50
  @Deprecated('Use context.colors instead')
  static const idle = Color(0xFFF6BA08);

  /// --status-dnd  hue 0  sat 84  L 60
  @Deprecated('Use context.colors instead')
  static const dnd = Color(0xFFEE4343);

  /// --status-offline  hue 218  sat 11  L 65
  @Deprecated('Use context.colors instead')
  static const offline = Color(0xFF9BA3AF);

  /// --status-danger  hue 1  sat 77  L 55
  @Deprecated('Use context.colors instead')
  static const streaming = Color(0xFFE43633);

  // ── darkText scale (neutralDark, L 52..96, easeInOut) ──

  /// --text-primary  pos 1  L=96%
  @Deprecated('Use context.colors instead')
  static const white = Color(0xFFF3F4F6);

  /// --text-chat  pos 0.82  L≈93%
  @Deprecated('Use context.colors instead')
  static const textNormal = Color(0xFFEBECEF);

  /// --text-secondary  pos 0.72  L≈89%
  @Deprecated('Use context.colors instead')
  static const textSecondary = Color(0xFFDFE2E6);

  /// --text-primary-muted / --text-chat-muted  pos 0.55  L≈78%
  @Deprecated('Use context.colors instead')
  static const textMuted = Color(0xFFC0C4CE);

  /// --text-tertiary  pos 0.38  L≈65%
  @Deprecated('Use context.colors instead')
  static const textTertiary = Color(0xFF99A1B0);

  /// --text-tertiary-muted  pos 0.2  L≈56%
  @Deprecated('Use context.colors instead')
  static const textFaint = Color(0xFF7E889C);

  /// --text-tertiary-secondary  pos 0  L=52%
  @Deprecated('Use context.colors instead')
  static const textFaintest = Color(0xFF747F94);

  /// --text-link  hue 210  sat 100  L 70
  @Deprecated('Use context.colors instead')
  static const textLink = Color(0xFF65B2FF);

  /// --text-warning  hue 45  sat 93  L 55
  @Deprecated('Use context.colors instead')
  static const textWarning = Color(0xFFF6C121);

  /// --text-on-brand-primary  L 98%
  @Deprecated('Use context.colors instead')
  static const textOnBrand = Color(0xFFF9F9F9);

  /// --status-danger (reused for danger text)
  @Deprecated('Use context.colors instead')
  static const textDanger = Color(0xFFE43633);

  /// --status-online (reused for positive text)
  @Deprecated('Use context.colors instead')
  static const textPositive = Color(0xFF18B351);

  // ── Interactive ──

  /// --interactive-active (approx: white)
  @Deprecated('Use context.colors instead')
  static const interactiveActive = Color(0xFFFFFFFF);

  /// Derived from --text-secondary (bright enough for icons)
  @Deprecated('Use context.colors instead')
  static const interactiveNormal = Color(0xFFDFE2E6);

  /// Derived from --text-tertiary
  @Deprecated('Use context.colors instead')
  static const interactiveHover = Color(0xFFF3F4F6);

  /// --interactive-muted (approx: hue 228  sat 10  L 35)
  @Deprecated('Use context.colors instead')
  static const interactiveMuted = Color(0xFF505362);

  // ── Channels ──

  /// Channel default text (= textTertiary)
  @Deprecated('Use context.colors instead')
  static const channelDefault = Color(0xFF99A1B0);

  /// Channel active text (= white / text-primary)
  @Deprecated('Use context.colors instead')
  static const channelActive = Color(0xFFF3F4F6);

  // ── Border / Divider ──

  /// --border-color  neutralDark L=50 @ 20%
  @Deprecated('Use context.colors instead')
  static const divider = Color(0x336E7990);

  /// Subtle separator for adjacent panels with same/similar background
  @Deprecated('Use context.colors instead')
  static const separator = Color(0xFF2A2D35);

  /// --border-color-hover  neutralDark L=50 @ 30%
  @Deprecated('Use context.colors instead')
  static const borderHover = Color(0x4C6E7990);

  // ── Scrollbar ──

  /// --scrollbar-thumb-bg  rgba(121,122,124,0.4)
  @Deprecated('Use context.colors instead')
  static const scrollbarThin = Color(0x66797A7C);

  /// --scrollbar-thumb-bg-hover  rgba(121,122,124,0.7)
  @Deprecated('Use context.colors instead')
  static const scrollbarHover = Color(0xB3797A7C);

  /// --scrollbar-track-bg  transparent
  @Deprecated('Use context.colors instead')
  static const Color scrollbarAuto = Colors.transparent;

  // ── Embed ──

  /// Embed background (= backgroundSecondary)
  @Deprecated('Use context.colors instead')
  static const Color embedBackground = backgroundSecondary;

  /// Embed border (= divider)
  @Deprecated('Use context.colors instead')
  static const Color embedBorder = divider;

  // ── Misc ──

  /// Mention highlight tint
  @Deprecated('Use context.colors instead')
  static const mentionBackground = Color(0x26C5C9D2);

  /// Spoiler overlay
  @Deprecated('Use context.colors instead')
  static const spoilerBackground = Color(0xFF15171B);

  // ── Buttons ──

  /// --button-primary-fill  hue 139  sat 55  L 44
  @Deprecated('Use context.colors instead')
  static const buttonPrimaryFill = Color(0xFF32AD59);

  /// --button-danger-fill  hue 359  sat 70  L 54
  @Deprecated('Use context.colors instead')
  static const buttonDangerFill = Color(0xFFDB373A);

  // ── Accent ──

  /// --accent-purple  hue 270  sat 80  L 65
  @Deprecated('Use context.colors instead')
  static const accentPurple = Color(0xFFA55EED);

  /// --plutonium-icon  hue 38  sat 92  L 50
  @Deprecated('Use context.colors instead')
  static const brandIcon = Color(0xFFF49E0A);
}
