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
    // Placeholder — implemented in Task 2.
    return TextSpan(text: text, style: style);
  }
}
