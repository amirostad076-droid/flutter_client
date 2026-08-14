import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_markdown/src/utils/code_block_highlight.dart';
import 'package:fluxer_markdown/src/utils/highlight_languages.dart';

void main() {
  setUp(ensureFluxerMarkdownLanguagesRegistered);

  test('caches highlight spans by code, language, and brightness', () {
    const String code = 'void main() {}';
    final List<TextSpan> first = highlightedCodeSpans(
      code: code,
      language: 'dart',
      isDark: false,
    );
    final List<TextSpan> second = highlightedCodeSpans(
      code: code,
      language: 'dart',
      isDark: false,
    );
    expect(identical(first, second), isTrue);
    expect(first, isNotEmpty);

    final List<TextSpan> dark = highlightedCodeSpans(
      code: code,
      language: 'dart',
      isDark: true,
    );
    expect(identical(first, dark), isFalse);
  });
}
