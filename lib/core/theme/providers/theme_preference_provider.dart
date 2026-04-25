import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_mode.dart';
import 'package:fluxer_app/core/theme/themes/coal.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/core/theme/themes/light.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_sync_service.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_preference_provider.g.dart';

class ThemePreferenceState {
  ThemePreferenceState({
    this.mode = FluxerThemeMode.dark,
    this.scaleFactor = 1.0,
    this.chatFontSize = 16,
    this.syncAcrossDevices = true,
  }) : darkColorTheme = buildDarkColorTheme(),
       lightColorTheme = buildLightColorTheme(),
       coalColorTheme = buildCoalColorTheme(),
       layoutTheme = FluxerLayoutTheme.scaled(scaleFactor: scaleFactor);

  final FluxerThemeMode mode;
  final double scaleFactor;
  final int chatFontSize;
  final bool syncAcrossDevices;
  final FluxerColorTheme darkColorTheme;
  final FluxerColorTheme lightColorTheme;
  final FluxerColorTheme coalColorTheme;
  final FluxerLayoutTheme layoutTheme;

  FluxerColorTheme get colorTheme => switch (mode) {
    FluxerThemeMode.dark => darkColorTheme,
    FluxerThemeMode.light => lightColorTheme,
    FluxerThemeMode.coal => coalColorTheme,
    FluxerThemeMode.system => darkColorTheme,
  };

  late final FluxerTextTheme textTheme = FluxerTextTheme.fromColors(colorTheme);
  late final FluxerTextTheme darkTextTheme =
      FluxerTextTheme.fromColors(darkColorTheme);
  late final FluxerTextTheme lightTextTheme =
      FluxerTextTheme.fromColors(lightColorTheme);

  ThemePreferenceState copyWith({
    FluxerThemeMode? mode,
    double? scaleFactor,
    int? chatFontSize,
    bool? syncAcrossDevices,
  }) {
    return ThemePreferenceState(
      mode: mode ?? this.mode,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      chatFontSize: chatFontSize ?? this.chatFontSize,
      syncAcrossDevices: syncAcrossDevices ?? this.syncAcrossDevices,
    );
  }
}

@Riverpod(keepAlive: true)
class ThemePreference extends _$ThemePreference {
  String? _userId;

  @override
  ThemePreferenceState build() => ThemePreferenceState();

  Future<void> load(String userId) async {
    _userId = userId;
    final db = ref.read(fluxerDatabaseProvider);
    final prefs = await db.userPreferencesDao.getPreferences(userId);
    if (prefs != null) {
      final mode = FluxerThemeMode.values.firstWhere(
        (m) => m.name == prefs.theme,
        orElse: () => FluxerThemeMode.dark,
      );
      state = ThemePreferenceState(
        mode: mode,
        scaleFactor: prefs.scaleFactor,
        chatFontSize: prefs.chatFontSize,
        syncAcrossDevices: prefs.syncAcrossDevices,
      );
    }
  }

  Future<void> setTheme(FluxerThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _persist();
    if (state.syncAcrossDevices && mode != FluxerThemeMode.system) {
      ref.read(userSettingsSyncProvider).enqueueTheme(_toUserThemeType(mode));
    }
  }

  Future<void> setScaleFactor(double factor) async {
    state = state.copyWith(scaleFactor: factor);
    await _persist();
  }

  Future<void> setChatFontSize(int size) async {
    state = state.copyWith(chatFontSize: size);
    await _persist();
  }

  Future<void> setSyncAcrossDevices({required bool value}) async {
    if (state.mode == FluxerThemeMode.system) {
      return;
    }
    final wasOff = !state.syncAcrossDevices;
    state = state.copyWith(syncAcrossDevices: value);
    await _persist();
    final sync = ref.read(userSettingsSyncProvider);
    if (value && wasOff) {
      sync.enqueueTheme(_toUserThemeType(state.mode));
      await sync.flushNow();
    } else if (!value) {
      sync.cancel();
    }
  }

  /// Apply settings received from the server (READY hydration or
  /// `USER_SETTINGS_UPDATE` echo). No-op when sync is disabled or the value
  /// already matches local. Persists locally; never pushes back.
  Future<void> applyServerSettings(UserSettingsResponse settings) async {
    if (_userId == null) {
      talker.warning(
        '[ThemePreference] Hydration dropped: userId not loaded yet',
      );
      return;
    }
    if (!state.syncAcrossDevices) {
      return;
    }
    final serverMode = _modeFromJson(settings.theme);
    if (serverMode == null || serverMode == state.mode) {
      return;
    }
    state = state.copyWith(mode: serverMode);
    await _persist();
  }

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    final db = ref.read(fluxerDatabaseProvider);
    try {
      await db.userPreferencesDao.savePreferences(
        UserPreferencesTableCompanion(
          userId: Value(userId),
          theme: Value(state.mode.name),
          scaleFactor: Value(state.scaleFactor),
          chatFontSize: Value(state.chatFontSize),
          syncAcrossDevices: Value(state.syncAcrossDevices),
        ),
      );
    } on Object catch (e, st) {
      talker.error('[ThemePreference] Persist failed', e, st);
    }
  }

  UserThemeType _toUserThemeType(FluxerThemeMode mode) => switch (mode) {
    FluxerThemeMode.dark => UserThemeType.dark,
    FluxerThemeMode.coal => UserThemeType.coal,
    FluxerThemeMode.light => UserThemeType.light,
    FluxerThemeMode.system => UserThemeType.system,
  };

  FluxerThemeMode? _modeFromJson(String raw) => switch (raw) {
    'dark' => FluxerThemeMode.dark,
    'coal' => FluxerThemeMode.coal,
    'light' => FluxerThemeMode.light,
    'system' => FluxerThemeMode.system,
    _ => null,
  };
}
