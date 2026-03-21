import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/deep_links/deep_link_handler.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/core/providers/gateway_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/theme/providers/theme_preference_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_provider.g.dart';

@Riverpod(keepAlive: true)
class AppStartup extends _$AppStartup {
  @override
  Future<void> build() async {
    try {
      debugPrint('[AppStartup] Starting…');
      await _validateAndRestore();
      debugPrint('[AppStartup] Completed');
    } on Exception catch (e, st) {
      debugPrint('[AppStartup] Unhandled error during startup: $e\n$st');
      rethrow;
    }
  }

  Future<void> retry() async {
    await _validateAndRestore();
  }

  Future<void> _validateAndRestore() async {
    final database = ref.read(fluxerDatabaseProvider);
    debugPrint('[AppStartup] Database obtained, querying session…');
    final session = await database.authSessionDao.getSession();
    debugPrint('[AppStartup] Session: ${session != null ? 'found' : 'none'}');

    if (session == null) {
      return;
    }

    ref.read(fluxerAuthTokenProvider.notifier).setToken(session.token);
    ref.read(authStateProvider.notifier).setAuthenticated(value: true);
    ref.read(currentUserIdProvider.notifier).set(session.userId);
    await ref.read(themePreferenceProvider.notifier).load(session.userId);

    unawaited(ref.read(gatewayConnectionProvider).connect());
    ref
      ..read(gatewayEventListenerProvider)
      ..read(gatewayStateListenerProvider);

    ref.read(deepLinkHandlerProvider.notifier).processPendingDeepLink();

    debugPrint(
      '[AppStartup] Session restored '
      'for user ${session.userId}',
    );
  }
}
