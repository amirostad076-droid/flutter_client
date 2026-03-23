import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxeron/core/constants/assets.dart';
import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/l10n/generated/fluxer_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
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
  Widget build(BuildContext context) {
    final FluxerLocalizations strings = FluxerLocalizations.of(context);
    final startup = ref.watch(appStartupProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundSecondary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
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
                          (1 -
                              Curves.easeIn.transform(_pulseController.value)) *
                          0.5;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: _logoHeight,
                          height: _logoHeight,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.brandPrimary.withValues(
                              alpha: opacity,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SvgPicture.asset(Assets.fluxerLogoColor, height: _logoHeight),
                ],
              ),
            ),
            if (startup is AsyncError) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  strings.splashStartupFailed(startup.error.toString()),
                  style: context.textStyles.smallText.copyWith(
                    color: context.colors.textDanger,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(appStartupProvider.notifier).retry(),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.brandPrimary,
                ),
                child: Text(strings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
