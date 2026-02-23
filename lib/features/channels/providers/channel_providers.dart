import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/features/channels/data/channel_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_providers.g.dart';

@Riverpod(keepAlive: true)
ChannelRepository channelRepository(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final db = ref.watch(fluxerDatabaseProvider);
  return ChannelRepository(client, db);
}
