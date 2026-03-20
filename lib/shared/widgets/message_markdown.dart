import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MessageMarkdown extends StatelessWidget {
  const MessageMarkdown({
    required this.data,
    this.baseStyle,
    this.selectable = false,
    super.key,
  });

  final String data;
  final TextStyle? baseStyle;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = baseStyle ?? context.textStyles.messageText;

    final sheet = MarkdownStyleSheet(
      p: style,
      a: style.copyWith(
        color: colors.textLink,
        decoration: TextDecoration.none,
      ),
      strong: style.copyWith(fontWeight: FontWeight.w700),
      em: style.copyWith(fontStyle: FontStyle.italic),
      code: style.copyWith(
        fontSize: (style.fontSize ?? 16) * 0.85,
        backgroundColor: colors.bgCode,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: colors.bgCodeBlock,
        borderRadius: BorderRadius.circular(4),
      ),
      codeblockPadding: const EdgeInsets.all(8),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.bgBlockquote, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 10),
      h1: style.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      h2: style.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      h3: style.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      listBullet: style,
      tableHead: style.copyWith(fontWeight: FontWeight.w600),
      tableBody: style,
      tableBorder: TableBorder.all(color: colors.borderColor),
    );

    return MarkdownBody(
      data: data,
      styleSheet: sheet,
      selectable: selectable,
      inlineSyntaxes: [_SpoilerSyntax()],
      builders: {_SpoilerSyntax.tag: _SpoilerBuilder()},
      extensionSet: md.ExtensionSet.gitHubFlavored,
      onTapLink: (_, href, _) => _onTapLink(href),
    );
  }

  void _onTapLink(String? href) {
    if (href == null) {
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null) {
      return;
    }
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }
}

/// Parses spoiler syntax /| test ||.
class _SpoilerSyntax extends md.InlineSyntax {
  _SpoilerSyntax() : super(r'\|\|(.+?)\|\|');

  static const tag = 'spoiler';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match[1];
    if (content == null || content.isEmpty) {
      return false;
    }
    parser.addNode(md.Element.text(tag, content));
    return true;
  }
}

class _SpoilerBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) =>
      _SpoilerSpan(
        child: Text(element.textContent, style: preferredStyle ?? parentStyle),
      );
}

class _SpoilerSpan extends StatefulWidget {
  const _SpoilerSpan({required this.child});

  final Widget child;

  @override
  State<_SpoilerSpan> createState() => _SpoilerSpanState();
}

class _SpoilerSpanState extends State<_SpoilerSpan>
    with SingleTickerProviderStateMixin {
  static const _kDuration = Duration(milliseconds: 200);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  var _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isRevealed = !_isRevealed);
    unawaited(_isRevealed ? _controller.forward() : _controller.reverse());
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _toggle,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          FadeTransition(opacity: _opacity, child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: _kDuration,
                opacity: _isRevealed ? 0 : 1,
                child: ColoredBox(color: context.colors.spoilerBackground),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
