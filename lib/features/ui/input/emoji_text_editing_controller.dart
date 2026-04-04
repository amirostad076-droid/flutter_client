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
