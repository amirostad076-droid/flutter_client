import 'dart:convert';

import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_settings_status_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<UserSettingsResponse?> userSettingsStatusStream(Ref ref) async* {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    yield null;
    return;
  }
  final database = ref.watch(fluxerDatabaseProvider);
  await for (final row in database.userSettingsDao.watchSettings(userId)) {
    if (row == null) {
      yield null;
      continue;
    }
    final Object? decoded = jsonDecode(row.data);
    if (decoded is! Map<String, dynamic>) {
      yield null;
      continue;
    }
    yield UserSettingsResponse.fromJson(decoded);
  }
}

@Riverpod(keepAlive: true)
UserSettingsResponse? userSettingsStatus(Ref ref) {
  return ref.watch(userSettingsStatusStreamProvider).value;
}
