import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart' as domain;
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/providers/slowmode_blocked_provider.dart';

void main() {
  test(
    'disposing slowmode check while channel is loading does not throw',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final errors = <Object>[];
      final channelController = StreamController<domain.Channel?>.broadcast();
      addTearDown(channelController.close);

      await runZonedGuarded(() async {
        final container = ProviderContainer(
          overrides: [
            fluxerDatabaseProvider.overrideWithValue(db),
            channelByIdProvider(
              'channel-1',
            ).overrideWith((ref) => channelController.stream),
          ],
        );
        container
            .listen(
              isSlowmodeBlockedProvider('channel-1'),
              (_, _) {},
              fireImmediately: true,
            )
            .close();
        container.dispose();
        await Future<void>.delayed(Duration.zero);
      }, (error, _) => errors.add(error));

      expect(errors, isEmpty);
    },
  );
}
