import 'package:fluxeron/core/api/fluxer_client_provider.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/features/dm/data/dm_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dm_providers.g.dart';

@Riverpod(keepAlive: true)
DmRepository dmRepository(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final db = ref.watch(fluxerDatabaseProvider);
  return DmRepository(client, db);
}
