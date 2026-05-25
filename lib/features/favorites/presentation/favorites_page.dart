import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/router/navigate_to_content.dart';
import 'package:fluxer_app/core/router/route_names.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteChannelsProvider).value ?? const [];
    final categories = ref.watch(favoriteCategoriesProvider).value ?? const [];
    final channels = ref.watch(allChannelsProvider).value ?? const [];
    final dms = ref.watch(
      dmViewModelProvider.select((state) => state.conversations),
    );
    final guilds = ref.watch(guildListViewModelProvider).guilds;

    final channelById = {for (final channel in channels) channel.id: channel};
    final dmById = {for (final dm in dms) dm.id: dm};
    final guildById = {for (final guild in guilds) guild.id: guild};
    final resolved = [
      for (final favorite in favorites)
        _ResolvedFavorite(
          favorite: favorite,
          channel: channelById[favorite.channelId],
          dm: dmById[favorite.channelId],
          guild: favorite.guildId == null ? null : guildById[favorite.guildId],
        ),
    ];

    return ColoredBox(
      color: context.colors.chatBackground,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.colors.userAreaDividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsFill.star,
                    size: 22,
                    color: context.colors.interactiveNormal,
                  ),
                  const SizedBox(width: 10),
                  Text('Favorites', style: context.textStyles.channelName),
                ],
              ),
            ),
            Expanded(
              child: resolved.isEmpty
                  ? const _FavoritesEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      children: _buildGroups(
                        context,
                        resolved: resolved,
                        categories: categories,
                        onTap: (entry) => _openFavorite(context, entry),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroups(
    BuildContext context, {
    required List<_ResolvedFavorite> resolved,
    required List<db.FavoriteCategory> categories,
    required ValueChanged<_ResolvedFavorite> onTap,
  }) {
    final byParent = <String?, List<_ResolvedFavorite>>{};
    for (final entry in resolved) {
      byParent.putIfAbsent(entry.favorite.parentId, () => []).add(entry);
    }
    for (final entries in byParent.values) {
      entries.sort(
        (a, b) => a.favorite.position.compareTo(b.favorite.position),
      );
    }

    final widgets = <Widget>[];
    void addGroup(String title, List<_ResolvedFavorite> entries) {
      if (entries.isEmpty) {
        return;
      }
      widgets
        ..add(_FavoriteGroupHeader(title: title))
        ..addAll([
          for (final entry in entries)
            _FavoriteTile(entry: entry, onTap: () => onTap(entry)),
        ])
        ..add(const SizedBox(height: 10));
    }

    addGroup('Favorites', byParent[null] ?? const []);
    for (final category in categories) {
      addGroup(category.name, byParent[category.id] ?? const []);
    }

    final knownCategoryIds = categories.map((category) => category.id).toSet();
    final uncategorized = <_ResolvedFavorite>[
      for (final entry in resolved)
        if (entry.favorite.parentId != null &&
            !knownCategoryIds.contains(entry.favorite.parentId))
          entry,
    ];
    addGroup('Other', uncategorized);

    return widgets;
  }

  void _openFavorite(BuildContext context, _ResolvedFavorite entry) {
    final guildId = entry.favorite.guildId;
    final path = guildId == null || guildId.isEmpty
        ? RoutePaths.dmChannel(entry.favorite.channelId)
        : RoutePaths.guildChannel(guildId, entry.favorite.channelId);
    navigateToContent(context, path);
  }
}

class _ResolvedFavorite {
  const _ResolvedFavorite({
    required this.favorite,
    required this.channel,
    required this.dm,
    required this.guild,
  });

  final db.FavoriteChannel favorite;
  final Channel? channel;
  final DmConversation? dm;
  final Guild? guild;

  String get title =>
      favorite.nickname ??
      channel?.name ??
      dm?.displayName ??
      favorite.channelId;

  String? get subtitle {
    if (guild != null) {
      return guild!.name;
    }
    if (dm != null) {
      return dm!.isGroup ? '${dm!.memberCount} members' : 'Direct Message';
    }
    return null;
  }
}

class _FavoriteGroupHeader extends StatelessWidget {
  const _FavoriteGroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        title,
        style: context.textStyles.categoryName.copyWith(
          color: context.colors.textPrimaryMuted,
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.entry, required this.onTap});

  final _ResolvedFavorite entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _FavoriteIcon(entry: entry),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: context.textStyles.username.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.subtitle != null)
                      Text(
                        entry.subtitle!,
                        style: context.textStyles.timestamp.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 18,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteIcon extends ConsumerWidget {
  const _FavoriteIcon({required this.entry});

  final _ResolvedFavorite entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = entry.channel;
    if (channel != null) {
      final int? effectivePermissionBits = ref
          .watch(effectiveGuildChannelPermissionBitsProvider(channel.id))
          .value;
      return SizedBox.square(
        dimension: 36,
        child: Center(
          child: ChannelIcon(
            type: channel.type,
            channel: channel,
            effectivePermissionBits: effectivePermissionBits,
          ),
        ),
      );
    }
    final dm = entry.dm;
    if (dm != null) {
      return FluxerAvatar.user(
        fallbackText: dm.displayName,
        userId: dm.recipientId,
        imageUrl: dm.recipientAvatar == null
            ? null
            : FluxerMediaUrl.userAvatar(
                userId: dm.recipientId,
                hash: dm.recipientAvatar,
              ),
        status: dm.recipientStatus,
        size: 36,
      );
    }
    return SizedBox.square(
      dimension: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.backgroundTertiary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsFill.chatCircle,
            size: 20,
            color: context.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.star,
              size: 48,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: 14),
            Text('No favorites yet', style: context.textStyles.channelName),
            const SizedBox(height: 6),
            Text(
              'Star channels from the chat header to keep them here.',
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
