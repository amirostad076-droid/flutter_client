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

bool _languagesRegistered = false;

void _ensureLanguagesRegistered() {
  if (_languagesRegistered) return;
  _languagesRegistered = true;
  _kLanguages.forEach(highlight.registerLanguage);
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
      builders: {
        _SpoilerSyntax.tag: _SpoilerBuilder(),
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