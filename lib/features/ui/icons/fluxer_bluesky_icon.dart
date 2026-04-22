import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FluxerBlueskyIcon extends StatelessWidget {
  const FluxerBlueskyIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/connections/bluesky.svg',
    width: size,
    height: size,
  );
}
