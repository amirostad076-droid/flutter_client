import 'package:drift/drift.dart';
import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/core/theme/fluxer_color_theme.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme_mode.dart';
import 'package:fluxeron/core/theme/themes/coal.dart';
import 'package:fluxeron/core/theme/themes/dark.dart';
import 'package:fluxeron/core/theme/themes/light.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_preference_provider.g.dart';

class ThemePreferenceState {
  ThemePreferenceState({
    this.mode = FluxerThemeMode.dark,
    this.scaleFactor = 1.0,
  })  : colorTheme = switch (mode) {
          FluxerThemeMode.dark => buildDarkColorTheme(),
          FluxerThemeMode.light => buildLightColorTheme(),
          FluxerThemeMode.coal => buildCoalColorTheme(),
        },
        layoutTheme = FluxerLayoutTheme.scaled(scaleFactor: scaleFactor);

  final FluxerThemeMode mode;
  final double scaleFactor;
  final FluxerColorTheme colorTheme;
  final FluxerLayoutTheme layoutTheme;

  late final FluxerTextTheme textTheme =
      FluxerTextTheme.fromColors(colorTheme);

  ThemePreferenceState copyWith({
    FluxerThemeMode? mode,
    double? scaleFactor,
  }) {
    return ThemePreferenceState(
      mode: mode ?? this.mode,
      scaleFactor: scaleFactor ?? this.scaleFactor,
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
      ),
    );
  }
}
