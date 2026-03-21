import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TextLink extends StatefulWidget {
  const TextLink(
    this.data, {
    required this.link,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.isSelectable = false,
    super.key,
  });
  final String data;
  final String link;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final bool isSelectable;

  @override
  State<TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<TextLink> {
  bool isHovering = false;

  void onTap() {
    unawaited(
      launchUrlString(widget.link, mode: LaunchMode.externalApplication),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle linkStyle =
        (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
          decoration: isHovering
              ? TextDecoration.underline
              : TextDecoration.none,
        );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: Semantics(
        link: true,
        linkUrl: Uri.parse(widget.link),
        onTap: onTap,
        child: GestureDetector(
          onTap: onTap,
          child: ColoredBox(
            color: Colors.transparent,
            child: Text(
              widget.data,
              style: linkStyle,
              strutStyle: widget.strutStyle,
              textAlign: widget.textAlign,
              textDirection: widget.textDirection,
              locale: widget.locale,
              softWrap: widget.softWrap,
              overflow: widget.overflow,
              textScaler: widget.textScaler,
              maxLines: widget.maxLines,
              semanticsLabel: widget.semanticsLabel,
              textWidthBasis: widget.textWidthBasis,
              textHeightBehavior: widget.textHeightBehavior,
            ),
          ),
        ),
      ),
    );
  }
}
