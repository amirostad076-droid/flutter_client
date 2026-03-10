import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxeron/core/constants/assets.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const double _logoHeight = 100;
  static const Duration _pulseDuration = Duration(milliseconds: 1000);

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FluxerColors.backgroundSecondary,
    body: Center(
      child: SizedBox(
        height: _logoHeight * 2,
        width: _logoHeight * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, Widget? child) {
                const double startScale = 0.4;
                const double endScale = 1.4;
                final double scale =
                    startScale +
                    (endScale - startScale) *
                        Curves.easeOut.transform(_pulseController.value);
                final double opacity =
                    (1 - Curves.easeIn.transform(_pulseController.value)) * 0.5;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: _logoHeight,
                    height: _logoHeight,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FluxerColors.blurple.withValues(alpha: opacity),
                    ),
                  ),
                );
              },
            ),
            SvgPicture.asset(Assets.fluxerLogoColorSVG, height: _logoHeight),
          ],
        ),
      ),
    ),
  );
}
