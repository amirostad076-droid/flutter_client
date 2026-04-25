import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_mode.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_look_and_feel.dart';
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_sync_service.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_dart/export.dart';

FluxerDatabase _buildDatabase() => FluxerDatabase.forTesting(
      NativeDatabase.memory(),
    );

class _NoopUserSettingsSyncService extends UserSettingsSyncService {
  _NoopUserSettingsSyncService(super.ref);

  @override
  void enqueueTheme(UserThemeType theme) {}

  @override
  Future<void> flushNow() async {}

  @override
  void cancel() {}
}

Widget _wrap(Widget child, {required FluxerDatabase db}) {
  final colorTheme = buildDarkColorTheme();
  final container = ProviderContainer(
    overrides: [
      fluxerDatabaseProvider.overrideWithValue(db),
      userSettingsSyncProvider.overrideWith(
        _NoopUserSettingsSyncService.new,
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      localizationsDelegates: FluxerLocalizations.localizationsDelegates,
      supportedLocales: FluxerLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

/// Suppress rendering overflow exceptions that originate from [FluxerSlider]'s
/// fixed-size marker column in test environments.
void _ignoreSliderOverflows() {
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('RenderFlex overflowed')) {
      return;
    }
    previousHandler?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousHandler);
}

void main() {
  late FluxerDatabase db;

  setUp(() {
    db = _buildDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders all section titles', (tester) async {
    _ignoreSliderOverflows();
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _wrap(
        UserLookAndFeel(scrollController: ScrollController()),
        db: db,
      ),
    );
    await tester.pump();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Chat Font Scaling'), findsOneWidget);
    expect(find.text('Interface'), findsOneWidget);
    expect(find.text('Channel List'), findsOneWidget);
    expect(find.text('Active Now'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
  });

  testWidgets('tapping light swatch updates theme preference', (tester) async {
    _ignoreSliderOverflows();
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        userSettingsSyncProvider.overrideWith(
          _NoopUserSettingsSyncService.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFluxerTheme(
            colorTheme: buildDarkColorTheme(),
            textTheme: FluxerTextTheme.fromColors(buildDarkColorTheme()),
            layoutTheme: FluxerLayoutTheme.scaled(),
          ),
          localizationsDelegates: FluxerLocalizations.localizationsDelegates,
          supportedLocales: FluxerLocalizations.supportedLocales,
          home: Scaffold(
            body: UserLookAndFeel(scrollController: ScrollController()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Light Theme'));
    await tester.pump();

    expect(
      container.read(themePreferenceProvider).mode,
      FluxerThemeMode.light,
    );
  });

  testWidgets('toggling Enable Favorites updates provider', (tester) async {
    _ignoreSliderOverflows();
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        userSettingsSyncProvider.overrideWith(
          _NoopUserSettingsSyncService.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await db.userPreferencesDao.savePreferences(
      const UserPreferencesTableCompanion(userId: Value('u1')),
    );
    await container
        .read(appearancePreferencesProvider.notifier)
        .load('u1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFluxerTheme(
            colorTheme: buildDarkColorTheme(),
            textTheme: FluxerTextTheme.fromColors(buildDarkColorTheme()),
            layoutTheme: FluxerLayoutTheme.scaled(),
          ),
          localizationsDelegates: FluxerLocalizations.localizationsDelegates,
          supportedLocales: FluxerLocalizations.supportedLocales,
          home: Scaffold(
            body: UserLookAndFeel(scrollController: ScrollController()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      container.read(appearancePreferencesProvider).showFavorites,
      isTrue,
    );

    await tester.dragUntilVisible(
      find.bySemanticsLabel('Enable Favorites'),
      find.byType(Scrollable),
      const Offset(0, -200),
    );
    await tester.tap(find.bySemanticsLabel('Enable Favorites'));
    await tester.pump();

    expect(
      container.read(appearancePreferencesProvider).showFavorites,
      isFalse,
    );
  });
}
