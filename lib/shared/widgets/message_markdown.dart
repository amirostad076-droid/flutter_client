import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:highlight/highlight.dart' show highlight, Mode;
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/diff.dart';
import 'package:highlight/languages/dockerfile.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/graphql.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/lua.dart';
import 'package:highlight/languages/makefile.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/nginx.dart';
import 'package:highlight/languages/objectivec.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/powershell.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/scala.dart';
import 'package:highlight/languages/scss.dart';
import 'package:highlight/languages/shell.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxeron/shared/utils/emoji_registry.dart';
import 'package:fluxeron/shared/utils/emoji_utils.dart';
import 'package:fluxeron/shared/widgets/message_alert.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

// sup lang list (test)
final Map<String, Mode> _kLanguages = {
  'bash': bash,
  'sh': bash,
  'shell': shell,
  'zsh': bash,
  'c': cpp,
  'c++': cpp,
  'cpp': cpp,
  'cs': cs,
  'csharp': cs,
  'css': css,
  'dart': dart,
  'diff': diff,
  'docker': dockerfile,
  'dockerfile': dockerfile,
  'go': go,
  'graphql': graphql,
  'java': java,
  'javascript': javascript,
  'js': javascript,
  'json': json,
  'kotlin': kotlin,
  'lua': lua,
  'makefile': makefile,
  'markdown': markdown,
  'md': markdown,
  'nginx': nginx,
  'objc': objectivec,
  'objectivec': objectivec,
  'php': php,
  'powershell': powershell,
  'ps1': powershell,
  'py': python,
  'python': python,
  'rb': ruby,
  'rs': rust,
  'ruby': ruby,
  'rust': rust,
  'scala': scala,
  'scss': scss,
  'sql': sql,
  'swift': swift,
  'ts': typescript,
  'typescript': typescript,
  'html': xml,
  'xml': xml,
  'yaml': yaml,
  'yml': yaml,
};

const _kJumboMaxCount = 6;
const _kEmojiSizeNormal = 22.0;
const _kEmojiSizeJumbo = 48.0;

bool _languagesRegistered = false;

bool isJumboEmoji(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;

  final tokenRe = RegExp(
    r':[a-zA-Z0-9_+\-]+:|<a?:[a-zA-Z0-9_]+:\d+>|\s',
  );
  final emojiRe = RegExp(r':[a-zA-Z0-9_+\-]+:|<a?:[a-zA-Z0-9_]+:\d+>');

  final withoutTokens = trimmed.replaceAll(tokenRe, '');
  if (withoutTokens.isNotEmpty) return false;

  final count = emojiRe.allMatches(trimmed).length;
  return count >= 1 && count <= _kJumboMaxCount;
}

void _ensureLanguagesRegistered() {
  if (_languagesRegistered) return;
  _languagesRegistered = true;
  _kLanguages.forEach(highlight.registerLanguage);
}

sealed class _Segment {}

final class _MarkdownSegment extends _Segment {
  _MarkdownSegment(this.text);
  final String text;
}

final class _AlertSegment extends _Segment {
  _AlertSegment({required this.type, required this.body});
  final AlertType type;
  final String body;
}

