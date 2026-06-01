import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/composer_drafts.dart';

part 'composer_draft_dao.g.dart';

@DriftAccessor(tables: [ComposerDrafts])
class ComposerDraftDao extends DatabaseAccessor<FluxerDatabase>
    with _$ComposerDraftDaoMixin {
  ComposerDraftDao(super.attachedDatabase);

  Future<ComposerDraft?> getDraft(String channelId) {
    return (select(
      composerDrafts,
    )..where((t) => t.channelId.equals(channelId))).getSingleOrNull();
  }

  Future<void> upsertDraft({
    required String channelId,
    required String content,
    String? replyToMessageId,
  }) {
    return into(composerDrafts).insertOnConflictUpdate(
      ComposerDraftsCompanion.insert(
        channelId: channelId,
        content: Value(content),
        replyToMessageId: Value(replyToMessageId),
      ),
    );
  }

  Future<void> deleteDraft(String channelId) {
    return (delete(
      composerDrafts,
    )..where((t) => t.channelId.equals(channelId))).go();
  }

  Future<void> clearAll() {
    return delete(composerDrafts).go();
  }
}
