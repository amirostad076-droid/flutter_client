import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/shared/markdown/fluxer_markdown_adapter.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';

class MessageMarkdown extends StatelessWidget {
  const MessageMarkdown({
    required this.data,
    this.baseStyle,
    this.selectable = false,
    this.channelId,
    this.markdownContext = FluxerMarkdownContext.standardWithJumbo,
    this.revealSpoilers = false,
    super.key,
  });

  final String data;
  final TextStyle? baseStyle;
  final bool selectable;
  final String? channelId;
  final FluxerMarkdownContext markdownContext;
  final bool revealSpoilers;

  @override
  Widget build(BuildContext context) {
    return FluxerMarkdown(
      data: data,
      config: createFluxerMarkdownConfig(
        context: context,
        channelId: channelId,
        revealSpoilers: revealSpoilers,
      ),
      baseStyle: baseStyle ?? context.textStyles.messageText,
      selectable: selectable,
      context: markdownContext,
    );
  }
}