/// Parses alert blocks out of [text], returns interleaved markdown and alert segmentss
List<_Segment> _parseSegments(String text) {
  final openRe = RegExp(
    r'^>\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*$',
    caseSensitive: false,
  );
  final lineRe = RegExp(r'^>\s?(.*)$');

  final lines = text.split('\n');
  final segments = <_Segment>[];
  final mdBuffer = StringBuffer();

  int i = 0;
  while (i < lines.length) {
    final match = openRe.firstMatch(lines[i]);
    if (match == null) {
      mdBuffer.writeln(lines[i]);
      i++;
      continue;
    }

    final pending = mdBuffer.toString().trim();
    if (pending.isNotEmpty) {
      segments.add(_MarkdownSegment(pending));
      mdBuffer.clear();
    }

    final rawType = match.group(1)!;
    final type = AlertType.tryParse(rawType)!;
    i++;

    final bodyLines = <String>[];
    while (i < lines.length) {
      final bodyMatch = lineRe.firstMatch(lines[i]);
      if (bodyMatch == null) break;
      bodyLines.add(bodyMatch.group(1) ?? '');
      i++;
    }

    segments.add(_AlertSegment(type: type, body: bodyLines.join('\n').trim()));
  }

  final remaining = mdBuffer.toString().trim();
  if (remaining.isNotEmpty) {
    segments.add(_MarkdownSegment(remaining));
  }

  return segments;
}

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
    _ensureLanguagesRegistered();

    final colors = context.colors;
    final style = baseStyle ?? context.textStyles.messageText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          left: BorderSide(color: colors.interactiveMuted, width: 4),
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

    final segments = _parseSegments(data);

    if (segments.length == 1 && segments.first is _MarkdownSegment) {
      return _buildMarkdown(
        (segments.first as _MarkdownSegment).text,
        sheet,
        isDark,
        style,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) {
        return switch (seg) {
          _MarkdownSegment(:final text) => _buildMarkdown(
            text,
            sheet,
            isDark,
            style,
          ),
          _AlertSegment(:final type, :final body) => MessageAlert(
            type: type,
            body: body,
            baseStyle: style,
          ),
        };
      }).toList(),
    );
  }

  Widget _buildMarkdown(
    String text,
    MarkdownStyleSheet sheet,
    bool isDark,
    TextStyle style,
  ) {
    final jumbo = isJumboEmoji(text);
    return MarkdownBody(
      data: text,
      styleSheet: sheet,
      selectable: selectable,
      inlineSyntaxes: [
        _SpoilerSyntax(),
        _UnicodeEmojiSyntax(),
        _CustomEmojiSyntax(),
      ],
      builders: {
        _SpoilerSyntax.tag: _SpoilerBuilder(),
        _UnicodeEmojiSyntax.tag: _EmojiBuilder(baseStyle: style, jumbo: jumbo),
        _CustomEmojiSyntax.tag: _EmojiBuilder(baseStyle: style, jumbo: jumbo),
        'code': _CodeBlockBuilder(isDark: isDark, baseStyle: style),
      },
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

/// Parses spoiler syntax ||text||.
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


class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.isDark, required this.baseStyle});

  final bool isDark;
  final TextStyle baseStyle;

  static const _kPadding = EdgeInsets.all(12);
  static const _kRadius = BorderRadius.all(Radius.circular(4));

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final rawClass = (element.attributes['class'] ?? '').trim();
    if (!rawClass.startsWith('language-')) {
      return const SizedBox.shrink();
    }

    final rawLang = rawClass
        .replaceFirst('language-', '')
        .toLowerCase();

    var code = element.textContent;
    if (code.endsWith('\n')) {
      code = code.substring(0, code.length - 1);
    }

    final knownLang = _kLanguages.containsKey(rawLang) ? rawLang : null;

    // No matching language but label exists, show it as the first line
    if (knownLang == null && rawLang.isNotEmpty) {
      code = '$rawLang\n$code';
    }

    final colors = context.colors;
    final bgColor = isDark
        ? (vs2015Theme['root']?.backgroundColor ?? colors.bgCodeBlock)
        : (githubTheme['root']?.backgroundColor ?? colors.bgCodeBlock);

    if (knownLang == null) {
      return _PlainCodeBlock(code: code, bgColor: bgColor, baseStyle: baseStyle);
    }

    return ClipRRect(
      borderRadius: _kRadius,
      child: HighlightView(
        code,
        language: knownLang,
        theme: isDark ? vs2015Theme : githubTheme,
        padding: _kPadding,
        textStyle: baseStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: (baseStyle.fontSize ?? 16) * 0.85,
        ),
      ),
    );
  }
}

class _PlainCodeBlock extends StatelessWidget {
  const _PlainCodeBlock({
    required this.code,
    required this.bgColor,
    required this.baseStyle,
  });

  final String code;
  final Color bgColor;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    ),
    padding: const EdgeInsets.all(12),
    child: Text(
      code,
      style: baseStyle.copyWith(
        fontFamily: 'monospace',
        fontSize: (baseStyle.fontSize ?? 16) * 0.85,
      ),
    ),
  );
}

class _UnicodeEmojiSyntax extends md.InlineSyntax {
  _UnicodeEmojiSyntax() : super(r':([a-zA-Z0-9_+\-]+):');

  static const tag = 'emoji-unicode';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final name = match[1];
    if (name == null || name.isEmpty) return false;
    final surrogate = EmojiRegistry.resolveSync(name);
    if (surrogate == null) return false;
    final el = md.Element.text(tag, name)
      ..attributes['surrogate'] = surrogate;
    parser.addNode(el);
    return true;
  }
}

class _CustomEmojiSyntax extends md.InlineSyntax {
  _CustomEmojiSyntax() : super(r'<(a?):([a-zA-Z0-9_]+):(\d+)>');

  static const tag = 'emoji-custom';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final animated = match[1] == 'a';
    final name = match[2] ?? '';
    final id = match[3];
    if (id == null) return false;
    final el = md.Element.text(tag, name)
      ..attributes['id'] = id
      ..attributes['animated'] = animated.toString();
    parser.addNode(el);
    return true;
  }
}

class _EmojiBuilder extends MarkdownElementBuilder {
  _EmojiBuilder({required this.baseStyle, this.jumbo = false});

  final TextStyle baseStyle;
  final bool jumbo;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final size = jumbo ? _kEmojiSizeJumbo : _kEmojiSizeNormal;
    if (element.tag == _CustomEmojiSyntax.tag) {
      return _buildCustom(element, size);
    }
    return _buildUnicode(element, size);
  }

  Widget _buildUnicode(md.Element element, double size) {
    final surrogate = element.attributes['surrogate'] ?? element.textContent;
    final url = getTwemojiUrl(surrogate);
    if (url == null) {
      return Text(surrogate, style: TextStyle(fontSize: size));
    }
    return SvgPicture.network(
      url,
      width: size,
      height: size,
      placeholderBuilder: (_) => Text(
        surrogate,
        style: TextStyle(fontSize: size),
      ),
    );
  }

  Widget _buildCustom(md.Element element, double size) {
    final id = element.attributes['id'] ?? '';
    final animated = element.attributes['animated'] == 'true';
    final name = element.textContent;
    final cdnSize = jumbo ? 240 : 96;
    final url = getCustomEmojiUrl(id: id, animated: animated, size: cdnSize);
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Text(':$name:'),
    );
  }
}