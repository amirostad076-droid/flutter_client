/// Compact 1-2 character label for a guild/channel/user name.
///
/// Two-or-more-word names use the first letter of the first two words.
/// Single-word names take up to the first two characters. Empty input
/// resolves to `'?'`.
String abbreviateGuildName(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return '?';
  }
  final List<String> words = value
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .toList();
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return value.substring(0, value.length.clamp(0, 2)).toUpperCase();
}
