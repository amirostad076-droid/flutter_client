import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/api/retry_interceptor.dart';
import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/core/providers/database_provider.dart';
// import 'package:fluxeron/core/providers/gateway_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_provider.g.dart';

@Riverpod(keepAlive: true)
class AppStartup extends _$AppStartup {
  @override
  Future<void> build() async {
    await _validateAndRestore();
  }

  Future<void> retry() async {
    await _validateAndRestore();
  }

  Future<void> _validateAndRestore() async {
    final database = ref.read(fluxerDatabaseProvider);
    final session = await database.authSessionDao.getSession();

    if (session == null) {
      return;
    }

    ref.read(fluxerAuthTokenProvider.notifier).setToken(session.token);

    try {
      final response = await ref
          .read(fluxerClientProvider)
          .getUsersApi()
          .getCurrentUser(extra: <String, dynamic>{kNoRetryKey: true});

      final data = response.data;
      if (data != null) {
        await database.userDao.upsertUser(
          db.UsersCompanion.insert(
            id: data.id,
            username: data.username,
            discriminator: Value(data.discriminator),
            globalName: Value(data.globalName),
            avatar: Value(data.avatar),
            avatarColor: Value(data.avatarColor),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('[AppStartup] Stored session is invalid, clearing');
        ref.read(fluxerAuthTokenProvider.notifier).setToken(null);
        await database.authSessionDao.clearSession();
        return;
      }
      // Got a response → server is reachable, treat as valid session
      // (e.g. deserialization error from SDK).
      if (e.response != null) {
        debugPrint('[AppStartup] Response received but SDK threw: ${e.error}');
        await _saveCurrentUserFromRaw(e.response!, database);
      } else {
        // No response at all → server unreachable.
        debugPrint('[AppStartup] Server unreachable, waiting for reconnect');
        ref.read(authStateProvider.notifier).setAuthenticated(value: true);
        ref.read(serverReachableProvider.notifier).setReachable(value: false);
        return;
      }
    }

    ref.read(serverReachableProvider.notifier).setReachable(value: true);
    ref.read(authStateProvider.notifier).setAuthenticated(value: true);

    // TODO: Enable gateway once the IDENTIFY payload format is known.
    // unawaited(ref.read(gatewayClientProvider).connect(session.token));

    debugPrint(
      '[AppStartup] Session restored '
      'for user ${session.userId}',
    );
  }

  Future<void> _saveCurrentUserFromRaw(
    Response<dynamic> response,
    db.FluxerDatabase database,
  ) async {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return;
    }
    try {
      await database.userDao.upsertUser(
        db.UsersCompanion.insert(
          id: data['id'] as String,
          username: data['username'] as String,
          discriminator: Value(data['discriminator'] as String? ?? '0000'),
          globalName: Value(data['global_name'] as String?),
          avatar: Value(data['avatar'] as String?),
          avatarColor: Value(data['avatar_color'] as int?),
        ),
      );
    } on Exception catch (e) {
      debugPrint('[AppStartup] Failed to save current user: $e');
    }
  }
}
