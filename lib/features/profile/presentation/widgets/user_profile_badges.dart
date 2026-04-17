import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const int _kFlagStaff = 1 << 0;
const int _kFlagPartner = 1 << 2;
const int _kFlagBugHunter = 1 << 3;
const double _kBadgeSize = 20;

class UserProfileBadges extends StatelessWidget {
  const UserProfileBadges({required this.flags, super.key});

  final int flags;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (flags & _kFlagStaff != 0) {
      children.add(
        SvgPicture.asset(
          'assets/images/badges/staff.svg',
          width: _kBadgeSize,
          height: _kBadgeSize,
        ),
      );
    }
    if (flags & _kFlagPartner != 0) {
      children.add(
        SvgPicture.asset(
          'assets/images/badges/partner.svg',
          width: _kBadgeSize,
          height: _kBadgeSize,
        ),
      );
    }
    if (flags & _kFlagBugHunter != 0) {
      children.add(
        SvgPicture.asset(
          'assets/images/badges/bug-hunter.svg',
          width: _kBadgeSize,
          height: _kBadgeSize,
        ),
      );
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(spacing: 4, runSpacing: 4, children: children);
  }
}
