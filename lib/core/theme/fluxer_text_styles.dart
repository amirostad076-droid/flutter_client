import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fluxer text styles using IBM Plex Sans.
abstract final class FluxerTextStyles {
  @Deprecated('Use context.textStyles instead')
  static final String _fontFamily = GoogleFonts.ibmPlexSans().fontFamily!;

  @Deprecated('Use context.textStyles instead')
  static final heading = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: FluxerColors.white,
  );

  @Deprecated('Use context.textStyles instead')
  static final channelName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FluxerColors.white,
  );

  @Deprecated('Use context.textStyles instead')
  static final username = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: FluxerColors.white,
  );

  @Deprecated('Use context.textStyles instead')
  static final messageText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textNormal,
    height: 1.375,
  );

  @Deprecated('Use context.textStyles instead')
  static final timestamp = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textMuted,
  );

  @Deprecated('Use context.textStyles instead')
  static final smallText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FluxerColors.textMuted,
    letterSpacing: 0.02,
  );

  @Deprecated('Use context.textStyles instead')
  static final categoryName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FluxerColors.textMuted,
    letterSpacing: 0.5,
  );

  @Deprecated('Use context.textStyles instead')
  static final inputText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textNormal,
  );

  @Deprecated('Use context.textStyles instead')
  static final embedTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FluxerColors.textLink,
  );

  @Deprecated('Use context.textStyles instead')
  static final embedDescription = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textNormal,
    height: 1.3,
  );

  @Deprecated('Use context.textStyles instead')
  static final embedFooter = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textMuted,
  );
}
