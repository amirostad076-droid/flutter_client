import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/emoji_search_bar.dart'
    show kSkinToneSurrogates, skinToneToName;

class EmojiSegment {
  const EmojiSegment({required this.displayName, required this.token});

  final String displayName;
  final String token;
}

class EmojiTextEditingController extends TextEditingController {
  final Map<String, EmojiSegment> _segments = {};
  int _nextSentinelIndex = 0;

  String _allocateSentinel(EmojiSegment segment) {
    final codePoint = 0xF0000 + _nextSentinelIndex++;
    final sentinel = String.fromCharCode(codePoint);
    _segments[sentinel] = segment;
    return sentinel;
  }

  String get actualText {
    final buffer = StringBuffer();
    for (final char in text.runes) {
      final s = String.fromCharCode(char);
      final segment = _segments[s];
      if (segment != null) {
        buffer.write(segment.token);
      } else {
        buffer.write(s);
      }
    }
    return buffer.toString();
  }

  int get actualTextLength => actualText.length;

  void insertEmoji(String name, String surrogates) {
    final String token;
    if (surrogates.startsWith('<')) {
      token = surrogates;
    } else {
      token = _buildUnicodeShortcode(name, surrogates);
    }

    final displayName = name;
    final sentinel = _allocateSentinel(
      EmojiSegment(displayName: displayName, token: token),
    );

    final sel = selection;
    final pos = sel.isValid ? sel.baseOffset : text.length;
    final newText = text.substring(0, pos) + sentinel + text.substring(pos);
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + sentinel.length),
    );
  }

  String _buildUnicodeShortcode(String name, String surrogates) {
    for (final tone in kSkinToneSurrogates) {
      if (surrogates.contains(tone)) {
        final toneName = skinToneToName(tone);
        if (toneName != null) {
          return ':$name::$toneName:';
        }
        break;
      }
    }
    return ':$name:';
  }

  void loadWithTokens(String rawText) {
    _segments.clear();
    _nextSentinelIndex = 0;

    // Custom emoji: <a:name:id> or <:name:id>
    final customPattern = RegExp(r'<(a?):([a-zA-Z0-9_]+):(\d+)>');
    // Unicode with skin tone: :name::skin-tone-N:
    final skinTonePattern = RegExp(
      r':([a-zA-Z0-9_+\-]+)::skin-tone-([1-5]):',
    );
    // Plain unicode: :name:
    final plainPattern = RegExp(r':([a-zA-Z0-9_+\-]+):');

    var result = rawText;

    // Process custom first.
    result = result.replaceAllMapped(customPattern, (match) {
      final animated = match.group(1)!;
      final name = match.group(2)!;
      final id = match.group(3)!;
      final token = '<$animated:$name:$id>';
      return _allocateSentinel(
        EmojiSegment(displayName: name, token: token),
      );
    });

    // Then skin-tone unicode.
    result = result.replaceAllMapped(skinTonePattern, (match) {
      final name = match.group(1)!;
      final tone = match.group(2)!;
      final token = ':$name::skin-tone-$tone:';
      return _allocateSentinel(
        EmojiSegment(displayName: name, token: token),
      );
    });

    // Then plain unicode.
    result = result.replaceAllMapped(plainPattern, (match) {
      final name = match.group(1)!;
      final token = ':$name:';
      return _allocateSentinel(
        EmojiSegment(displayName: name, token: token),
      );
    });

    text = result;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <InlineSpan>[];
    final buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        children.add(TextSpan(text: buffer.toString(), style: style));
        buffer.clear();
      }
    }

    final currentChars = <String>{};
    for (final rune in text.runes) {
      currentChars.add(String.fromCharCode(rune));
    }
    _segments.removeWhere((key, _) => !currentChars.contains(key));

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final segment = _segments[char];
      if (segment != null) {
        flushBuffer();
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _EmojiChip(name: segment.displayName),
          ),
        );
      } else {
        buffer.write(char);
      }
    }
    flushBuffer();

    if (children.isEmpty) {
      return TextSpan(text: text, style: style);
    }
    return TextSpan(style: style, children: children);
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.backgroundModifierAccent,
          borderRadius: layout.radiusSm,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: layout.s1,
            vertical: 1,
          ),
          child: Text(
            ':$name:',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
