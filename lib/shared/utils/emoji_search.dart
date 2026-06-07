/// Pure, dependency-free emoji search ranking primitives shared by the emoji
/// picker and the composer autocomplete. Mirrors the Fluxer web app's
/// `EmojiSearchIndex` tier model and `Emoji.normalizeEmojiSearchQuery` so both
/// clients return identical results and ordering.
library;

/// Relevance tiers (lower = better). Mirrors web `MATCH_TIER`.
const int emojiTierExactName = 0;
const int emojiTierNameStartsWith = 1;
const int emojiTierNameBoundary = 2;
const int emojiTierNameContains = 3;
const int emojiTierKeywordStartsWith = 4;
const int emojiTierKeywordContains = 5;

const Map<String, String> _kPunctuationQueryAliases = <String, String>{
  '!': 'exclamation',
  '!!': 'bangbang',
  '!?': 'interrobang',
  '?': 'question',
  '+1': 'thumbsup',
  '-1': 'thumbsdown',
};

final RegExp _kLeadingColons = RegExp('^:+');
final RegExp _kTrailingColons = RegExp(r':+$');

const int _kCodeUnitUnderscore = 0x5F; // _
const int _kCodeUnitLowerS = 0x73; // s
const int _kCodeUnitUpperA = 0x41; // A
const int _kCodeUnitUpperZ = 0x5A; // Z

/// Normalizes a raw emoji query to the canonical lowercase form used for
/// matching: trims, strips wrapping colons, converts spaces to underscores,
/// applies punctuation aliases (`+1` -> `thumbsup`, `-1` -> `thumbsdown`,
/// `?` -> `question`, ...), then lowercases. Mirrors web
/// `normalizeEmojiSearchQuery` followed by the index's `normalizeQuery`.
String normalizeEmojiSearchQuery(String raw) {
  final String stripped = raw
      .trim()
      .replaceFirst(_kLeadingColons, '')
      .replaceFirst(_kTrailingColons, '')
      .replaceAll(' ', '_');
  return (_kPunctuationQueryAliases[stripped] ?? stripped).toLowerCase();
}

bool _isUpperAsciiLetter(int codeUnit) =>
    codeUnit >= _kCodeUnitUpperA && codeUnit <= _kCodeUnitUpperZ;

/// Whether the character of [name] at [index] is a word boundary for
/// camelCase/underscore matching: out of range, `_`, or an uppercase ASCII
/// letter. Mirrors web `isNameBoundary` (out-of-range == `undefined`).
bool _isNameBoundaryAt(String name, int index) {
  if (index < 0 || index >= name.length) {
    return true;
  }
  final int c = name.codeUnitAt(index);
  return c == _kCodeUnitUnderscore || _isUpperAsciiLetter(c);
}

/// Whether [query] (already lowercased) matches at a word boundary inside
/// [name], including the trailing plural-`s` edge case. [lowerName] must be the
/// lowercased form of [name]; both share indices (shortcodes are ASCII).
/// Mirrors web `hasBoundaryMatch`.
bool emojiHasBoundaryMatch(String name, String lowerName, String query) {
  if (query.isEmpty) {
    return false;
  }
  int index = lowerName.indexOf(query);
  while (index != -1) {
    if (_isNameBoundaryAt(name, index - 1)) {
      final int end = index + query.length;
      if (_isNameBoundaryAt(name, end)) {
        return true;
      }
      if (end < lowerName.length &&
          lowerName.codeUnitAt(end) == _kCodeUnitLowerS &&
          _isNameBoundaryAt(name, end + 1)) {
        return true;
      }
    }
    index = lowerName.indexOf(query, index + 1);
  }
  return false;
}

/// Best (lowest) match tier for an emoji's names/keywords against [query]
/// (already normalized + lowercased), or `null` when nothing matches.
/// [namesLower]/[keywordsLower] are the lowercased forms of [names]/keywords.
/// Mirrors web `getEmojiMatchTier`. Callers MUST short-circuit empty queries.
int? emojiMatchTier({
  required List<String> names,
  required List<String> namesLower,
  required List<String> keywordsLower,
  required String query,
}) {
  for (final String lower in namesLower) {
    if (lower == query) {
      return emojiTierExactName;
    }
  }
  for (final String lower in namesLower) {
    if (lower.startsWith(query)) {
      return emojiTierNameStartsWith;
    }
  }
  for (int i = 0; i < names.length; i++) {
    if (emojiHasBoundaryMatch(names[i], namesLower[i], query)) {
      return emojiTierNameBoundary;
    }
  }
  for (final String lower in namesLower) {
    if (lower.contains(query)) {
      return emojiTierNameContains;
    }
  }
  var hasKeywordContains = false;
  for (final String lower in keywordsLower) {
    if (lower == query || lower.startsWith(query)) {
      return emojiTierKeywordStartsWith;
    }
    if (lower.contains(query)) {
      hasKeywordContains = true;
    }
  }
  return hasKeywordContains ? emojiTierKeywordContains : null;
}
