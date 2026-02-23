import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/features/servers/data/server_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_providers.g.dart';

@Riverpod(keepAlive: true)
ServerRepository serverRepository(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final db = ref.watch(fluxerDatabaseProvider);
  return ServerRepository(client, db);
}
