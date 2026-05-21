import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_message_provider.g.dart';

@riverpod
Stream<bool> isMessageSaved(Ref ref, String messageId) {
  return ref.watch(fluxerDatabaseProvider).savedMessageDao.watchIsSaved(
    messageId,
  );
}
