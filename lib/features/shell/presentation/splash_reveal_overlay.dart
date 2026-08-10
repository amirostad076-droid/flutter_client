import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluxer_app/features/ui/icons/fluxer_brand_logo.dart';

/// Expands the brand circle over the live splash, then fades to the shell
class SplashRevealOverlay {
  SplashRevealOverlay._();

  static const double logoSize = 85;
  static const double pulseScale = 0.8;
  static const double expandScale = 500;
  static const double pulseEndFraction = 0.08;
  static const Duration totalDuration = Duration(milliseconds: 1200);
  static const int maxTickMicros = 32000;
  static const double fadeSpan = 0.12;

  static Duration get pulseDuration {
    final double linear = math.pow(pulseEndFraction, 1 / 3).toDouble();
    return Duration(
      milliseconds: (totalDuration.inMilliseconds * linear).round(),
    );
  }

  static Duration get expandDuration => totalDuration - pulseDuration;

  static void show({
    required BuildContext context,
    required Color backgroundColor,
    required Color brandColor,
    required Offset logoCenterGlobal,
    required VoidCallback onShellMount,
    VoidCallback? onComplete,
  }) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return _SplashRevealOverlayWidget(
          backgroundColor: backgroundColor,
          brandColor: brandColor,
          logoCenterGlobal: logoCenterGlobal,
          onShellMount: onShellMount,
          onComplete: () {
            entry.remove();
            onComplete?.call();
          },
        );
      },
    );
    overlay.insert(entry);
  }
}

class _SplashRevealOverlayWidget extends StatefulWidget {
  const _SplashRevealOverlayWidget({
    required this.backgroundColor,
    required this.brandColor,
    required this.logoCenterGlobal,
    required this.onShellMount,
    required this.onComplete,
  });

  final Color backgroundColor;
  final Color brandColor;
  final Offset logoCenterGlobal;
  final VoidCallback onShellMount;
  final VoidCallback onComplete;

  @override
  State<_SplashRevealOverlayWidget> createState() =>
      _SplashRevealOverlayWidgetState();
}

class _SplashRevealOverlayWidgetState extends State<_SplashRevealOverlayWidget>
    with SingleTickerProviderStateMixin {
  final Widget _logo = const RepaintBoundary(
    child: FluxerBrandLogo(size: SplashRevealOverlay.logoSize),
  );

  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double _expandProgress = 0;
  double? _mountProgress;
  bool _shellMounted = false;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ticker != null) {
        return;
      }
      _ticker = createTicker(_onExpandTick);
      unawaited(_ticker!.start());
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onExpandTick(Duration elapsed) {
    final int dt = (elapsed - _lastElapsed).inMicroseconds.clamp(
      0,
      SplashRevealOverlay.maxTickMicros,
    );
    _lastElapsed = elapsed;

    final double next =
        (_expandProgress +
                dt / SplashRevealOverlay.expandDuration.inMicroseconds)
            .clamp(0.0, 1.0);

    final double scale = _scaleFor(next);
    if (!_shellMounted && _viewport.width > 0 && _circleCoversScreen(scale)) {
      _shellMounted = true;
      _mountProgress = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onShellMount();
      });
    }

    setState(() => _expandProgress = next);
    if (next >= 1) {
      _ticker?.stop();
      widget.onComplete();
    }
  }

  bool _circleCoversScreen(double scale) {
    final Offset center = _localCenter();
    final double radius = (SplashRevealOverlay.logoSize / 2) * scale;
    return radius >= maxRevealRadius(_viewport, center);
  }

  double _scaleFor(double progress) {
    return lerpDouble(
      SplashRevealOverlay.pulseScale,
      SplashRevealOverlay.expandScale,
      Curves.easeInCubic.transform(progress),
    )!;
  }

  double _coverOpacity() {
    final double? mountProgress = _mountProgress;
    if (mountProgress == null) {
      return 1;
    }
    final double u =
        ((_expandProgress - mountProgress) / SplashRevealOverlay.fadeSpan)
            .clamp(0.0, 1.0);
    return 1 - Curves.easeOut.transform(u);
  }

  Offset _localCenter() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return widget.logoCenterGlobal;
    }
    return renderObject.globalToLocal(widget.logoCenterGlobal);
  }

  @override
  Widget build(BuildContext context) {
    _viewport = MediaQuery.sizeOf(context);
    final Offset center = _localCenter();
    final double scale = _scaleFor(_expandProgress);
    final double opacity = _coverOpacity();
    const double logoHalf = SplashRevealOverlay.logoSize / 2;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _SplashRevealPainter(
              backgroundColor: widget.backgroundColor,
              brandColor: widget.brandColor,
              logoSize: SplashRevealOverlay.logoSize,
              center: center,
              scale: scale,
              opacity: opacity,
              paintBackdrop: _shellMounted,
            ),
          ),
          if (scale <= 1.05 && opacity > 0)
            Positioned(
              left: center.dx - logoHalf,
              top: center.dy - logoHalf,
              width: SplashRevealOverlay.logoSize,
              height: SplashRevealOverlay.logoSize,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: _logo),
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashRevealPainter extends CustomPainter {
  _SplashRevealPainter({
    required this.backgroundColor,
    required this.brandColor,
    required this.logoSize,
    required this.center,
    required this.scale,
    required this.opacity,
    required this.paintBackdrop,
  });

  final Color backgroundColor;
  final Color brandColor;
  final double logoSize;
  final Offset center;
  final double scale;
  final double opacity;
  final bool paintBackdrop;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) {
      return;
    }

    if (paintBackdrop) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = backgroundColor.withValues(alpha: opacity),
      );
    }

    canvas.drawCircle(
      center,
      (logoSize / 2) * scale,
      Paint()
        ..color = brandColor.withValues(alpha: opacity)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashRevealPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.opacity != opacity ||
        oldDelegate.center != center ||
        oldDelegate.paintBackdrop != paintBackdrop ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.brandColor != brandColor;
  }
}

double maxRevealRadius(Size size, Offset center) {
  return <Offset>[
    Offset.zero,
    Offset(size.width, 0),
    Offset(0, size.height),
    Offset(size.width, size.height),
  ].map((Offset corner) => (corner - center).distance).reduce(math.max);
}
