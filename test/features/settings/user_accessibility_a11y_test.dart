import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_accessibility.dart';
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

class _InertSyncedPreferencesStore extends SyncedPreferencesStore {
  // ignore: use_super_parameters
  _InertSyncedPreferencesStore(Ref ref) : super(ref);

  @override
  void markDirty(SyncedPreferenceField field) {}

  @override
  void scheduleFlush() {}
}

class _FakeAppearancePreferences extends AppearancePreferences {
  @override
  AppearancePreferencesState build() => const AppearancePreferencesState();

  @override
  Future<void> setScreenReaderAnnounceNewMessages({required bool value}) async {
    state = state.copyWith(screenReaderAnnounceNewMessages: value);
  }

  @override
  Future<void> setSyncReducedMotionWithSystem({required bool value}) async {
    state = state.copyWith(syncReducedMotionWithSystem: value);
  }

  @override
  Future<void> setReducedMotionOverride({required bool value}) async {
    state = state.copyWith(reducedMotionOverride: value);
  }
}

Widget _app(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [
      syncedPreferencesStoreProvider.overrideWith(
        _InertSyncedPreferencesStore.new,
      ),
      appearancePreferencesProvider.overrideWith(
        _FakeAppearancePreferences.new,
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: FluxerLocalizations.localizationsDelegates,
      supportedLocales: FluxerLocalizations.supportedLocales,
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('shows screen reader and reduced motion accessibility toggles', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const UserAccessibility()));
    await tester.pumpAndSettle();

    final FluxerLocalizations l10n = lookupFluxerLocalizations(
      const Locale('en', 'US'),
    );

    expect(
      find.text(l10n.accessibilityScreenReaderAnnounceNewMessagesLabel),
      findsOneWidget,
    );
    expect(
      find.text(l10n.accessibilitySyncReducedMotionWithSystemLabel),
      findsOneWidget,
    );
    expect(
      find.text(l10n.accessibilityReducedMotionOverrideLabel),
      findsOneWidget,
    );
  });
}
