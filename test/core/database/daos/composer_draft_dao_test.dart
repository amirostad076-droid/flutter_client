import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';

void main() {
  test('upsertDraft stores and reads text with reply and forward ids', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.composerDraftDao.upsertDraft(
      channelId: 'channel-1',
      content: 'Hello draft',
      replyToMessageId: 'msg-reply',
      forwardFromMessageId: 'msg-forward',
    );

    final draft = await db.composerDraftDao.getDraft('channel-1');
    expect(draft?.content, 'Hello draft');
    expect(draft?.replyToMessageId, 'msg-reply');
    expect(draft?.forwardFromMessageId, 'msg-forward');
  });

  test('upsertDraft updates existing draft for channel', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.composerDraftDao.upsertDraft(
      channelId: 'channel-1',
      content: 'First',
    );
    await db.composerDraftDao.upsertDraft(
      channelId: 'channel-1',
      content: 'Updated',
      replyToMessageId: 'msg-2',
    );

    final draft = await db.composerDraftDao.getDraft('channel-1');
    expect(draft?.content, 'Updated');
    expect(draft?.replyToMessageId, 'msg-2');
    expect(draft?.forwardFromMessageId, isNull);
  });

  test('deleteDraft removes draft for channel', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.composerDraftDao.upsertDraft(
      channelId: 'channel-1',
      content: 'Draft',
    );
    await db.composerDraftDao.deleteDraft('channel-1');

    final draft = await db.composerDraftDao.getDraft('channel-1');
    expect(draft, isNull);
  });

  test('clearAll removes all drafts', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.composerDraftDao.upsertDraft(
      channelId: 'channel-1',
      content: 'Draft 1',
    );
    await db.composerDraftDao.upsertDraft(
      channelId: 'channel-2',
      content: 'Draft 2',
    );
    await db.composerDraftDao.clearAll();

    expect(await db.composerDraftDao.getDraft('channel-1'), isNull);
    expect(await db.composerDraftDao.getDraft('channel-2'), isNull);
  });
}
