import 'package:flutter/widgets.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/emoji_search_bar.dart'
    show kSkinToneSurrogates, skinToneToName;

/// Inserts an emoji selection into [controller] at the current caret.
///
/// Custom emoji ([surrogates] beginning with `<`) are inserted verbatim;
/// unicode emoji become a `:name:` shortcode (or `:name::tone:` when a
/// skin-tone modifier is present). The caret is left after the inserted token.
void insertEmojiToken(
  TextEditingController controller,
  String name,
  String surrogates,
) {
  final String token = surrogates.startsWith('<')
      ? surrogates
      : _buildUnicodeShortcode(name, surrogates);
  final String text = controller.text;
  final TextSelection selection = controller.selection;
  final int pos = selection.isValid ? selection.baseOffset : text.length;
  final String newText = text.substring(0, pos) + token + text.substring(pos);
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: pos + token.length),
  );
}

String _buildUnicodeShortcode(String name, String surrogates) {
  for (final String tone in kSkinToneSurrogates) {
    if (surrogates.contains(tone)) {
      final String? toneName = skinToneToName(tone);
      if (toneName != null) {
        return ':$name::$toneName:';
      }
      break;
    }
  }
  return ':$name:';
}
