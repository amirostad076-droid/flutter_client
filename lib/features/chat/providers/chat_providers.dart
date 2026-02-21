import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/features/chat/data/message_repository.dart';

part 'chat_providers.g.dart';

@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final db = ref.watch(fluxerDatabaseProvider);
  return MessageRepository(client, db);
}
