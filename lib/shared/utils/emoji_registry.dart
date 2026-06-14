import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fluxer_app/shared/utils/emoji_search.dart';

class EmojiEntry {
  EmojiEntry({
    required this.names,
    required this.surrogates,
    required this.category,
    required this.spriteIndex,
    this.keywords = const <String>[],
    this.diversityIndex,
    this.hasDiversity = false,
  }) : namesLower = names.map((n) => n.toLowerCase()).toList(growable: false),
       keywordsLower = keywords
           .map((k) => k.toLowerCase())
           .toList(growable: false);

  final List<String> names;
  final List<String> namesLower;
  final List<String> keywords;
  final List<String> keywordsLower;
  final String surrogates;
  final String category;
  final int spriteIndex;
  final int? diversityIndex;

  /// True if this emoji supports skin tone modifiers.
  final bool hasDiversity;

  String get primaryName => names.first;
}

const List<String> kEmojiCategoryOrder = [
  'people',
  'nature',
  'food',
  'activity',
  'travel',
  'objects',
  'symbols',
  'flags',
];

class EmojiRegistry {
  EmojiRegistry._();

  static const _kAssetPath = 'assets/emojis.json';

  static Map<String, String>? _nameToSurrogate;
  static Map<String, EmojiEntry>? _nameToEntry;
  static Map<String, EmojiEntry>? _surrogateToEntry;
  static Map<String, List<EmojiEntry>>? _categories;
  static List<EmojiEntry>? _allEmojis;
  static RegExp? _unicodeEmojiRegex;

  static Future<String?> resolve(String name) async {
    _nameToSurrogate ??= await _loadNameMap();
    return _nameToSurrogate![name];
  }

  static String? resolveSync(String name) => _nameToSurrogate?[name];
  static RegExp? get unicodeEmojiRegexSync => _unicodeEmojiRegex;

  static Map<String, List<EmojiEntry>> get categories => _categories ?? {};

  static List<EmojiEntry> get allEmojis => _allEmojis ?? [];

  static EmojiEntry? entryByName(String name) => _nameToEntry?[name];

  static EmojiEntry? entryBySurrogates(String surrogates) =>
      _surrogateToEntry?[surrogates];

  static Future<void> ensureLoaded() => preload();

  static Future<void> preload() async {
    if (_categories != null && _unicodeEmojiRegex != null) {
      return;
    }
    final raw = await rootBundle.loadString(_kAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _parseAll(json);
  }

  static void _parseAll(Map<String, dynamic> json) {
    final nameMap = <String, String>{};
    final entryMap = <String, EmojiEntry>{};
    final surrogateMap = <String, EmojiEntry>{};
    final cats = <String, List<EmojiEntry>>{};
    final all = <EmojiEntry>[];
    final unicodeSurrogates = <String>{};
    var spriteIndex = 0;
    var diversityIndex = 0;

    for (final category in kEmojiCategoryOrder) {
      final entries = json[category] as List<dynamic>?;
      if (entries == null) {
        continue;
      }

      final list = <EmojiEntry>[];
      for (final entry in entries) {
        final obj = entry as Map<String, dynamic>;
        final surrogates = obj['surrogates'] as String? ?? '';
        if (surrogates.isEmpty) {
          continue;
        }
        unicodeSurrogates.add(surrogates);

        final names = (obj['names'] as List<dynamic>).cast<String>();
        final keywords =
            (obj['keywords'] as List<dynamic>?)?.cast<String>() ??
            const <String>[];
        final hasDiversity = obj.containsKey('skins');
        final emoji = EmojiEntry(
          names: names,
          surrogates: surrogates,
          keywords: keywords,
          category: category,
          spriteIndex: spriteIndex,
          diversityIndex: hasDiversity ? diversityIndex : null,
          hasDiversity: hasDiversity,
        );
        if (hasDiversity) {
          diversityIndex++;
        }
        spriteIndex++;
        list.add(emoji);
        all.add(emoji);
        surrogateMap[surrogates] = emoji;
        for (final name in names) {
          nameMap[name] = surrogates;
          entryMap[name] = emoji;
        }

        final skins = obj['skins'] as List<dynamic>?;
        if (skins != null) {
          for (final skin in skins) {
            final skinObj = skin as Map<String, dynamic>;
            final skinSurrogates = skinObj['surrogates'] as String? ?? '';
            if (skinSurrogates.isEmpty) {
              continue;
            }
            unicodeSurrogates.add(skinSurrogates);
          }
        }
      }
      cats[category] = list;
    }

    _nameToSurrogate = nameMap;
    _nameToEntry = entryMap;
    _surrogateToEntry = surrogateMap;
    _categories = cats;
    _allEmojis = all;
    _unicodeEmojiRegex = _buildUnicodeEmojiRegex(unicodeSurrogates);
  }

  static Future<Map<String, String>> _loadNameMap() async {
    await preload();
    return _nameToSurrogate!;
  }

  static RegExp? _buildUnicodeEmojiRegex(Set<String> surrogates) {
    if (surrogates.isEmpty) {
      return null;
    }

    final ordered = surrogates.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = ordered.map(RegExp.escape).join('|');
    if (pattern.isEmpty) {
      return null;
    }
    return RegExp(pattern);
  }

  static List<EmojiEntry> search(String query) {
    final q = normalizeEmojiSearchQuery(query);
    if (q.isEmpty) {
      return <EmojiEntry>[];
    }
    final entries = allEmojis;
    final ranked = <({EmojiEntry entry, int tier, int order})>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final tier = emojiMatchTier(
        names: e.names,
        namesLower: e.namesLower,
        keywordsLower: e.keywordsLower,
        query: q,
      );
      if (tier == null) {
        continue;
      }
      ranked.add((entry: e, tier: tier, order: i));
    }
    ranked.sort((a, b) {
      if (a.tier != b.tier) {
        return a.tier - b.tier;
      }
      final int byName = a.entry.primaryName.compareTo(b.entry.primaryName);
      return byName != 0 ? byName : a.order - b.order;
    });
    return ranked.map((r) => r.entry).toList(growable: false);
  }
}
