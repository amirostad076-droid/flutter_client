import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxeron/core/constants/assets.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/presentation/widgets/login_form.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileLayout(context);

    if (isMobile) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
    backgroundColor: context.colors.brandPrimary,
    body: Stack(
      children: [
        const Positioned.fill(child: _TiledPatternBackground()),
        Center(
          child: Container(
            width: 800,
            margin: const EdgeInsets.all(20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 8,
                  blurRadius: 24,
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: context.colors.backgroundSecondary,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            Assets.fluxerLogoColor,
                            width: 128,
                            height: 128,
                          ),
                          const SizedBox(height: 16),
                          SvgPicture.asset(
                            Assets.fluxerLogoText,
                            height: 36,
                            colorFilter: ColorFilter.mode(
                              context.colors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(color: context.colors.borderColor, width: 1),
                  const Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(32),
                      child: LoginForm(showBrowserLogin: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMobileLayout(BuildContext context) => Scaffold(
    backgroundColor: context.colors.backgroundSecondary,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(Assets.fluxerLogoColor, width: 36, height: 36),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  Assets.fluxerLogoText,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    context.colors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const LoginForm(showBrowserLogin: false),
          ],
        ),
      ),
    ),
  );
}

class _TiledPatternBackground extends StatefulWidget {
  const _TiledPatternBackground();

  @override
  State<_TiledPatternBackground> createState() =>
      _TiledPatternBackgroundState();
}

class _TiledPatternBackgroundState extends State<_TiledPatternBackground> {
  ui.Image? _tileImage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTile());
  }

  Future<void> _loadTile() async {
    const loader = SvgAssetLoader(Assets.patternLoginBackground);
    final pictureInfo = await vg.loadPicture(loader, null);
    final image = await pictureInfo.picture.toImage(260, 260);
    pictureInfo.picture.dispose();
    if (mounted) {
      setState(() => _tileImage = image);
    }
  }

  @override
  void dispose() {
    _tileImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tileImage == null) {
      return const SizedBox.expand();
    }
    return CustomPaint(
      painter: _TiledPatternPainter(_tileImage!),
      size: Size.infinite,
    );
  }
}

class _TiledPatternPainter extends CustomPainter {
  final ui.Image tile;

  _TiledPatternPainter(this.tile);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ImageShader(
        tile,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..colorFilter = const ColorFilter.mode(
        Color(0x0DFFFFFF),
        BlendMode.srcIn,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_TiledPatternPainter old) => old.tile != tile;
}
