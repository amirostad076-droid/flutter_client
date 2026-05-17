const _kTwemojiCdn = 'https://fluxerstatic.com/emoji';

String emojiToCodePoints(String emoji) {
  final containsZwj = emoji.contains('\u200D');
  final processed = containsZwj ? emoji : emoji.replaceAll('\uFE0F', '');
  return processed.runes
      .map((r) => r.toRadixString(16).replaceAll(RegExp('^0+'), ''))
      .where((s) => s.isNotEmpty)
      .join('-');
}

String? getTwemojiUrl(String unicode) {
  final codePoints = emojiToCodePoints(unicode);
  if (codePoints.isEmpty) {
    return null;
  }
  return '$_kTwemojiCdn/$codePoints.svg';
}

String getCustomEmojiMarkdown({
  required String name,
  required String id,
  bool animated = false,
}) => '<${animated ? 'a' : ''}:$name:$id>';
