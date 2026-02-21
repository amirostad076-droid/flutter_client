import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';

/// Fluxer text styles using IBM Plex Sans.
abstract final class FluxerTextStyles {
  static final String _fontFamily = GoogleFonts.ibmPlexSans().fontFamily!;

  static final heading = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: FluxerColors.white,
  );

  static final channelName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FluxerColors.white,
  );

  static final username = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: FluxerColors.white,
  );

  static final messageText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textNormal,
    height: 1.375,
  );

  static final timestamp = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textMuted,
  );

  static final smallText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FluxerColors.textMuted,
    letterSpacing: 0.02,
  );

  static final categoryName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FluxerColors.textMuted,
    letterSpacing: 0.5,
  );

  static final inputText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textNormal,
  );

  static final embedTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FluxerColors.textLink,
  );

  static final embedDescription = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textNormal,
    height: 1.3,
  );

  static final embedFooter = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: FluxerColors.textMuted,
  );
}
