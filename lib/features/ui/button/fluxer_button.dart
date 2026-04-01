import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_size.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_variant.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FluxerButton extends StatelessWidget {
  const FluxerButton.primary({
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = FluxerButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.child,
    super.key,
  })  : _variant = FluxerButtonVariant.primary,
        _isCircle = false,
        _iconSizeOverride = null;

  const FluxerButton.secondary({
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = FluxerButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.child,
    super.key,
  })  : _variant = FluxerButtonVariant.secondary,
        _isCircle = false,
        _iconSizeOverride = null;

  const FluxerButton.dangerPrimary({
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = FluxerButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.child,
    super.key,
  })  : _variant = FluxerButtonVariant.dangerPrimary,
        _isCircle = false,
        _iconSizeOverride = null;

  const FluxerButton.dangerSecondary({
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = FluxerButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.child,
    super.key,
  })  : _variant = FluxerButtonVariant.dangerSecondary,
        _isCircle = false,
        _iconSizeOverride = null;

  const FluxerButton.inverted({
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = FluxerButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.child,
    super.key,
  })  : _variant = FluxerButtonVariant.inverted,
        _isCircle = false,
        _iconSizeOverride = null;

  const FluxerButton.invertedOutline({
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = FluxerButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.child,
    super.key,
  })  : _variant = FluxerButtonVariant.invertedOutline,
        _isCircle = false,
        _iconSizeOverride = null;

  const FluxerButton.ghost({
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = FluxerButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.child,
    super.key,
  })  : _variant = FluxerButtonVariant.ghost,
        _isCircle = false,
        _iconSizeOverride = null;

  const FluxerButton.circle({
    required this.onPressed,
    required IconData this.icon,
    FluxerButtonVariant variant = FluxerButtonVariant.primary,
    this.size = FluxerButtonSize.regular,
    double? iconSize,
    this.isLoading = false,
    super.key,
  })  : _variant = variant,
        _isCircle = true,
        _iconSizeOverride = iconSize,
        isSquare = true,
        label = null,
        trailingIcon = null,
        fitContent = false,
        child = null;

  final FluxerButtonVariant _variant;
  final bool _isCircle;
  final double? _iconSizeOverride;
  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final FluxerButtonSize size;
  final bool isSquare;
  final bool isLoading;
  final bool fitContent;
  final Widget? child;

  bool get _enabled => onPressed != null && !isLoading;

  BorderRadius get _borderRadius => BorderRadius.circular(
    _isCircle
        ? size.height / 2
        : switch (size) {
            FluxerButtonSize.regular || FluxerButtonSize.small => 8.0,
            FluxerButtonSize.compact ||
            FluxerButtonSize.superCompact => 6.0,
          },
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = context.motion;
    final foreground = _variant.textColor(colors);

    return FluxerTappable(
      onTap: _enabled ? onPressed : null,
      enabled: _enabled,
      semanticLabel: label,
      builder: (context, states) {
        final isHovered = states.contains(WidgetState.hovered);
        final fill = isHovered
            ? _variant.activeFill(colors)
            : _variant.fill(colors);
        final border = _variant.borderColor(colors);

        return AnimatedContainer(
          duration: motion.fast,
          curve: motion.curve,
          constraints: BoxConstraints(
            minHeight: size.height,
            minWidth: isSquare ? size.height : (fitContent ? 0 : 96),
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: _borderRadius,
            border: border != null ? Border.all(color: border) : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSquare ? 0 : size.padding,
          ),
          child: _buildContent(foreground),
        );
      },
    );
  }

  Widget _buildContent(Color foreground) {
    final effectiveIconSize = _iconSizeOverride ?? size.iconSize;

    if (isLoading) {
      return Center(
        child: SizedBox(
          width: effectiveIconSize,
          height: effectiveIconSize,
          child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
        ),
      );
    }

    final contentWidgets = <Widget>[];

    if (icon != null) {
      contentWidgets.add(
        PhosphorIcon(icon!, size: effectiveIconSize, color: foreground),
      );
    }

    if (child != null) {
      contentWidgets.add(Flexible(child: child!));
    } else if (label != null) {
      contentWidgets.add(
        Flexible(
          child: Text(
            label!,
            style: TextStyle(
              fontSize: size.fontSize,
              fontWeight: FontWeight.w600,
              color: foreground,
              height: 1.4,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }

    if (trailingIcon != null) {
      contentWidgets.add(
        PhosphorIcon(trailingIcon!, size: size.iconSize, color: foreground),
      );
    }

    return Row(
      mainAxisSize: fitContent || isSquare
          ? MainAxisSize.min
          : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _addSpacing(contentWidgets),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets) {
    if (widgets.length <= 1) {
      return widgets;
    }
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(const SizedBox(width: 8));
      }
    }
    return result;
  }
}
