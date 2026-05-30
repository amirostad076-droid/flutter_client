import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

const int _kFlagStaff = 1 << 0;
const int _kFlagCtp = 1 << 1;
const int _kFlagPartner = 1 << 2;
const int _kFlagBugHunter = 1 << 3;
const double _kBadgeSize = 20;
const double _kVisionaryIdFontSize = 17;
const double _kVisionaryIdLineHeight = 20;
const String _kStaffBadgeAsset = 'assets/images/badges/staff.svg';
const String _kCtpBadgeAsset = 'assets/images/badges/ctp.svg';
const String _kPartnerBadgeAsset = 'assets/images/badges/partner.svg';
const String _kBugHunterBadgeAsset = 'assets/images/badges/bug-hunter.svg';
const String _kPlutoniumBadgeAsset = 'assets/images/badges/plutonium.svg';

TextStyle visionaryIdBadgeTextStyle(
  FluxerColorTheme colors,
  Brightness brightness,
) {
  return TextStyle(
    color: brightness == Brightness.light
        ? colors.brandPrimary
        : colors.brandPrimaryLight,
    fontSize: _kVisionaryIdFontSize,
    fontWeight: FontWeight.w700,
    height: _kVisionaryIdLineHeight / _kVisionaryIdFontSize,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

class UserProfileBadges extends StatelessWidget {
  const UserProfileBadges({
    required this.flags,
    this.hasPlutonium = false,
    this.premiumLifetimeSequence,
    super.key,
  });

  final int flags;
  final bool hasPlutonium;
  final int? premiumLifetimeSequence;

  Widget _buildBadge({required String asset, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: SvgPicture.asset(
        asset,
        width: _kBadgeSize,
        height: _kBadgeSize,
        semanticsLabel: tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final List<Widget> children = <Widget>[];
    if (flags & _kFlagStaff != 0) {
      children.add(
        _buildBadge(
          asset: _kStaffBadgeAsset,
          tooltip: l10n.userProfileStaffBadgeTooltip,
        ),
      );
    }
    if (flags & _kFlagCtp != 0) {
      children.add(
        _buildBadge(
          asset: _kCtpBadgeAsset,
          tooltip: l10n.userProfileCtpBadgeTooltip,
        ),
      );
    }
    if (flags & _kFlagPartner != 0) {
      children.add(
        _buildBadge(
          asset: _kPartnerBadgeAsset,
          tooltip: l10n.userProfilePartnerBadgeTooltip,
        ),
      );
    }
    if (flags & _kFlagBugHunter != 0) {
      children.add(
        _buildBadge(
          asset: _kBugHunterBadgeAsset,
          tooltip: l10n.userProfileBugHunterBadgeTooltip,
        ),
      );
    }
    if (hasPlutonium) {
      children.add(
        _buildBadge(
          asset: _kPlutoniumBadgeAsset,
          tooltip: l10n.userProfilePlutoniumBadgeTooltip,
        ),
      );
    }
    if (hasPlutonium && premiumLifetimeSequence != null) {
      final FluxerColorTheme colors = context.colors;
      final Brightness brightness = Theme.of(context).brightness;
      children.add(
        Tooltip(
          message: l10n.userProfileVisionaryIdTooltip(premiumLifetimeSequence!),
          preferBelow: false,
          child: Text(
            '#$premiumLifetimeSequence',
            style: visionaryIdBadgeTextStyle(colors, brightness),
          ),
        ),
      );
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(spacing: 4, runSpacing: 4, children: children);
  }
}
