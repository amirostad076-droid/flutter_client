import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
FluxerDatabase fluxerDatabase(Ref ref) {
  final db = FluxerDatabase();
  ref.onDispose(db.close);
  return db;
}
