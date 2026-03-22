import 'dart:convert';

import 'package:fluxer_dart/models/user_settings_response_guild_folders.dart';
import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/features/guilds/data/guild_order_repository.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'organized_guild_list_provider.g.dart';

sealed class GuildNavbarItem {
  const GuildNavbarItem();
}

class GuildNavbarFolder extends GuildNavbarItem {
  const GuildNavbarFolder({
    required this.id,
    required this.guilds,
    this.name,
    this.color,
    this.flags = 0,
    this.icon,
  });

  final int id;
  final String? name;
  final int? color;
  final int flags;
  final String? icon;
  final List<Guild> guilds;

  /// Whether to show the folder icon instead of the 2x2 grid when collapsed.
  bool get showIconWhenCollapsed => (flags & 1) != 0;
}

class GuildNavbarGuild extends GuildNavbarItem {
  const GuildNavbarGuild({required this.guild});
  final Guild guild;
}

@Riverpod(keepAlive: true)
Stream<List<UserSettingsResponseGuildFolders>> guildFolders(Ref ref) async* {
  final db = ref.watch(fluxerDatabaseProvider);
  final UserSettingsViewState userState = ref.watch(
    userSettingsViewModelProvider,
  );

  if (userState.userId.isEmpty) {
    yield [];
    return;
  }

  await for (final settings in db.userSettingsDao.watchSettings(
    userState.userId,
  )) {
    if (settings == null) {
      yield [];
      continue;
    }

    final data = jsonDecode(settings.data) as Map<String, dynamic>;
    final foldersJson = data['guild_folders'] as List<dynamic>? ?? [];
    yield foldersJson
        .map(
          (e) => UserSettingsResponseGuildFolders.fromJson(
            e as Map<String, Object?>,
          ),
        )
        .toList();
  }
}

@Riverpod(keepAlive: true)
class OrganizedGuildList extends _$OrganizedGuildList {
  @override
  List<GuildNavbarItem> build() {
    final folders = ref.watch(guildFoldersProvider).value ?? [];
    final GuildListViewState guildState = ref.watch(guildListViewModelProvider);
    final List<Guild> guilds = guildState.guilds;

    if (folders.isEmpty) {
      return guilds.map((Guild g) => GuildNavbarGuild(guild: g)).toList();
    }

    final guildMap = <String, Guild>{for (final Guild g in guilds) g.id: g};

    final items = <GuildNavbarItem>[];
    for (final folder in folders) {
      final folderGuilds = folder.guildIds
          .map((String id) => guildMap[id])
          .whereType<Guild>()
          .toList();

      if (folderGuilds.isEmpty) {
        continue;
      }

      // Web app uses UNCATEGORIZED_FOLDER_ID = -1.
      // Gateway may send null or -1 for uncategorized entries.
      if (folder.id == null || folder.id == -1) {
        for (final guild in folderGuilds) {
          items.add(GuildNavbarGuild(guild: guild));
        }
      } else {
        items.add(
          GuildNavbarFolder(
            id: folder.id!,
            name: folder.name,
            color: folder.color,
            flags: folder.flags ?? 0,
            icon: folder.icon?.json,
            guilds: folderGuilds,
          ),
        );
      }
    }

    return items;
  }

  void reorder({
    required String sourceId,
    required String targetId,
    required bool insertAfter,
  }) {
    final items = [...state];
    final sourceIndex = _findTopLevelIndex(items, sourceId);
    final targetIndex = _findTopLevelIndex(items, targetId);
    if (sourceIndex == -1 || targetIndex == -1) return;

    final item = items.removeAt(sourceIndex);
    final adjustedTarget = sourceIndex < targetIndex
        ? targetIndex - 1
        : targetIndex;
    final insertIndex = insertAfter ? adjustedTarget + 1 : adjustedTarget;
    items.insert(insertIndex, item);

    state = items;
    _persist();
  }

  void combineIntoFolder({
    required String sourceGuildId,
    required String targetGuildId,
  }) {
    final items = [...state];
    final sourceIndex = _findTopLevelIndex(items, sourceGuildId);
    final targetIndex = _findTopLevelIndex(items, targetGuildId);
    if (sourceIndex == -1 || targetIndex == -1) return;

    final sourceItem = items[sourceIndex];
    final targetItem = items[targetIndex];
    if (sourceItem is! GuildNavbarGuild || targetItem is! GuildNavbarGuild) {
      return;
    }

    // Generate a folder ID from the two guild IDs to keep it deterministic.
    final folderId =
        (sourceGuildId.hashCode ^ targetGuildId.hashCode).abs() % 0x7FFFFFFF;

    final folder = GuildNavbarFolder(
      id: folderId,
      guilds: [targetItem.guild, sourceItem.guild],
    );

    // Remove higher index first to avoid shifting.
    final first = sourceIndex < targetIndex ? sourceIndex : targetIndex;
    if (sourceIndex > targetIndex) {
      items
        ..removeAt(sourceIndex)
        ..removeAt(targetIndex);
    } else {
      items
        ..removeAt(targetIndex)
        ..removeAt(sourceIndex);
    }
    items.insert(first < items.length ? first : items.length, folder);

    state = items;
    _persist();
  }

  void moveIntoFolder({required String guildId, required int folderId}) {
    final items = [...state];
    final sourceIndex = _findTopLevelIndex(items, guildId);
    if (sourceIndex == -1) return;

    final sourceItem = items[sourceIndex];
    if (sourceItem is! GuildNavbarGuild) return;

    final folderIndex = _findTopLevelIndex(items, folderId.toString());
    if (folderIndex == -1) return;

    final folderItem = items[folderIndex];
    if (folderItem is! GuildNavbarFolder) return;

    items.removeAt(sourceIndex);
    final adjustedFolderIndex = sourceIndex < folderIndex
        ? folderIndex - 1
        : folderIndex;

    items[adjustedFolderIndex] = GuildNavbarFolder(
      id: folderItem.id,
      name: folderItem.name,
      color: folderItem.color,
      flags: folderItem.flags,
      icon: folderItem.icon,
      guilds: [...folderItem.guilds, sourceItem.guild],
    );

    state = items;
    _persist();
  }

  void _persist() {
    ref.read(guildOrderRepositoryProvider).saveGuildFolders(state);
  }

  static int _findTopLevelIndex(List<GuildNavbarItem> items, String id) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      switch (item) {
        case GuildNavbarGuild(:final guild):
          if (guild.id == id) return i;
        case GuildNavbarFolder():
          if (item.id.toString() == id) return i;
      }
    }
    return -1;
  }
}

@Riverpod(keepAlive: true)
class FolderExpandedState extends _$FolderExpandedState {
  @override
  Set<int> build() => {};

  void toggle(int folderId) {
    if (state.contains(folderId)) {
      state = Set.of(state)..remove(folderId);
    } else {
      state = {...state, folderId};
    }
  }
}
