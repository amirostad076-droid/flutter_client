import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_note_view_model.g.dart';

@riverpod
class UserNoteViewModel extends _$UserNoteViewModel {
  @override
  Stream<String?> build({required String userId}) {
    final database = ref.watch(fluxerDatabaseProvider);
    return database.userNotesDao.watchNote(userId).map((row) => row?.content);
  }

  Future<void> save(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return delete();
    }
    final database = ref.read(fluxerDatabaseProvider);
    await database.userNotesDao.upsertNote(
      UserNotesTableCompanion.insert(targetUserId: userId, content: trimmed),
    );
  }

  Future<void> delete() async {
    final database = ref.read(fluxerDatabaseProvider);
    await database.userNotesDao.deleteNote(userId);
  }
}
