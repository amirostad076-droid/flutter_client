import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Duration _kNekoAnimationDuration = Duration(seconds: 1);
const double _kNekoSize = 32;
const Rect _kNekoFrameTop = Rect.fromLTWH(64, 0, 32, 32);
const Rect _kNekoFrameBottom = Rect.fromLTWH(64, 32, 32, 32);

class NekoSprite extends StatefulWidget {
  const NekoSprite({super.key});

  @override
  State<NekoSprite> createState() => _NekoSpriteState();
}

class _NekoSpriteState extends State<NekoSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  ui.Image? _spriteImage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _kNekoAnimationDuration,
    )..repeat();
    _loadSpriteImage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _spriteImage?.dispose();
    super.dispose();
  }

  Future<void> _loadSpriteImage() async {
    final ByteData byteData = await rootBundle.load('assets/images/neko.gif');
    final Uint8List bytes = byteData.buffer.asUint8List();
    final ui.Image image = await _decodeImage(bytes);
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _spriteImage?.dispose();
      _spriteImage = image;
    });
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Rect _selectFrameRect(double progress) {
    if (progress <= 0.5) {
      return _kNekoFrameTop;
    }
    return _kNekoFrameBottom;
  }

  @override
  Widget build(BuildContext context) {
    final ui.Image? spriteImage = _spriteImage;
    if (spriteImage == null) {
      return const SizedBox(width: _kNekoSize, height: _kNekoSize);
    }
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          size: const Size(_kNekoSize, _kNekoSize),
          painter: _NekoSpritePainter(
            image: spriteImage,
            sourceRect: _selectFrameRect(_animationController.value),
          ),
        );
      },
    );
  }
}

class _NekoSpritePainter extends CustomPainter {
  const _NekoSpritePainter({required this.image, required this.sourceRect});

  final ui.Image image;
  final Rect sourceRect;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final Rect destinationRect = Offset.zero & size;
    canvas.drawImageRect(image, sourceRect, destinationRect, paint);
  }

  @override
  bool shouldRepaint(covariant _NekoSpritePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.sourceRect != sourceRect;
  }
}
