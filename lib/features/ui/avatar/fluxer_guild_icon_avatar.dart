import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _kCornerRatio = 0.32;
const double _kUnavailableIconSize = 22;
const double _kFallbackFontSize = 13;

/// Rounded-square server icon used by inbox-style notification cards.
///
/// Renders one of three states:
/// - Unavailable guild placeholder when [isUnavailable] is true.
/// - Network image with letter fallback when [imageUrl] is provided.
/// - Letter-only fallback otherwise.
class FluxerGuildIconAvatar extends StatelessWidget {
  const FluxerGuildIconAvatar({
    required this.abbreviation,
    this.imageUrl,
    this.isUnavailable = false,
    this.isCircle = false,
    this.size = 36,
    super.key,
  });

  final String abbreviation;
  final String? imageUrl;
  final bool isUnavailable;
  final bool isCircle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final BorderRadius radius = BorderRadius.circular(
      isCircle ? size / 2 : size * _kCornerRatio,
    );
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.serverIconBackground,
          borderRadius: radius,
        ),
        child: ClipRRect(borderRadius: radius, child: _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.colors;
    if (isUnavailable) {
      return Center(
        child: PhosphorIcon(
          PhosphorIconsRegular.exclamationMark,
          color: colors.textOnBrandPrimary,
          size: _kUnavailableIconSize,
        ),
      );
    }
    final String? url = imageUrl;
    if (url == null) {
      return _LetterFallback(text: abbreviation, color: colors.textPrimary);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
          _LetterFallback(text: abbreviation, color: colors.textPrimary),
    );
  }
}

class _LetterFallback extends StatelessWidget {
  const _LetterFallback({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: _kFallbackFontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
