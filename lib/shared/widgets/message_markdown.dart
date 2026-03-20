import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
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
