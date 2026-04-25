import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_mode.dart';
import 'package:fluxer_app/core/theme/themes/coal.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/core/theme/themes/light.dart';
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
    state = state.copyWith(syncAcrossDevices: value);
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
        theme: Value(state.mode.name),
        scaleFactor: Value(state.scaleFactor),
        chatFontSize: Value(state.chatFontSize),
        syncAcrossDevices: Value(state.syncAcrossDevices),
      ),
    );
  }
}
