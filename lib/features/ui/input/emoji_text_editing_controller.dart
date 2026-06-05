import 'package:fluxer_app/features/ui/input/emoji_inline_token.dart';
import 'package:fluxer_app/features/ui/input/inline_token_text_editing_controller.dart';

/// An [InlineTokenTextEditingController] specialised for emoji-only fields
/// (bios, autocomplete inputs): it loads and inserts emoji as inline `:name:`
/// chips while [actualText] preserves their wire shortcodes for sending.
class EmojiTextEditingController extends InlineTokenTextEditingController {
  /// The editing text with emoji sentinels expanded to their wire forms.
  String get actualText => toWireText();

  /// The length of [actualText] without materializing the string.
  int get actualTextLength => wireLength;

  /// Replaces previously loaded tokens, rewriting any emoji shortcodes and
  /// custom-emoji markdown in [rawText] into inline chips.
  void loadWithTokens(String rawText) {
    clearTokens();
    text = substituteEmojiTokens(rawText, allocateToken);
  }
}
