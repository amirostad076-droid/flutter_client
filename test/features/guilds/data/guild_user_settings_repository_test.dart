import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/providers/guild_collapsed_categories_provider.dart';
import 'package:fluxer_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:fluxer_dart/export.dart';

class _FakeUsersApi implements UsersApi {
  _FakeUsersApi();

  UserGuildSettingsUpdateRequest? lastRequest;
  int patchCount = 0;

  @override
  Future<UserGuildSettingsResponse> updateGuildSettingsForUser({
    required String guildId,
    required UserGuildSettingsUpdateRequest body,
  }) async {
    patchCount++;
    lastRequest = body;
    return UserGuildSettingsResponse(
      guildId: guildId,
      messageNotifications: UserNotificationSettings.inherit,
      muted: false,
      muteConfig: null,
      mobilePush: true,
      suppressEveryone: false,
      suppressRoles: false,
      hideMutedChannels: false,
      channelOverrides: body.channelOverrides,
      version: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient extends FluxerClient {
  _FakeClient(this._usersApi) : super(Dio());

  final UsersApi _usersApi;

  @override
  UsersApi get users => _usersApi;
}

ProviderContainer _createContainer({
  required db.FluxerDatabase database,
  required _FakeUsersApi usersApi,
}) {
  return ProviderContainer(
    overrides: [
      fluxerDatabaseProvider.overrideWithValue(database),
      fluxerClientProvider.overrideWithValue(_FakeClient(usersApi)),
    ],
  );
}

void main() {
  group('GuildUserSettingsRepository', () {
    late db.FluxerDatabase database;
    late _FakeUsersApi usersApi;
    late ProviderContainer container;

    setUp(() {
      database = db.FluxerDatabase.forTesting(NativeDatabase.memory());
      usersApi = _FakeUsersApi();
      container = _createContainer(database: database, usersApi: usersApi);
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('toggleCategoryCollapsed flips collapsed in drift and PATCH', () async {
      const guildId = 'guild-1';
      const categoryId = 'category-1';
      final repo = container.read(guildUserSettingsRepositoryProvider);

      await repo.toggleCategoryCollapsed(
        guildId: guildId,
        categoryId: categoryId,
      );

      expect(usersApi.patchCount, 1);
      expect(
        usersApi.lastRequest?.channelOverrides?[categoryId]?.collapsed,
        isTrue,
      );

      final row = await database.userGuildSettingsDao.getByGuildId(guildId);
      expect(row, isNotNull);
      final data = jsonDecode(row!.data) as Map<String, dynamic>;
      final overrides = data['channel_overrides'] as Map<String, dynamic>;
      expect(overrides[categoryId]['collapsed'], isTrue);

      final subscription = container.listen(
        guildCollapsedCategoriesProvider(guildId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await pumpEventQueue();
      expect(subscription.read().requireValue, {categoryId});
    });

    test('toggleCategoryCollapsed collapses then expands', () async {
      const guildId = 'guild-1';
      const categoryId = 'category-1';
      final repo = container.read(guildUserSettingsRepositoryProvider);

      await repo.toggleCategoryCollapsed(
        guildId: guildId,
        categoryId: categoryId,
      );
      await repo.toggleCategoryCollapsed(
        guildId: guildId,
        categoryId: categoryId,
      );

      expect(
        usersApi.lastRequest?.channelOverrides?[categoryId]?.collapsed,
        isFalse,
      );

      final subscription = container.listen(
        guildCollapsedCategoriesProvider(guildId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await pumpEventQueue();
      expect(subscription.read().requireValue, isEmpty);
    });
  });
}
