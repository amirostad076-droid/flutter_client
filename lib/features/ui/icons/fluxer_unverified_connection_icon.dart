import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FluxerUnverifiedConnectionIcon extends StatelessWidget {
  const FluxerUnverifiedConnectionIcon({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/connections/unverified-connection.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}
