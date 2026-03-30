import 'dart:convert';

import 'package:flutter/services.dart';

class EmojiRegistry {
  EmojiRegistry._();

  static const _kAssetPath = 'assets/emojis.json';

  static Map<String, String>? _nameToSurrogate;

  static Future<String?> resolve(String name) async {
    _nameToSurrogate ??= await _load();
    return _nameToSurrogate![name];
  }

  static String? resolveSync(String name) => _nameToSurrogate?[name];

  static Future<void> preload() async {
    _nameToSurrogate ??= await _load();
  }

  static Future<Map<String, String>> _load() async {
    final raw = await rootBundle.loadString(_kAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final map = <String, String>{};
    for (final category in json.values) {
      for (final entry in (category as List<dynamic>)) {
        final obj = entry as Map<String, dynamic>;
        final surrogates = obj['surrogates'] as String? ?? '';
        if (surrogates.isEmpty) {
          continue;
        }
        for (final name in (obj['names'] as List<dynamic>).cast<String>()) {
          map[name] = surrogates;
        }
      }
    }
    return map;
  }
}
