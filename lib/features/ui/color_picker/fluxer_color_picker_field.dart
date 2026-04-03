import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/popout/fluxer_popout.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _kInputHeight = 44;
const double _kSwatchWidth = 48;
const double _kColorAreaHeight = 160;
const double _kHueTrackHeight = 16;
const double _kThumbSize = 18;
const double _kPopoverWidth = 260;

int _colorToInt(Color color) =>
    ((color.r * 255).round() << 16) |
    ((color.g * 255).round() << 8) |
    (color.b * 255).round();

Color _intToColor(int value) => Color.fromARGB(
      255,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );

String _intToHex(int value) =>
    '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';

int? _parseHex(String input) {
  var raw = input.trim();
  if (!raw.startsWith('#')) {
    raw = '#$raw';
  }
  raw = raw.toUpperCase();

  if (raw.length == 4) {
    final r = raw[1];
    final g = raw[2];
    final b = raw[3];
    raw = '#$r$r$g$g$b$b';
  }

  if (raw.length == 9) {
    raw = raw.substring(0, 7);
  }

  final match = RegExp(r'^#[0-9A-F]{6}$').firstMatch(raw);
  if (match == null) {
    return null;
  }
  return int.tryParse(raw.substring(1), radix: 16);
}

class FluxerColorPickerField extends StatefulWidget {
  const FluxerColorPickerField({
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.disabled = false,
    this.defaultValue,
    this.hideHelperText = false,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? label;
  final String? description;
  final bool disabled;
  final int? defaultValue;
  final bool hideHelperText;

  @override
  State<FluxerColorPickerField> createState() =>
      _FluxerColorPickerFieldState();
}

class _FluxerColorPickerFieldState extends State<FluxerColorPickerField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showError = false;

  int get _effectiveValue =>
      widget.value == 0 && widget.defaultValue != null
          ? widget.defaultValue!
          : widget.value;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _intToHex(_effectiveValue));
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FluxerColorPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.defaultValue != widget.defaultValue) {
      if (!_focusNode.hasFocus) {
        _controller.text = _intToHex(_effectiveValue);
        _showError = false;
      }
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitFromText();
    }
  }

  void _commitFromText() {
    final parsed = _parseHex(_controller.text);
    if (parsed == null) {
      setState(() {
        _showError = true;
        _controller.text = _intToHex(_effectiveValue);
      });
      return;
    }
    if (parsed != _effectiveValue) {
      widget.onChanged(parsed);
    }
    setState(() {
      _showError = false;
      _controller.text = _intToHex(parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    final displayColor = _intToColor(_effectiveValue);
    final iconColor =
        displayColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: EdgeInsets.only(bottom: layout.s1),
            child: Text(
              widget.label!,
              style: textStyles.label.copyWith(color: colors.textPrimary),
            ),
          ),
        SizedBox(
          height: _kInputHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: layout.radiusLg,
              border: Border.all(color: colors.backgroundModifierAccent),
            ),
            child: ClipRRect(
              borderRadius: layout.radiusLg,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !widget.disabled,
                      style: textStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: _showError
                            ? colors.statusDanger
                            : colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '#000000',
                        hintStyle: textStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          color: colors.textPrimaryMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: layout.s4,
                          vertical: layout.s2,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _commitFromText(),
                      onChanged: (_) {
                        if (_showError) {
                          setState(() => _showError = false);
                        }
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(7),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 1,
                    child: ColoredBox(color: colors.backgroundModifierAccent),
                  ),
                  FluxerPopout(
                    anchorBuilder: (context, toggle) => FluxerTappable(
                      enabled: !widget.disabled,
                      onTap: toggle,
                      semanticLabel: 'Open color picker',
                      builder: (context, states) => SizedBox(
                        width: _kSwatchWidth,
                        height: _kInputHeight,
                        child: ColoredBox(
                          color: displayColor,
                          child: Center(
                            child: Icon(
                              PhosphorIcons.eyedropper(
                                PhosphorIconsStyle.fill,
                              ),
                              size: 18,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    contentBuilder: (context, close) => _ColorPickerContent(
                      color: _intToColor(_effectiveValue),
                      onChanged: (color) {
                        final intValue = _colorToInt(color);
                        widget.onChanged(intValue);
                        _controller.text = _intToHex(intValue);
                        setState(() => _showError = false);
                      },
                      onReset: widget.defaultValue != null
                          ? () {
                              widget.onChanged(0);
                              _controller.text =
                                  _intToHex(widget.defaultValue!);
                              setState(() => _showError = false);
                              close();
                            }
                          : null,
                      hasCustomColor: widget.value != 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.description != null ||
            (!widget.hideHelperText && !_showError))
          Padding(
            padding: EdgeInsets.only(top: layout.s1_5),
            child: Text(
              widget.description ?? 'Type a hex color or use the picker.',
              style: textStyles.timestamp.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
          ),
        if (_showError)
          Padding(
            padding: EdgeInsets.only(top: layout.s1_5),
            child: Text(
              'Invalid color. Try a hex value like #FF5733.',
              style: textStyles.timestamp.copyWith(
                color: colors.statusDanger,
              ),
            ),
          ),
      ],
    );
  }
}

class _ColorPickerContent extends StatefulWidget {
  const _ColorPickerContent({
    required this.color,
    required this.onChanged,
    required this.hasCustomColor,
    this.onReset,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final VoidCallback? onReset;
  final bool hasCustomColor;

  @override
  State<_ColorPickerContent> createState() => _ColorPickerContentState();
}

class _ColorPickerContentState extends State<_ColorPickerContent> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(_ColorPickerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hsv = HSVColor.fromColor(widget.color);
    }
  }

  void _updateColor(HSVColor hsv) {
    setState(() => _hsv = hsv);
    widget.onChanged(hsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;

    return SizedBox(
      width: _kPopoverWidth,
      child: Padding(
        padding: EdgeInsets.all(layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorArea(
              hue: _hsv.hue,
              saturation: _hsv.saturation,
              value: _hsv.value,
              onChanged: (saturation, value) => _updateColor(
                _hsv.withSaturation(saturation).withValue(value),
              ),
            ),
            SizedBox(height: layout.s3),
            _HueSlider(
              hue: _hsv.hue,
              onChanged: (hue) => _updateColor(_hsv.withHue(hue)),
            ),
            if (widget.onReset != null) ...[
              SizedBox(height: layout.s2),
              FluxerTappable(
                enabled: widget.hasCustomColor,
                onTap: widget.onReset,
                builder: (context, states) => SizedBox(
                  width: double.infinity,
                  height: 24,
                  child: Center(
                    child: Text(
                      'Reset',
                      style: textStyles.bodySmall.copyWith(
                        color: widget.hasCustomColor
                            ? colors.textPrimary
                            : colors.textPrimaryMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorArea extends StatelessWidget {
  const _ColorArea({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  void _handleInteraction(Offset localPosition, Size size) {
    final s = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final v = 1.0 - (localPosition.dy / size.height).clamp(0.0, 1.0);
    onChanged(s, v);
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final size = Size(width, _kColorAreaHeight);
        return GestureDetector(
          onPanStart: (details) =>
              _handleInteraction(details.localPosition, size),
          onPanUpdate: (details) =>
              _handleInteraction(details.localPosition, size),
          onTapDown: (details) =>
              _handleInteraction(details.localPosition, size),
          child: SizedBox(
            width: width,
            height: _kColorAreaHeight,
            child: ClipRRect(
              borderRadius: layout.radiusSm,
              child: CustomPaint(
                painter: _ColorAreaPainter(hue: hue),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: saturation * width - _kThumbSize / 2,
                      top: (1.0 - value) * _kColorAreaHeight - _kThumbSize / 2,
                      child: _Thumb(
                        color: HSVColor.fromAHSV(1, hue, saturation, value)
                            .toColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorAreaPainter extends CustomPainter {
  _ColorAreaPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    final horizontalGradient = ui.Gradient.linear(
      rect.topLeft,
      rect.topRight,
      [Colors.white, hueColor],
    );
    canvas.drawRect(rect, Paint()..shader = horizontalGradient);

    final verticalGradient = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomLeft,
      [const Color(0x00000000), const Color(0xFF000000)],
    );
    canvas.drawRect(rect, Paint()..shader = verticalGradient);
  }

  @override
  bool shouldRepaint(_ColorAreaPainter oldDelegate) => oldDelegate.hue != hue;
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hue,
    required this.onChanged,
  });

  final double hue;
  final ValueChanged<double> onChanged;

  void _handleInteraction(Offset localPosition, double width) {
    final h = (localPosition.dx / width).clamp(0.0, 1.0) * 360;
    onChanged(h);
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanStart: (details) =>
              _handleInteraction(details.localPosition, width),
          onPanUpdate: (details) =>
              _handleInteraction(details.localPosition, width),
          onTapDown: (details) =>
              _handleInteraction(details.localPosition, width),
          child: SizedBox(
            width: width,
            height: _kHueTrackHeight,
            child: ClipRRect(
              borderRadius: layout.radiusSm,
              child: CustomPaint(
                painter: const _HueSliderPainter(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (hue / 360) * width - _kThumbSize / 2,
                      top: (_kHueTrackHeight - _kThumbSize) / 2,
                      child: _Thumb(
                        color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HueSliderPainter extends CustomPainter {
  const _HueSliderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = List<Color>.generate(
      7,
      (i) => HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
    );
    final stops = List<double>.generate(7, (i) => i / 6);
    final gradient = ui.Gradient.linear(
      rect.topLeft,
      rect.topRight,
      colors,
      stops,
    );
    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(_HueSliderPainter oldDelegate) => false;
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: _kThumbSize,
        height: _kThumbSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
