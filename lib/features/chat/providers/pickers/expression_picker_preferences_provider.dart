import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expression_picker_preferences_provider.g.dart';

@Riverpod(keepAlive: true)
class FavoriteEmojiKeys extends _$FavoriteEmojiKeys {
  @override
  Future<List<String>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const <String>[];
    }
    return ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .getFavoriteEmojiKeys(userId);
  }

  Future<void> toggle(String key) async {
    final current = _currentKeys(state);
    final next = _toggleKey(current, key);
    state = AsyncData<List<String>>(next);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    await ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .setFavoriteEmojiKeys(userId, next);
  }
}

@Riverpod(keepAlive: true)
class FavoriteStickerKeys extends _$FavoriteStickerKeys {
  @override
  Future<List<String>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const <String>[];
    }
    return ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .getFavoriteStickerKeys(userId);
  }

  Future<void> toggle(String key) async {
    final current = _currentKeys(state);
    final next = _toggleKey(current, key);
    state = AsyncData<List<String>>(next);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    await ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .setFavoriteStickerKeys(userId, next);
  }
}

@Riverpod(keepAlive: true)
class CollapsedEmojiPickerCategories extends _$CollapsedEmojiPickerCategories {
  @override
  Future<List<String>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const <String>[];
    }
    return ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .getCollapsedEmojiPickerCategories(userId);
  }

  Future<void> toggle(String category) async {
    final current = _currentKeys(state);
    final next = _toggleKey(current, category);
    state = AsyncData<List<String>>(next);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    await ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .setCollapsedEmojiPickerCategories(userId, next);
  }
}

@Riverpod(keepAlive: true)
class CollapsedStickerPickerCategories
    extends _$CollapsedStickerPickerCategories {
  @override
  Future<List<String>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const <String>[];
    }
    return ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .getCollapsedStickerPickerCategories(userId);
  }

  Future<void> toggle(String category) async {
    final current = _currentKeys(state);
    final next = _toggleKey(current, category);
    state = AsyncData<List<String>>(next);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    await ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .setCollapsedStickerPickerCategories(userId, next);
  }
}

List<String> _currentKeys(AsyncValue<List<String>> state) => switch (state) {
  AsyncData<List<String>>(:final value) => value,
  _ => const <String>[],
};

List<String> _toggleKey(List<String> current, String key) {
  final normalized = key.trim();
  if (normalized.isEmpty) {
    return current;
  }
  if (current.contains(normalized)) {
    return current.where((entry) => entry != normalized).toList();
  }
  return <String>[normalized, ...current];
}
