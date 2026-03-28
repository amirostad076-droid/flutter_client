import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/guild_stickers.dart';

part 'guild_sticker_dao.g.dart';

@DriftAccessor(tables: [GuildStickers])
class GuildStickerDao extends DatabaseAccessor<FluxerDatabase>
    with _$GuildStickerDaoMixin {
  GuildStickerDao(super.attachedDatabase);

  Stream<List<GuildSticker>> watchByGuild(String guildId) =>
      (select(guildStickers)..where((s) => s.guildId.equals(guildId))).watch();

  Future<List<GuildSticker>> getByGuild(String guildId) =>
      (select(guildStickers)..where((s) => s.guildId.equals(guildId))).get();

  Future<void> replaceForGuild(
    String guildId,
    List<GuildStickersCompanion> stickers,
  ) async {
    await (delete(guildStickers)..where((s) => s.guildId.equals(guildId))).go();
    await batch((b) {
      for (final sticker in stickers) {
        b.insert(guildStickers, sticker);
      }
    });
  }

  Future<void> clearAll() => delete(guildStickers).go();
}
