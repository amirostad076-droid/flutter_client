import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart'
    show FluxerDatabase;
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/guild_sidebar.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/channels/providers/channel_mute_provider.dart';
import 'package:fluxer_app/features/channels/providers/guild_collapsed_categories_provider.dart';
import 'package:fluxer_app/features/channels/providers/unread_provider.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_mute_provider.dart';
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_state.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;

const String _guildId = 'g1';
const List<String> _channelIds = ['c1', 'c2'];

void main() {
  group('GuildSidebar collapsed category visibility', () {
    testWidgets('keeps the unread channel and hides the read one', (
      tester,
    ) async {
      _setMobileSurface(tester);
      await tester.pumpWidget(
        _buildTestApp(
          overrides: _buildOverrides(
            channelListState: _state(),
            collapsed: const {'cat1'},
            unread: const {
              'c1': UnreadState(hasUnread: true, hasUnreadMessages: true),
              'c2': UnreadState(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Category'), findsOneWidget);
      expect(find.text('general'), findsOneWidget);
      expect(find.text('random'), findsNothing);
    });

    testWidgets('keeps the selected channel even when it is read', (
      tester,
    ) async {
      _setMobileSurface(tester);
      await tester.pumpWidget(
        _buildTestApp(
          overrides: _buildOverrides(
            channelListState: _state(selectedChannelId: 'c2'),
            selectedChannelId: 'c2',
            collapsed: const {'cat1'},
            unread: const {'c1': UnreadState(), 'c2': UnreadState()},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('random'), findsOneWidget);
      expect(find.text('general'), findsNothing);
    });
  });

  group('GuildSidebar hide muted channels', () {
    testWidgets('keeps a mentioned muted channel and hides a plain muted one', (
      tester,
    ) async {
      _setMobileSurface(tester);
      await tester.pumpWidget(
        _buildTestApp(
          overrides: _buildOverrides(
            channelListState: _state(),
            hideMuted: true,
            muted: const {'c1', 'c2'},
            unread: const {
              'c1': UnreadState(
                hasUnread: true,
                hasUnreadMessages: true,
                mentionCount: 1,
              ),
              'c2': UnreadState(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('general'), findsOneWidget);
      expect(find.text('random'), findsNothing);
    });
  });

  group('GuildSidebar long-press menus', () {
    testWidgets('channel menu shows copy and notification actions', (
      tester,
    ) async {
      _setMobileSurface(tester);
      await tester.pumpWidget(
        _buildTestApp(
          overrides: _buildOverrides(
            channelListState: _state(),
            unread: const {'c1': UnreadState(), 'c2': UnreadState()},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('general'));
      await tester.pumpAndSettle();

      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Copy Channel ID'), findsOneWidget);
      expect(find.text('Notification Settings'), findsOneWidget);
    });

    testWidgets('category menu shows mute, copy id, and mark read actions', (
      tester,
    ) async {
      _setMobileSurface(tester);
      await tester.pumpWidget(
        _buildTestApp(
          overrides: _buildOverrides(
            channelListState: _state(),
            unread: const {'c1': UnreadState(), 'c2': UnreadState()},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('My Category'));
      await tester.pumpAndSettle();

      expect(find.text('Mute Category'), findsOneWidget);
      expect(find.text('Copy Category ID'), findsOneWidget);
      expect(find.text('Mark Category as Read'), findsOneWidget);
    });
  });
}

void _setMobileSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Channel _channel(String id, String name) =>
    Channel(id: id, guildId: _guildId, name: name, parentId: 'cat1');

ChannelListState _state({String? selectedChannelId}) => ChannelListState(
  guild: const Guild(id: _guildId, name: 'Test Guild'),
  categories: [
    ChannelCategory(
      id: 'cat1',
      name: 'My Category',
      channels: [_channel('c1', 'general'), _channel('c2', 'random')],
    ),
  ],
  selectedChannelId: selectedChannelId,
);

List<Override> _buildOverrides({
  required ChannelListState channelListState,
  String? selectedChannelId,
  Set<String> collapsed = const {},
  Set<String> muted = const {},
  bool hideMuted = false,
  Map<String, UnreadState> unread = const {},
}) {
  final db = FluxerDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  return [
    fluxerDatabaseProvider.overrideWithValue(db),
    currentUserIdProvider.overrideWithValue('me'),
    activeGuildIdProvider.overrideWithValue(_guildId),
    activeChannelIdProvider.overrideWithValue(selectedChannelId),
    channelListViewModelProvider.overrideWith(
      () => _FakeChannelListViewModel(channelListState),
    ),
    appearancePreferencesProvider.overrideWith(_FakeAppearancePreferences.new),
    voiceSessionProvider.overrideWith(_FakeVoiceSession.new),
    guildMuteProvider(_guildId).overrideWith(
      (ref) => Stream.value(GuildMuteState(hideMutedChannels: hideMuted)),
    ),
    mutedChannelIdsProvider(
      _guildId,
    ).overrideWith((ref) => Stream.value(muted)),
    guildCollapsedCategoriesProvider(
      _guildId,
    ).overrideWith((ref) => Stream.value(collapsed)),
    for (final id in _channelIds)
      effectiveGuildChannelPermissionBitsProvider(id).overrideWith((ref) => 0),
    for (final entry in unread.entries)
      channelUnreadProvider(
        entry.key,
      ).overrideWith((ref) => Stream.value(entry.value)),
  ];
}

Widget _buildTestApp({required List<Override> overrides}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      localizationsDelegates: FluxerLocalizations.localizationsDelegates,
      supportedLocales: FluxerLocalizations.supportedLocales,
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      routerConfig: GoRouter(
        initialLocation: '/channels/$_guildId',
        routes: [
          GoRoute(
            path: '/channels/$_guildId',
            builder: (context, state) => const Scaffold(body: GuildSidebar()),
          ),
          GoRoute(
            path: '/channels/$_guildId/:channelId',
            builder: (context, state) => const Scaffold(body: GuildSidebar()),
          ),
        ],
      ),
    ),
  );
}

class _FakeChannelListViewModel extends ChannelListViewModel {
  _FakeChannelListViewModel(this._state);

  final ChannelListState _state;

  @override
  ChannelListState build() => _state;
}

class _FakeAppearancePreferences extends AppearancePreferences {
  @override
  AppearancePreferencesState build() =>
      const AppearancePreferencesState(showFavorites: false);
}

class _FakeVoiceSession extends VoiceSession {
  @override
  VoiceSessionState build() => const VoiceSessionState();
}
