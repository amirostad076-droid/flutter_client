import 'dart:async';

import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_settings_sync_service.g.dart';

const Duration _kDebounceDelay = Duration(milliseconds: 500);

/// Debounced PATCH `/users/@me/settings` queue. Mirrors the web app's
/// `UserSettingsCommands.update` + `flushPendingSettings` pipeline: changes
/// merge into a pending patch and flush 500ms after the last enqueue.
class UserSettingsSyncService {
  UserSettingsSyncService(Ref ref) : _ref = ref;

  final Ref _ref;
  Timer? _debounceTimer;
  UserThemeType? _pendingTheme;

  void enqueueTheme(UserThemeType theme) {
    _pendingTheme = theme;
    _scheduleFlush();
  }

  Future<void> flushNow() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _flush();
  }

  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingTheme = null;
  }

  void _scheduleFlush() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_kDebounceDelay, () {
      unawaited(_flush());
    });
  }

  Future<void> _flush() async {
    final theme = _pendingTheme;
    if (theme == null) {
      return;
    }
    _pendingTheme = null;

    try {
      final client = _ref.read(fluxerClientProvider);
      await client.users.updateCurrentUserSettings(
        body: UserSettingsUpdateRequest(theme: theme),
      );
      talker.debug('[UserSettingsSync] Pushed theme=${theme.json}');
    } on Object catch (e, st) {
      talker.error('[UserSettingsSync] Push failed', e, st);
    }
  }
}

@Riverpod(keepAlive: true)
UserSettingsSyncService userSettingsSync(Ref ref) {
  final service = UserSettingsSyncService(ref);
  ref.onDispose(service.cancel);
  return service;
}
