import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FluxerVerifiedBadgeIcon extends StatelessWidget {
  const FluxerVerifiedBadgeIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/connections/verified-badge.svg',
    width: size,
    height: size,
  );
}
