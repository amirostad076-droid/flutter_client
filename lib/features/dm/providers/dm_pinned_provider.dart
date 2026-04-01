import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dm_pinned_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<Set<String>> pinnedDmChannelIds(Ref ref) {
  final db = ref.watch(fluxerDatabaseProvider);
  return db.pinnedDmsDao.watchPinnedDms().map(
    (rows) => rows.map((r) => r.channelId).toSet(),
  );
}
