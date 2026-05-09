import 'package:fluxer_app/core/database/fluxer_database.dart' as db;

class FavoriteChannelsRepository {
  const FavoriteChannelsRepository(this._database);

  final db.FluxerDatabase _database;

  Stream<List<db.FavoriteChannel>> watchChannels() =>
      _database.favoriteChannelsDao.watchChannels();

  Stream<db.FavoriteChannel?> watchChannel(String channelId) =>
      _database.favoriteChannelsDao.watchChannel(channelId);

  Stream<List<db.FavoriteCategory>> watchCategories() =>
      _database.favoriteChannelsDao.watchCategories();

  Stream<db.FavoriteSetting> watchSettings() =>
      _database.favoriteChannelsDao.watchSettings();

  Future<bool> isFavorite(String channelId) async =>
      await _database.favoriteChannelsDao.getChannel(channelId) != null;

  Future<bool> addChannel({
    required String channelId,
    String? guildId,
    String? parentId,
    String? nickname,
  }) => _database.favoriteChannelsDao.addChannel(
    channelId: channelId,
    guildId: guildId,
    parentId: parentId,
    nickname: nickname,
  );

  Future<bool> removeChannel(String channelId) =>
      _database.favoriteChannelsDao.removeChannel(channelId);

  Future<void> moveChannel({
    required String channelId,
    required int position,
    String? parentId,
  }) => _database.favoriteChannelsDao.moveChannel(
    channelId: channelId,
    position: position,
    parentId: parentId,
  );

  Future<bool> addCategory({required String id, required String name}) =>
      _database.favoriteChannelsDao.addCategory(id: id, name: name);

  Future<bool> removeCategory(String id) =>
      _database.favoriteChannelsDao.removeCategory(id);

  Future<void> setCollapsedCategoryIds(List<String> categoryIds) =>
      _database.favoriteChannelsDao.setCollapsedCategoryIds(categoryIds);

  Future<void> setHideMuted({required bool value}) =>
      _database.favoriteChannelsDao.setHideMuted(value: value);

  Future<void> setMuted({required bool value}) =>
      _database.favoriteChannelsDao.setMuted(value: value);
}
