import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appearance_preferences_provider.g.dart';

enum ChannelTypingIndicatorMode { avatars, indicatorOnly, hidden }

class AppearancePreferencesState {
  const AppearancePreferencesState({
    this.channelTypingIndicatorMode = ChannelTypingIndicatorMode.avatars,
    this.showSelectedChannelTypingIndicator = false,
    this.collapseDMs = false,
    this.showFadedUnreadOnMutedChannels = true,
    this.showActiveNow = true,
    this.showFavorites = true,
  });

  final ChannelTypingIndicatorMode channelTypingIndicatorMode;
  final bool showSelectedChannelTypingIndicator;
  final bool collapseDMs;
  final bool showFadedUnreadOnMutedChannels;
  final bool showActiveNow;
  final bool showFavorites;

  AppearancePreferencesState copyWith({
    ChannelTypingIndicatorMode? channelTypingIndicatorMode,
    bool? showSelectedChannelTypingIndicator,
    bool? collapseDMs,
    bool? showFadedUnreadOnMutedChannels,
    bool? showActiveNow,
    bool? showFavorites,
  }) {
    return AppearancePreferencesState(
      channelTypingIndicatorMode:
          channelTypingIndicatorMode ?? this.channelTypingIndicatorMode,
      showSelectedChannelTypingIndicator:
          showSelectedChannelTypingIndicator ??
          this.showSelectedChannelTypingIndicator,
      collapseDMs: collapseDMs ?? this.collapseDMs,
      showFadedUnreadOnMutedChannels:
          showFadedUnreadOnMutedChannels ??
          this.showFadedUnreadOnMutedChannels,
      showActiveNow: showActiveNow ?? this.showActiveNow,
      showFavorites: showFavorites ?? this.showFavorites,
    );
  }
}

@Riverpod(keepAlive: true)
class AppearancePreferences extends _$AppearancePreferences {
  String? _userId;

  @override
  AppearancePreferencesState build() => const AppearancePreferencesState();

  Future<void> load(String userId) async {
    _userId = userId;
    final db = ref.read(fluxerDatabaseProvider);
    final prefs = await db.userPreferencesDao.getPreferences(userId);
    if (prefs != null) {
      state = AppearancePreferencesState(
        channelTypingIndicatorMode: ChannelTypingIndicatorMode.values
            .firstWhere(
              (m) => m.name == prefs.channelTypingIndicatorMode,
              orElse: () => ChannelTypingIndicatorMode.avatars,
            ),
        showSelectedChannelTypingIndicator:
            prefs.showSelectedChannelTypingIndicator,
        collapseDMs: prefs.collapseDMs,
        showFadedUnreadOnMutedChannels: prefs.showFadedUnreadOnMutedChannels,
        showActiveNow: prefs.showActiveNow,
        showFavorites: prefs.showFavorites,
      );
    }
  }

  Future<void> setChannelTypingIndicatorMode(
    ChannelTypingIndicatorMode mode,
  ) async {
    state = state.copyWith(channelTypingIndicatorMode: mode);
    await _persist();
  }

  Future<void> setShowSelectedChannelTypingIndicator({
    required bool value,
  }) async {
    state = state.copyWith(showSelectedChannelTypingIndicator: value);
    await _persist();
  }

  Future<void> setCollapseDMs({required bool value}) async {
    state = state.copyWith(collapseDMs: value);
    await _persist();
  }

  Future<void> setShowFadedUnreadOnMutedChannels({required bool value}) async {
    state = state.copyWith(showFadedUnreadOnMutedChannels: value);
    await _persist();
  }

  Future<void> setShowActiveNow({required bool value}) async {
    state = state.copyWith(showActiveNow: value);
    await _persist();
  }

  Future<void> setShowFavorites({required bool value}) async {
    state = state.copyWith(showFavorites: value);
    await _persist();
  }

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    final db = ref.read(fluxerDatabaseProvider);
    await db.userPreferencesDao.savePreferences(
      UserPreferencesTableCompanion(
        userId: Value(userId),
        channelTypingIndicatorMode: Value(
          state.channelTypingIndicatorMode.name,
        ),
        showSelectedChannelTypingIndicator: Value(
          state.showSelectedChannelTypingIndicator,
        ),
        collapseDMs: Value(state.collapseDMs),
        showFadedUnreadOnMutedChannels: Value(
          state.showFadedUnreadOnMutedChannels,
        ),
        showActiveNow: Value(state.showActiveNow),
        showFavorites: Value(state.showFavorites),
      ),
    );
  }
}
