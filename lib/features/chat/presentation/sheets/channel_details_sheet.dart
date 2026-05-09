import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_names.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/data/read_state_repository.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxer_app/features/channels/providers/channel_mute_provider.dart';
import 'package:fluxer_app/features/channels/providers/unread_provider.dart';
import 'package:fluxer_app/features/chat/data/channel_pins_repository.dart';
import 'package:fluxer_app/features/chat/data/message_search_repository.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_item.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_markdown.dart';
import 'package:fluxer_app/features/chat/providers/channel_details_providers.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_mute_provider.dart';
import 'package:fluxer_app/features/dm/providers/dm_pinned_provider.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_providers.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:fluxer_app/features/members/providers/member_list_view_model.dart';
import 'package:fluxer_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kSheetLoadMoreThreshold = 160.0;

// Riverpod does not expose the concrete family type through flutter_riverpod.
// ignore: specify_nonobvious_property_types
final _channelPermissionBitsProvider = FutureProvider.family<int, String>(
  (ref, channelId) => computeEffectiveGuildChannelPermissionBits(
    ref: ref,
    channelId: channelId,
  ),
);

enum ChannelDetailsInitialTab { members, pins }

Future<void> showChannelDetailsSheet(
  BuildContext context, {
  required Channel? channel,
  required DmConversation? dm,
  ChannelDetailsInitialTab initialTab = ChannelDetailsInitialTab.members,
  bool openSearchImmediately = false,
}) {
  return FluxerBottomSheet.showScrollable<void>(
    context,
    maxHeight: 0.94,
    builder: (sheetContext, scrollController, close) => ChannelDetailsSheet(
      channel: channel,
      dm: dm,
      initialTab: initialTab,
      openSearchImmediately: openSearchImmediately,
      scrollController: scrollController,
      close: close,
    ),
  );
}

Future<void> showChannelSearchSheet(
  BuildContext context, {
  required String channelId,
  required String? guildId,
  required String title,
}) {
  return FluxerBottomSheet.showScrollable<void>(
    context,
    title: 'Search $title',
    maxHeight: 0.96,
    builder: (sheetContext, scrollController, close) => ChannelSearchSheet(
      channelId: channelId,
      guildId: guildId,
      scrollController: scrollController,
      close: close,
    ),
  );
}

class ChannelDetailsSheet extends ConsumerStatefulWidget {
  const ChannelDetailsSheet({
    required this.channel,
    required this.dm,
    required this.initialTab,
    required this.openSearchImmediately,
    required this.scrollController,
    required this.close,
    super.key,
  });

  final Channel? channel;
  final DmConversation? dm;
  final ChannelDetailsInitialTab initialTab;
  final bool openSearchImmediately;
  final ScrollController scrollController;
  final VoidCallback close;

  @override
  ConsumerState<ChannelDetailsSheet> createState() =>
      _ChannelDetailsSheetState();
}

class _ChannelDetailsSheetState extends ConsumerState<ChannelDetailsSheet> {
  late int _selectedIndex;
  bool _topicExpanded = false;
  bool _searchOpened = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab == ChannelDetailsInitialTab.pins ? 1 : 0;
    widget.scrollController.addListener(_onScroll);
    if (_selectedIndex == 1) {
      _ackPins();
    }
    if (widget.openSearchImmediately && _targetChannelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_searchOpened) {
          _openSearch();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  String? get _targetChannelId => widget.channel?.id ?? widget.dm?.id;
  String? get _targetGuildId => widget.channel?.guildId;
  String? get _targetTitle => widget.channel?.name ?? widget.dm?.displayName;

  void _onScroll() {
    final channelId = _targetChannelId;
    if (_selectedIndex != 1 || channelId == null) {
      return;
    }
    final position = widget.scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - _kSheetLoadMoreThreshold) {
      unawaited(
        ref.read(channelPinsProvider(channelId).notifier).loadMore(),
      );
    }
  }

  void _ackPins() {
    final channelId = _targetChannelId;
    if (channelId == null) {
      return;
    }
    unawaited(
      ReadStateRepository(
        ref.read(fluxerClientProvider),
        ref.read(fluxerDatabaseProvider),
      ).ackPins(channelId),
    );
  }

  void _openSearch() {
    final channelId = _targetChannelId;
    final title = _targetTitle;
    if (channelId == null || title == null) {
      return;
    }
    _searchOpened = true;
    unawaited(
      showChannelSearchSheet(
        context,
        channelId: channelId,
        guildId: _targetGuildId,
        title: title,
      ),
    );
  }

  Future<void> _markRead() async {
    final channel = widget.channel;
    final dm = widget.dm;
    if (channel != null) {
      await ReadStateRepository(
        ref.read(fluxerClientProvider),
        ref.read(fluxerDatabaseProvider),
      ).ackLatest(channel.id);
      return;
    }
    if (dm != null) {
      await ref.read(dmViewModelProvider.notifier).markAsRead(dm.id);
    }
  }

  Future<void> _toggleFavorite({required bool isFavorite}) async {
    final channel = widget.channel;
    final dm = widget.dm;
    final channelId = channel?.id ?? dm?.id;
    if (channelId == null) {
      return;
    }

    final repository = ref.read(favoriteChannelsRepositoryProvider);
    if (isFavorite) {
      await repository.removeChannel(channelId);
    } else {
      await repository.addChannel(
        channelId: channelId,
        guildId: channel?.guildId,
        nickname: channel?.name ?? dm?.displayName,
      );
    }
    _toast(isFavorite ? 'Removed from Favorites' : 'Added to Favorites');
  }

  Future<void> _toggleDmPin({required bool isPinned}) async {
    final dm = widget.dm;
    if (dm == null) {
      return;
    }
    final repository = ref.read(dmRepositoryProvider);
    if (isPinned) {
      await repository.unpinDm(dm.id);
      _toast('Unpinned DM');
    } else {
      await repository.pinDm(dm.id);
      _toast('Pinned DM');
    }
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _toast('Copied to clipboard');
  }

  Future<void> _confirmCloseDm() async {
    final dm = widget.dm;
    if (dm == null) {
      return;
    }
    await FluxerConfirmModal.show(
      context,
      title: dm.isGroup ? 'Leave Group' : 'Close DM',
      description: dm.isGroup
          ? 'Leave ${dm.displayName}?'
          : 'Close your conversation with ${dm.displayName}?',
      confirmLabel: dm.isGroup ? 'Leave Group' : 'Close DM',
      isDanger: true,
      onConfirm: () {
        unawaited(ref.read(dmViewModelProvider.notifier).closeDmChannel(dm.id));
        widget.close();
      },
    );
  }

  Future<void> _setMute({required bool isMuted, int? durationSeconds}) async {
    final dm = widget.dm;
    final channel = widget.channel;
    if (dm != null) {
      if (isMuted) {
        await ref
            .read(dmRepositoryProvider)
            .muteDm(dm.id, durationSeconds: durationSeconds);
        _toast('Muted conversation');
      } else {
        await ref.read(dmRepositoryProvider).unmuteDm(dm.id);
        _toast('Unmuted conversation');
      }
      return;
    }
    if (channel != null) {
      await _updateGuildChannelOverride(
        ref,
        guildId: channel.guildId,
        channelId: channel.id,
        muted: isMuted,
        durationSeconds: durationSeconds,
      );
      _toast(isMuted ? 'Muted channel' : 'Unmuted channel');
    }
  }

  Future<void> _setNotification(UserNotificationSettings setting) async {
    final channel = widget.channel;
    if (channel == null) {
      return;
    }
    await _updateGuildChannelOverride(
      ref,
      guildId: channel.guildId,
      channelId: channel.id,
      messageNotifications: setting,
    );
    _toast('Notification settings updated');
  }

  void _toast(
    String message, {
    FluxerToastVariant variant = FluxerToastVariant.success,
  }) {
    ref
        .read(toastProvider.notifier)
        .show(FluxerToast(message: message, variant: variant));
  }

  @override
  Widget build(BuildContext context) {
    final targetChannelId = widget.channel?.id ?? widget.dm?.id;
    final hasPins = targetChannelId != null;
    final showFavorites = ref.watch(
      appearancePreferencesProvider.select((s) => s.showFavorites),
    );
    final isFavorite =
        showFavorites &&
        targetChannelId != null &&
        (ref.watch(favoriteChannelProvider(targetChannelId)).asData?.value !=
            null);
    final mutedDmIds = ref.watch(mutedDmChannelIdsProvider).value ?? {};
    final mutedChannelIds = widget.channel == null
        ? const <String>{}
        : ref.watch(mutedChannelIdsProvider(widget.channel!.guildId)).value ??
              const <String>{};
    final isMuted = widget.dm != null
        ? mutedDmIds.contains(widget.dm!.id)
        : widget.channel != null &&
              mutedChannelIds.contains(widget.channel!.id);
    final pinnedDmIds = ref.watch(pinnedDmChannelIdsProvider).value ?? {};
    final isDmPinned = widget.dm != null && pinnedDmIds.contains(widget.dm!.id);
    final unread = targetChannelId == null
        ? 0
        : widget.dm?.unreadCount ??
              (ref
                          .watch(channelUnreadProvider(targetChannelId))
                          .value
                          ?.hasUnread ??
                      false
                  ? 1
                  : 0);
    final tabs = <FluxerTab>[
      const FluxerTab(label: 'Members', icon: PhosphorIconsFill.users),
      if (hasPins)
        const FluxerTab(label: 'Pins', icon: PhosphorIconsFill.pushPin),
    ];
    final selectedIndex = _selectedIndex.clamp(0, tabs.length - 1);
    if (widget.channel != null) {
      // Prefetch permission bits so the More menu has them ready on tap.
      ref.watch(_channelPermissionBitsProvider(widget.channel!.id));
    }

    return Column(
      children: [
        _DetailsIdentityHeader(
          channel: widget.channel,
          dm: widget.dm,
          topicExpanded: _topicExpanded,
          onToggleTopic: () => setState(() => _topicExpanded = !_topicExpanded),
          onClose: widget.close,
        ),
        SizedBox(height: context.layout.s3),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
          child: Row(
            children: [
              Expanded(
                child: FluxerActionButton(
                  icon: PhosphorIconsFill.bellSlash,
                  label: isMuted ? 'Unmute' : 'Mute',
                  isActive: isMuted,
                  onTap: () => _showMuteSheet(
                    context,
                    isMuted: isMuted,
                    onSelected: _setMute,
                  ),
                ),
              ),
              if (hasPins) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FluxerActionButton(
                    icon: PhosphorIconsBold.magnifyingGlass,
                    label: 'Search',
                    onTap: _openSearch,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: FluxerActionButton(
                  icon: PhosphorIconsBold.dotsThreeVertical,
                  label: 'More',
                  onTap: () {
                    final bits = widget.channel == null
                        ? 0
                        : ref
                                .read(
                                  _channelPermissionBitsProvider(
                                    widget.channel!.id,
                                  ),
                                )
                                .value ??
                            0;
                    unawaited(
                      _showDetailsMoreSheet(
                        context,
                        ref: ref,
                        channel: widget.channel,
                        dm: widget.dm,
                        showFavorite: showFavorites &&
                            targetChannelId != null &&
                            !(widget.dm?.isPersonalNotes ?? false),
                        isFavorite: isFavorite,
                        isDmPinned: isDmPinned,
                        hasUnread: unread > 0,
                        channelPermissionBits: bits,
                        onMarkRead: _markRead,
                        onToggleFavorite: _toggleFavorite,
                        onToggleDmPin: _toggleDmPin,
                        onSetNotification: _setNotification,
                        onCopy: _copy,
                        onCloseDm: _confirmCloseDm,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.layout.s3),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2,
                color: context.colors.backgroundModifierAccent,
              ),
            ),
            FluxerTabs(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onChanged: (index) {
                setState(() => _selectedIndex = index);
                if (index == 1) {
                  _ackPins();
                }
              },
            ),
          ],
        ),
        SizedBox(height: context.layout.s3),
        Expanded(
          child: selectedIndex == 1 && targetChannelId != null
              ? _PinsTab(
                  channelId: targetChannelId,
                  guildId: widget.channel?.guildId,
                  scrollController: widget.scrollController,
                  close: widget.close,
                )
              : _MembersTab(
                  dm: widget.dm,
                  guildId: widget.channel?.guildId,
                  scrollController: widget.scrollController,
                ),
        ),
      ],
    );
  }
}

class _DetailsIdentityHeader extends StatelessWidget {
  const _DetailsIdentityHeader({
    required this.channel,
    required this.dm,
    required this.topicExpanded,
    required this.onToggleTopic,
    required this.onClose,
  });

  final Channel? channel;
  final DmConversation? dm;
  final bool topicExpanded;
  final VoidCallback onToggleTopic;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title = channel?.name ?? dm?.displayName ?? 'Details';
    final subtitle = _detailsSubtitle(channel: channel, dm: dm);
    final topic = channel?.topic?.trim();
    final isBot = dm != null && !dm!.isGroup && dm!.isBot;
    final showInlineChannelIcon = channel != null;
    final hasTopic = topic != null && topic.isNotEmpty;

    return FluxerSheetIdentityHeader(
      leading: _DetailsAvatar(channel: channel, dm: dm),
      title: title,
      subtitle: subtitle,
      onClose: onClose,
      titlePrefix: showInlineChannelIcon
          ? ChannelIcon(
              type: channel!.type,
              size: 16,
              color: context.colors.textPrimary,
            )
          : null,
      titleAdornments: [if (isBot) const FluxerBotBadge()],
      body: hasTopic
          ? _TopicCard(
              topic: topic,
              channelId: channel?.id,
              expanded: topicExpanded,
              onToggle: onToggleTopic,
            )
          : null,
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.channelId,
    required this.expanded,
    required this.onToggle,
  });

  final String topic;
  final String? channelId;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedSize(
            duration: context.motion.fast,
            curve: context.motion.curve,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: expanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 60),
              child: ClipRect(
                child: MessageMarkdown(
                  data: topic,
                  channelId: channelId,
                  markdownContext:
                      FluxerMarkdownContext.restrictedInlineReply,
                  baseStyle: context.textStyles.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: PhosphorIcon(
              expanded
                  ? PhosphorIconsBold.caretUp
                  : PhosphorIconsBold.caretDown,
              size: 16,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsAvatar extends ConsumerWidget {
  const _DetailsAvatar({required this.channel, required this.dm});

  static const double _size = 48;

  final Channel? channel;
  final DmConversation? dm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dm = this.dm;
    final channel = this.channel;
    if (dm != null) {
      if (dm.isPersonalNotes) {
        final currentUserId = ref.watch(currentUserIdProvider);
        if (currentUserId == null) {
          return const SizedBox.square(dimension: _size);
        }
        return FutureBuilder<db.User?>(
          future: ref
              .read(fluxerDatabaseProvider)
              .userDao
              .getUserById(currentUserId),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return FluxerAvatar.user(
              fallbackText: user?.globalName ?? user?.username ?? 'You',
              userId: currentUserId,
              imageUrl: user?.avatar == null
                  ? null
                  : '$fluxerMediaCdn/avatars/$currentUserId/${user!.avatar}.png',
              avatarColor: user?.avatarColor,
              status: user?.status ?? 'online',
              size: _size,
            );
          },
        );
      }
      if (dm.isGroup) {
        return FluxerAvatarCluster(
          channelId: dm.id,
          iconUrl: _groupIconUrl(dm),
          status: dm.groupStatus,
          size: _size,
          members: [
            for (final member in dm.groupMembers)
              AvatarClusterMember(
                userId: member.id,
                fallbackText: member.name,
                imageUrl: _memberAvatarUrl(member),
              ),
          ],
        );
      }
      return FluxerAvatar.user(
        fallbackText: dm.recipientName,
        userId: dm.recipientId,
        imageUrl: _dmAvatarUrl(dm),
        status: dm.recipientStatus,
        size: _size,
      );
    }
    if (channel != null) {
      return FluxerAvatar.icon(
        icon: ChannelIcon.iconDataFor(channel.type),
        size: _size,
      );
    }
    return const SizedBox.square(dimension: _size);
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({
    required this.dm,
    required this.guildId,
    required this.scrollController,
  });

  final DmConversation? dm;
  final String? guildId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dm != null) {
      final currentUserId = ref.watch(currentUserIdProvider);
      final canShowNewGroupCta = !dm!.isGroup &&
          !dm!.isPersonalNotes &&
          !dm!.isBot &&
          !dm!.isSystem;

      return ListView(
        controller: scrollController,
        padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
        children: [
          if (canShowNewGroupCta)
            _NewGroupCtaRow(
              recipientHandle: dm!.recipientUsername ?? dm!.recipientName,
              onTap: () => _stubComingSoon(context, ref),
            ),
          _DmMemberGroups(dm: dm!, currentUserId: currentUserId),
        ],
      );
    }

    final roleGroups = ref.watch(memberListViewModelProvider).roleGroups;
    if (roleGroups.isEmpty) {
      return const _EmptySheetState(
        icon: PhosphorIconsBold.users,
        title: 'No members to show',
        body: 'Members will appear here once the community data is loaded.',
      );
    }

    final guildOwnerId = guildId == null
        ? null
        : ref.watch(guildByIdProvider(guildId!)).asData?.value?.ownerId;
    final currentUserId = ref.watch(currentUserIdProvider);

    final renderGroups = _splitOnlineOffline(roleGroups);

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
      itemCount: renderGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = renderGroups[groupIndex];
        return FluxerListSection(
          header: group.displayName,
          headerColor: group.headerColor,
          children: [
            for (final member in group.members)
              _SimpleMemberRow(
                userId: member.id,
                name: member.displayName,
                avatarUrl: member.avatarUrl,
                avatarColor: member.avatarColor,
                status: member.status,
                isBot: member.isBot,
                isOwner: guildOwnerId != null && member.id == guildOwnerId,
                customStatus: member.customStatus,
                dimmed: group.dimMembers,
                onTap: () =>
                    FluxerUserProfileSheet.show(context, userId: member.id),
                onLongPress: () => _showGuildMemberActionsSheet(
                  context,
                  ref: ref,
                  member: member,
                  guildId: guildId,
                  isCurrentUser: member.id == currentUserId,
                  isOwner: guildOwnerId != null && member.id == guildOwnerId,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PinsTab extends ConsumerWidget {
  const _PinsTab({
    required this.channelId,
    required this.guildId,
    required this.scrollController,
    required this.close,
  });

  final String channelId;
  final String? guildId;
  final ScrollController scrollController;
  final VoidCallback close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(channelPinsProvider(channelId));
    return pins.when(
      loading: () => const Center(child: FluxerLoadingSpinner()),
      error: (error, stack) => _ErrorSheetState(
        title: 'Pins could not be loaded',
        onRetry: () => ref.invalidate(channelPinsProvider(channelId)),
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return const _PinsEmptyState();
        }

        final endStateDescription = guildId != null
            ? 'Members with the "Pin Messages" permission can pin messages '
                'for everyone to see.'
            : 'You can pin messages in this conversation for everyone to see.';

        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
          itemCount:
              state.items.length +
              (state.isLoadingMore ||
                      state.errorMessage != null ||
                      !state.hasMore
                  ? 1
                  : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              if (state.errorMessage != null) {
                return _InlineRetry(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(channelPinsProvider(channelId).notifier)
                      .loadMore(),
                );
              }
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: FluxerLoadingSpinner()),
                );
              }
              return _PinsEndState(description: endStateDescription);
            }
            final entry = state.items[index];
            return MessagePreviewTile(
              message: entry.message,
              guildId: guildId,
              onTap: () =>
                  _jumpToMessage(context, ref, entry.message, close: close),
              onLongPress: () => _showPinnedMessageActions(
                context,
                ref,
                channelId: channelId,
                guildId: guildId,
                entry: entry,
                close: close,
              ),
            );
          },
        );
      },
    );
  }
}

class _PinsEmptyState extends StatelessWidget {
  const _PinsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.sparkle,
              size: 80,
              color: context.colors.textPrimaryMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No Pinned Messages',
              style: context.textStyles.heading.copyWith(
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Whenever someone pins a message, it'll appear here.",
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinsEndState extends StatelessWidget {
  const _PinsEndState({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.flagCheckered,
              size: 48,
              color: context.colors.textPrimaryMuted,
            ),
            const SizedBox(height: 8),
            Text(
              "You've reached the end",
              style: context.textStyles.heading.copyWith(
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                description,
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textPrimaryMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChannelSearchSheet extends ConsumerStatefulWidget {
  const ChannelSearchSheet({
    required this.channelId,
    required this.guildId,
    required this.scrollController,
    required this.close,
    super.key,
  });

  final String channelId;
  final String? guildId;
  final ScrollController scrollController;
  final VoidCallback close;

  @override
  ConsumerState<ChannelSearchSheet> createState() => _ChannelSearchSheetState();
}

class _ChannelSearchSheetState extends ConsumerState<ChannelSearchSheet> {
  late final TextEditingController _textController;
  late final TextEditingController _authorController;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _authorController = TextEditingController();
    _focusNode = FocusNode();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.scrollController.removeListener(_onScroll);
    _textController.dispose();
    _authorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = widget.scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - _kSheetLoadMoreThreshold) {
      unawaited(
        ref
            .read(
              channelSearchProvider(widget.channelId, widget.guildId).notifier,
            )
            .loadMore(),
      );
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  void _runSearch() {
    final state = ref.read(
      channelSearchProvider(widget.channelId, widget.guildId),
    );
    unawaited(
      ref
          .read(
            channelSearchProvider(widget.channelId, widget.guildId).notifier,
          )
          .search(
            text: _textController.text,
            authorId: _authorController.text,
            scope: state.query.scope,
            sort: state.query.sort,
            contentType: state.query.contentType,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      channelSearchProvider(widget.channelId, widget.guildId),
    );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
          child: Column(
            children: [
              FluxerInput(
                controller: _textController,
                focusNode: _focusNode,
                hint: 'Search messages',
                prefixIcon: const PhosphorIcon(
                  PhosphorIconsBold.magnifyingGlass,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => _scheduleSearch(),
                onSubmitted: (_) => _runSearch(),
              ),
              SizedBox(height: context.layout.s2),
              FluxerInput(
                controller: _authorController,
                hint: 'Author ID',
                prefixIcon: const PhosphorIcon(PhosphorIconsBold.user),
                textInputAction: TextInputAction.search,
                onChanged: (_) => _scheduleSearch(),
                onSubmitted: (_) => _runSearch(),
              ),
              SizedBox(height: context.layout.s2),
              Wrap(
                spacing: context.layout.s2,
                runSpacing: context.layout.s2,
                children: [
                  _SearchDropdown<MessageSearchScopeFilter>(
                    value: state.query.scope,
                    items: MessageSearchScopeFilter.values,
                    labelFor: _scopeLabel,
                    onChanged: (value) => _updateFilters(scope: value),
                  ),
                  _SearchDropdown<MessageSearchSortFilter>(
                    value: state.query.sort,
                    items: MessageSearchSortFilter.values,
                    labelFor: _sortLabel,
                    onChanged: (value) => _updateFilters(sort: value),
                  ),
                  _SearchDropdown<MessageSearchContentFilter>(
                    value: state.query.contentType,
                    items: MessageSearchContentFilter.values,
                    labelFor: _contentLabel,
                    onChanged: (value) => _updateFilters(contentType: value),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.layout.s3),
        Expanded(child: _buildResults(context, state)),
      ],
    );
  }

  void _updateFilters({
    MessageSearchScopeFilter? scope,
    MessageSearchSortFilter? sort,
    MessageSearchContentFilter? contentType,
  }) {
    final state = ref.read(
      channelSearchProvider(widget.channelId, widget.guildId),
    );
    unawaited(
      ref
          .read(
            channelSearchProvider(widget.channelId, widget.guildId).notifier,
          )
          .search(
            text: _textController.text,
            authorId: _authorController.text,
            scope: scope ?? state.query.scope,
            sort: sort ?? state.query.sort,
            contentType: contentType ?? state.query.contentType,
          ),
    );
  }

  Widget _buildResults(BuildContext context, ChannelSearchState state) {
    if (!state.hasSearched) {
      return const _EmptySheetState(
        icon: PhosphorIconsBold.magnifyingGlass,
        title: 'Search this conversation',
        body: 'Enter text, an author, or a content filter to find messages.',
      );
    }
    if (state.isSearching) {
      return const Center(child: FluxerLoadingSpinner());
    }
    if (state.errorMessage != null) {
      return _ErrorSheetState(title: state.errorMessage!, onRetry: _runSearch);
    }
    if (state.indexing) {
      return const _EmptySheetState(
        icon: PhosphorIconsBold.clockCounterClockwise,
        title: 'Messages are indexing',
        body: 'Try again shortly once search finishes indexing this scope.',
      );
    }
    if (state.results.isEmpty) {
      return const _EmptySheetState(
        icon: PhosphorIconsBold.magnifyingGlass,
        title: 'No results',
        body: 'Try different search terms or filters.',
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(horizontal: context.layout.s3),
      itemCount: state.results.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: FluxerLoadingSpinner()),
          );
        }
        final entry = state.results[index];
        final label = entry.channelName == null
            ? _formatDate(entry.message.timestamp)
            : '#${entry.channelName} - ${_formatDate(entry.message.timestamp)}';
        return MessagePreviewTile(
          message: entry.message,
          label: label,
          guildId: entry.guildId,
          onTap: () => _jumpToMessage(
            context,
            ref,
            entry.message,
            guildId: entry.guildId,
            close: widget.close,
          ),
          onLongPress: () => _showSearchMessageActions(
            context,
            ref,
            entry: entry,
            close: widget.close,
          ),
        );
      },
    );
  }
}

class MessagePreviewTile extends StatelessWidget {
  const MessagePreviewTile({
    required this.message,
    required this.onTap,
    this.label,
    this.onLongPress,
    this.guildId,
    super.key,
  });

  final Message message;
  final String? label;
  final String? guildId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.colors.backgroundModifierHover,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasLabel)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    child: Text(
                      label!,
                      style: context.textStyles.timestamp.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ),
                MessageItem(
                  message: message,
                  inboxPreviewMode: true,
                  hideMentionHighlight: true,
                  previewRoleGuildId: guildId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DmMemberGroups extends ConsumerWidget {
  const _DmMemberGroups({required this.dm, required this.currentUserId});

  final DmConversation dm;
  final String? currentUserId;

  static bool _isOnline(String status) =>
      status != 'offline' && status != 'invisible';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = currentUserId;
    if (userId == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<db.User?>(
      future: ref.read(fluxerDatabaseProvider).userDao.getUserById(userId),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        final currentUserStatus = currentUser?.status ?? 'online';

        final onlineRows = <Widget>[];
        final offlineRows = <Widget>[];

        Widget currentUserRow() => _SimpleMemberRow(
              userId: userId,
              name: currentUser?.globalName ?? currentUser?.username ?? 'You',
              avatarUrl: currentUser?.avatar == null
                  ? null
                  : '$fluxerMediaCdn/avatars/$userId/${currentUser!.avatar}.png',
              avatarColor: currentUser?.avatarColor,
              status: currentUserStatus,
              isBot: currentUser?.bot ?? false,
              isCurrentUser: true,
              onTap: () =>
                  FluxerUserProfileSheet.show(context, userId: userId),
            );

        if (_isOnline(currentUserStatus)) {
          onlineRows.add(currentUserRow());
        } else {
          offlineRows.add(currentUserRow());
        }

        if (dm.isGroup) {
          for (final member in dm.groupMembers) {
            // Per-member presence isn't loaded into DmConversation yet.
            offlineRows.add(
              _SimpleMemberRow(
                userId: member.id,
                name: member.name,
                avatarUrl: _memberAvatarUrl(member),
                isCurrentUser: member.id == userId,
                onTap: () =>
                    FluxerUserProfileSheet.show(context, userId: member.id),
              ),
            );
          }
        } else if (!dm.isPersonalNotes) {
          final recipientRow = _SimpleMemberRow(
            userId: dm.recipientId,
            name: dm.recipientName,
            avatarUrl: _dmAvatarUrl(dm),
            status: dm.recipientStatus,
            isBot: dm.isBot,
            isSystem: dm.isSystem,
            onTap: () =>
                FluxerUserProfileSheet.show(context, userId: dm.recipientId),
          );
          if (_isOnline(dm.recipientStatus)) {
            onlineRows.add(recipientRow);
          } else {
            offlineRows.add(recipientRow);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onlineRows.isNotEmpty)
              FluxerListSection(
                header: 'Online — ${onlineRows.length}',
                children: onlineRows,
              ),
            if (offlineRows.isNotEmpty)
              FluxerListSection(
                header: 'Offline — ${offlineRows.length}',
                children: offlineRows,
              ),
          ],
        );
      },
    );
  }
}

class _SimpleMemberRow extends StatelessWidget {
  const _SimpleMemberRow({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.avatarColor,
    this.status = 'offline',
    this.isBot = false,
    this.isSystem = false,
    this.isCurrentUser = false,
    this.isOwner = false,
    this.customStatus,
    this.dimmed = false,
    this.onTap,
    this.onLongPress,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final int? avatarColor;
  final String status;
  final bool isBot;
  final bool isSystem;
  final bool isCurrentUser;
  final bool isOwner;
  final String? customStatus;
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return FluxerListRow(
      leading: FluxerAvatar.user(
        fallbackText: name,
        userId: userId,
        imageUrl: avatarUrl,
        avatarColor: avatarColor,
        status: status,
        size: 36,
      ),
      title: name,
      subtitle: customStatus,
      dimmed: dimmed,
      onTap: onTap,
      onLongPress: onLongPress,
      titleAdornments: [
        if (isOwner)
          const PhosphorIcon(
            PhosphorIconsFill.crown,
            size: 14,
            color: Color(0xFFFAA61A),
          ),
        if (isCurrentUser) const _MemberTag(label: 'You'),
        if (isBot) const FluxerBotBadge(),
        if (isSystem) const _MemberTag(label: 'System'),
      ],
    );
  }
}

class _MemberTag extends StatelessWidget {
  const _MemberTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.brandPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: context.textStyles.smallText.copyWith(
          color: context.colors.brandPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NewGroupCtaRow extends StatelessWidget {
  const _NewGroupCtaRow({required this.recipientHandle, required this.onTap});

  final String recipientHandle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Material(
        color: colors.backgroundSecondaryAlt,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: PhosphorIcon(
                      PhosphorIconsFill.chatCircle,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New Group',
                        style: context.textStyles.username.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create a new group with $recipientHandle',
                        style: context.textStyles.bodySmall.copyWith(
                          color: colors.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: 20,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenderGroup {
  final String displayName;
  final List<Member> members;
  final Color? headerColor;
  final bool dimMembers;

  const _RenderGroup({
    required this.displayName,
    required this.members,
    this.headerColor,
    this.dimMembers = false,
  });
}

bool _isMemberOnline(Member m) => m.status != 'offline';

List<_RenderGroup> _splitOnlineOffline(List<RoleGroup> roleGroups) {
  final online = <_RenderGroup>[];
  final offline = <Member>[];

  for (final group in roleGroups) {
    final onlineMembers = group.members.where(_isMemberOnline).toList();
    final offlineMembers = group.members.where((m) => !_isMemberOnline(m));
    offline.addAll(offlineMembers);
    if (onlineMembers.isEmpty) {
      continue;
    }
    final base = group.role?.name ?? 'Online';
    online.add(
      _RenderGroup(
        displayName: '$base — ${onlineMembers.length}',
        members: onlineMembers,
        headerColor: group.role != null ? Color(group.role!.color) : null,
      ),
    );
  }

  if (offline.isNotEmpty) {
    online.add(
      _RenderGroup(
        displayName: 'Offline — ${offline.length}',
        members: offline,
        dimMembers: true,
      ),
    );
  }
  return online;
}

class _SearchDropdown<T> extends StatelessWidget {
  const _SearchDropdown({
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  // Generic dropdown callbacks preserve enum-specific labels and selections.
  // ignore: unsafe_variance
  final String Function(T value) labelFor;
  // Generic dropdown callbacks preserve enum-specific labels and selections.
  // ignore: unsafe_variance
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            dropdownColor: context.colors.backgroundSecondary,
            style: context.textStyles.label.copyWith(
              color: context.colors.textPrimary,
            ),
            items: [
              for (final item in items)
                DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
            ],
            onChanged: (next) {
              if (next != null) {
                onChanged(next);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _EmptySheetState extends StatelessWidget {
  const _EmptySheetState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 42, color: context.colors.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              style: context.textStyles.channelName,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              body,
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

class _ErrorSheetState extends StatelessWidget {
  const _ErrorSheetState({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsBold.warning,
              size: 42,
              color: context.colors.statusDanger,
            ),
            const SizedBox(height: 12),
            Text(title, style: context.textStyles.channelName),
            const SizedBox(height: 12),
            FluxerButton.secondary(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.statusDanger,
              ),
            ),
          ),
          FluxerButton.secondary(
            label: 'Retry',
            size: FluxerButtonSize.small,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _MuteSelection {
  const _MuteSelection({required this.muted, this.durationSeconds});

  final bool muted;
  final int? durationSeconds;
}

enum _PinnedMessageAction { jump, unpin, copyMessageId, copyMessageLink }

Future<void> _showMuteSheet(
  BuildContext context, {
  required bool isMuted,
  required Future<void> Function({required bool isMuted, int? durationSeconds})
  onSelected,
}) async {
  final result = await FluxerBottomSheet.show<_MuteSelection>(
    context,
    title: isMuted ? 'Unmute' : 'Mute',
    variant: FluxerBottomSheetVariant.menu,
    builder: (sheetContext, close) {
      void select(_MuteSelection selection) {
        close();
        unawaited(
          onSelected(
            isMuted: selection.muted,
            durationSeconds: selection.durationSeconds,
          ),
        );
      }

      return FluxerBottomSheetContent(
        child: FluxerMenuGroup(
          children: isMuted
              ? [
                  FluxerBottomSheetMenuItem(
                    label: 'Unmute',
                    icon: PhosphorIconsBold.bell,
                    onTap: () => select(const _MuteSelection(muted: false)),
                  ),
                ]
              : [
                  FluxerBottomSheetMenuItem(
                    label: 'For 15 minutes',
                    onTap: () => select(
                      const _MuteSelection(
                        muted: true,
                        durationSeconds: 15 * 60,
                      ),
                    ),
                  ),
                  FluxerBottomSheetMenuItem(
                    label: 'For 1 hour',
                    onTap: () => select(
                      const _MuteSelection(
                        muted: true,
                        durationSeconds: 60 * 60,
                      ),
                    ),
                  ),
                  FluxerBottomSheetMenuItem(
                    label: 'For 8 hours',
                    onTap: () => select(
                      const _MuteSelection(
                        muted: true,
                        durationSeconds: 8 * 60 * 60,
                      ),
                    ),
                  ),
                  FluxerBottomSheetMenuItem(
                    label: 'For 24 hours',
                    onTap: () => select(
                      const _MuteSelection(
                        muted: true,
                        durationSeconds: 24 * 60 * 60,
                      ),
                    ),
                  ),
                  FluxerBottomSheetMenuItem(
                    label: 'Until I turn it back on',
                    icon: PhosphorIconsBold.bellSlash,
                    onTap: () => select(const _MuteSelection(muted: true)),
                  ),
                ],
        ),
      );
    },
  );

  if (result != null && context.mounted) {
    await onSelected(
      isMuted: result.muted,
      durationSeconds: result.durationSeconds,
    );
  }
}

void _stubComingSoon(BuildContext context, WidgetRef ref) {
  ref.read(toastProvider.notifier).show(
        const FluxerToast(message: 'Coming soon'),
      );
}

Future<void> _showGuildMemberActionsSheet(
  BuildContext context, {
  required WidgetRef ref,
  required Member member,
  required String? guildId,
  required bool isCurrentUser,
  required bool isOwner,
}) {
  return FluxerBottomSheet.show<void>(
    context,
    title: member.displayName,
    variant: FluxerBottomSheetVariant.menu,
    builder: (sheetContext, close) {
      void run(VoidCallback action) {
        close();
        action();
      }

      final canKick = !isCurrentUser && !isOwner;
      final canBan = !isCurrentUser && !isOwner;

      return FluxerBottomSheetContent(
        child: FluxerBottomSheetGroupColumn(
          children: <Widget>[
            FluxerMenuGroup(
              children: [
                FluxerBottomSheetMenuItem(
                  label: 'Open Profile',
                  icon: PhosphorIconsBold.user,
                  onTap: () => run(
                    () => FluxerUserProfileSheet.show(
                      context,
                      userId: member.id,
                    ),
                  ),
                ),
                FluxerBottomSheetMenuItem(
                  label: 'Copy User ID',
                  icon: PhosphorIconsRegular.snowflake,
                  onTap: () => run(() {
                    unawaited(
                      Clipboard.setData(ClipboardData(text: member.id)),
                    );
                    ref.read(toastProvider.notifier).show(
                          const FluxerToast(
                            message: 'Copied user ID',
                            variant: FluxerToastVariant.success,
                          ),
                        );
                  }),
                ),
              ],
            ),
            if (canKick || canBan)
              FluxerMenuGroup(
                children: [
                  if (canKick)
                    FluxerBottomSheetMenuItem(
                      label: 'Kick Member',
                      icon: PhosphorIconsBold.userMinus,
                      isDanger: true,
                      onTap: () => run(() => _stubComingSoon(context, ref)),
                    ),
                  if (canBan)
                    FluxerBottomSheetMenuItem(
                      label: 'Ban Member',
                      icon: PhosphorIconsBold.prohibit,
                      isDanger: true,
                      onTap: () => run(() => _stubComingSoon(context, ref)),
                    ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _showDetailsMoreSheet(
  BuildContext context, {
  required WidgetRef ref,
  required Channel? channel,
  required DmConversation? dm,
  required bool showFavorite,
  required bool isFavorite,
  required bool isDmPinned,
  required bool hasUnread,
  required int channelPermissionBits,
  required Future<void> Function() onMarkRead,
  required Future<void> Function({required bool isFavorite}) onToggleFavorite,
  required Future<void> Function({required bool isPinned}) onToggleDmPin,
  required Future<void> Function(UserNotificationSettings setting)
  onSetNotification,
  required Future<void> Function(String value) onCopy,
  required Future<void> Function() onCloseDm,
}) {
  final channelId = channel?.id ?? dm?.id;
  final title = dm == null
      ? 'Channel Settings'
      : (dm.isGroup ? 'Group Settings' : 'DM Settings');
  return FluxerBottomSheet.show<void>(
    context,
    title: title,
    variant: FluxerBottomSheetVariant.menu,
    builder: (sheetContext, close) {
      void run(Future<void> Function() action) {
        close();
        unawaited(action());
      }

      final canManageChannel = channel != null &&
          hasPermission(channelPermissionBits, Permission.manageChannels);
      final canCreateInvite = channel != null &&
          hasPermission(channelPermissionBits, Permission.createInstantInvite);

      final groups = <Widget>[
        FluxerMenuGroup(
          children: [
            if (showFavorite)
              FluxerBottomSheetMenuItem(
                label: isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
                icon: isFavorite
                    ? PhosphorIconsFill.star
                    : PhosphorIconsBold.star,
                onTap: () =>
                    run(() => onToggleFavorite(isFavorite: isFavorite)),
              ),
            if (hasUnread)
              FluxerBottomSheetMenuItem(
                label: 'Mark as Read',
                icon: PhosphorIconsBold.checkCircle,
                onTap: () => run(onMarkRead),
              ),
            if (dm != null && !dm.isPersonalNotes)
              FluxerBottomSheetMenuItem(
                label: dm.isGroup
                    ? (isDmPinned ? 'Unpin Group DM' : 'Pin Group DM')
                    : (isDmPinned ? 'Unpin DM' : 'Pin DM'),
                icon: PhosphorIconsBold.pushPin,
                onTap: () => run(() => onToggleDmPin(isPinned: isDmPinned)),
              ),
          ],
        ),
        if (canCreateInvite)
          FluxerMenuGroup(
            children: [
              FluxerBottomSheetMenuItem(
                label: 'Invite People',
                icon: PhosphorIconsBold.userPlus,
                onTap: () {
                  close();
                  _stubComingSoon(context, ref);
                },
              ),
            ],
          ),
        if (dm != null && dm.isGroup)
          FluxerMenuGroup(
            children: [
              FluxerBottomSheetMenuItem(
                label: 'Edit Group',
                icon: PhosphorIconsBold.pencilSimple,
                onTap: () {
                  close();
                  _stubComingSoon(context, ref);
                },
              ),
              FluxerBottomSheetMenuItem(
                label: 'Add Friends to Group',
                icon: PhosphorIconsBold.userPlus,
                onTap: () {
                  close();
                  _stubComingSoon(context, ref);
                },
              ),
              FluxerBottomSheetMenuItem(
                label: 'Group Invites',
                icon: PhosphorIconsBold.envelope,
                onTap: () {
                  close();
                  _stubComingSoon(context, ref);
                },
              ),
            ],
          ),
        if (channel != null)
          FluxerMenuGroup(
            children: [
              FluxerBottomSheetSubmenuItem(
                label: 'Notification Settings',
                icon: PhosphorIconsBold.bellRinging,
                onTap: () {
                  close();
                  unawaited(
                    _showNotificationSettingsSheet(
                      context,
                      channel: channel,
                      onSetNotification: onSetNotification,
                    ),
                  );
                },
              ),
            ],
          ),
        if (channelId != null)
          FluxerMenuGroup(
            children: [
              if (channel != null)
                FluxerBottomSheetMenuItem(
                  label: 'Copy Channel Link',
                  icon: PhosphorIconsBold.link,
                  onTap: () => run(
                    () => onCopy(_channelLink(channelId, channel.guildId)),
                  ),
                ),
              if (dm != null && !dm.isGroup && !dm.isPersonalNotes)
                FluxerBottomSheetMenuItem(
                  label: 'Copy User ID',
                  icon: PhosphorIconsRegular.snowflake,
                  onTap: () => run(() => onCopy(dm.recipientId)),
                ),
              FluxerBottomSheetMenuItem(
                label: 'Copy Channel ID',
                icon: PhosphorIconsRegular.snowflake,
                onTap: () => run(() => onCopy(channelId)),
              ),
            ],
          ),
        if (canManageChannel)
          FluxerMenuGroup(
            children: [
              FluxerBottomSheetMenuItem(
                label: 'Edit Channel',
                icon: PhosphorIconsBold.pencilSimple,
                onTap: () {
                  close();
                  _stubComingSoon(context, ref);
                },
              ),
              FluxerBottomSheetMenuItem(
                label: 'Delete Channel',
                icon: PhosphorIconsBold.trash,
                isDanger: true,
                onTap: () {
                  close();
                  _stubComingSoon(context, ref);
                },
              ),
            ],
          ),
        if (dm != null && !dm.isPersonalNotes)
          FluxerMenuGroup(
            children: [
              FluxerBottomSheetMenuItem(
                label: dm.isGroup ? 'Leave Group' : 'Close DM',
                icon: PhosphorIconsBold.xCircle,
                isDanger: true,
                onTap: () => run(onCloseDm),
              ),
            ],
          ),
      ];

      return FluxerBottomSheetContent(
        child: FluxerBottomSheetGroupColumn(children: groups),
      );
    },
  );
}

Future<void> _showNotificationSettingsSheet(
  BuildContext context, {
  required Channel channel,
  required Future<void> Function(UserNotificationSettings setting)
  onSetNotification,
}) async {
  final info = await _readChannelNotificationInfo(context, channel);
  if (!context.mounted) {
    return;
  }

  final defaultLabel = info.hasCategory
      ? 'Category Default'
      : 'Community Default';
  final defaultHint = _notificationLabel(info.effectiveDefault);

  await FluxerBottomSheet.show<void>(
    context,
    title: 'Notification Settings',
    variant: FluxerBottomSheetVariant.menu,
    builder: (sheetContext, close) {
      void select(UserNotificationSettings setting) {
        close();
        unawaited(onSetNotification(setting));
      }

      return FluxerBottomSheetContent(
        child: FluxerMenuGroup(
          children: [
            FluxerBottomSheetMenuItem(
              label: defaultLabel,
              hint: defaultHint,
              icon: PhosphorIconsBold.bell,
              isSelected: info.selected == UserNotificationSettings.inherit,
              onTap: () => select(UserNotificationSettings.inherit),
            ),
            FluxerBottomSheetMenuItem(
              label: 'All Messages',
              icon: PhosphorIconsBold.bellRinging,
              isSelected: info.selected == UserNotificationSettings.allMessages,
              onTap: () => select(UserNotificationSettings.allMessages),
            ),
            FluxerBottomSheetMenuItem(
              label: 'Only @mentions',
              icon: PhosphorIconsBold.at,
              isSelected:
                  info.selected == UserNotificationSettings.onlyMentions,
              onTap: () => select(UserNotificationSettings.onlyMentions),
            ),
            FluxerBottomSheetMenuItem(
              label: 'Nothing',
              icon: PhosphorIconsBold.bellSlash,
              isSelected: info.selected == UserNotificationSettings.noMessages,
              onTap: () => select(UserNotificationSettings.noMessages),
            ),
          ],
        ),
      );
    },
  );
}

class _ChannelNotificationInfo {
  const _ChannelNotificationInfo({
    required this.selected,
    required this.effectiveDefault,
    required this.hasCategory,
  });

  final UserNotificationSettings selected;
  final UserNotificationSettings effectiveDefault;
  final bool hasCategory;
}

Future<_ChannelNotificationInfo> _readChannelNotificationInfo(
  BuildContext context,
  Channel channel,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final row = await container
      .read(fluxerDatabaseProvider)
      .userGuildSettingsDao
      .getByGuildId(channel.guildId);

  var selected = UserNotificationSettings.inherit;
  var guildDefault = UserNotificationSettings.allMessages;
  var categoryOverride = UserNotificationSettings.inherit;

  if (row != null) {
    try {
      final settings = UserGuildSettingsResponse.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
      selected =
          settings.channelOverrides?[channel.id]?.messageNotifications ??
          UserNotificationSettings.inherit;
      guildDefault = settings.messageNotifications;
      if (channel.parentId != null) {
        categoryOverride =
            settings
                .channelOverrides?[channel.parentId]
                ?.messageNotifications ??
            UserNotificationSettings.inherit;
      }
    } on Object {
      // Malformed override JSON falls back to defaults.
    }
  }

  final effectiveDefault = categoryOverride == UserNotificationSettings.inherit
      ? guildDefault
      : categoryOverride;

  return _ChannelNotificationInfo(
    selected: selected,
    effectiveDefault: effectiveDefault,
    hasCategory: channel.parentId != null,
  );
}

String _notificationLabel(UserNotificationSettings setting) {
  return switch (setting) {
    UserNotificationSettings.allMessages => 'All Messages',
    UserNotificationSettings.onlyMentions => 'Only @mentions',
    UserNotificationSettings.noMessages => 'Nothing',
    UserNotificationSettings.inherit => 'Default',
    UserNotificationSettings.$unknown => 'Default',
  };
}

Future<void> _showPinnedMessageActions(
  BuildContext context,
  WidgetRef ref, {
  required String channelId,
  required String? guildId,
  required PinnedMessageEntry entry,
  required VoidCallback close,
}) async {
  final canUnpin = await _canUnpinMessage(
    ref,
    channelId: channelId,
    guildId: guildId,
  );
  if (!context.mounted) {
    return;
  }
  final action = await FluxerBottomSheet.show<_PinnedMessageAction>(
    context,
    title: 'Pinned Message',
    variant: FluxerBottomSheetVariant.menu,
    builder: (sheetContext, _) {
      void pop(_PinnedMessageAction action) {
        Navigator.of(sheetContext).pop(action);
      }

      return FluxerBottomSheetContent(
        child: FluxerMenuGroup(
          children: [
            FluxerBottomSheetMenuItem(
              label: 'Jump to Message',
              icon: PhosphorIconsBold.arrowSquareOut,
              onTap: () => pop(_PinnedMessageAction.jump),
            ),
            if (canUnpin)
              FluxerBottomSheetMenuItem(
                label: 'Unpin Message',
                icon: PhosphorIconsBold.pushPinSlash,
                isDanger: true,
                onTap: () => pop(_PinnedMessageAction.unpin),
              ),
            FluxerBottomSheetMenuItem(
              label: 'Copy Message Link',
              icon: PhosphorIconsBold.link,
              onTap: () => pop(_PinnedMessageAction.copyMessageLink),
            ),
            FluxerBottomSheetMenuItem(
              label: 'Copy Message ID',
              icon: PhosphorIconsRegular.snowflake,
              onTap: () => pop(_PinnedMessageAction.copyMessageId),
            ),
          ],
        ),
      );
    },
  );

  if (action == null || !context.mounted) {
    return;
  }
  switch (action) {
    case _PinnedMessageAction.jump:
      await _jumpToMessage(context, ref, entry.message, close: close);
    case _PinnedMessageAction.unpin:
      await ref.read(channelPinsProvider(channelId).notifier).unpin(entry);
      ref
          .read(toastProvider.notifier)
          .show(
            const FluxerToast(
              message: 'Message unpinned',
              variant: FluxerToastVariant.success,
            ),
          );
    case _PinnedMessageAction.copyMessageId:
      await Clipboard.setData(ClipboardData(text: entry.message.id));
      ref
          .read(toastProvider.notifier)
          .show(
            const FluxerToast(
              message: 'Copied to clipboard',
              variant: FluxerToastVariant.success,
            ),
          );
    case _PinnedMessageAction.copyMessageLink:
      await Clipboard.setData(
        ClipboardData(
          text: _messageLink(
            channelId: entry.message.channelId,
            messageId: entry.message.id,
            guildId: guildId,
          ),
        ),
      );
      ref
          .read(toastProvider.notifier)
          .show(
            const FluxerToast(
              message: 'Copied to clipboard',
              variant: FluxerToastVariant.success,
            ),
          );
  }
}

Future<void> _showSearchMessageActions(
  BuildContext context,
  WidgetRef ref, {
  required MessageSearchResultEntry entry,
  required VoidCallback close,
}) async {
  final action = await FluxerBottomSheet.show<_PinnedMessageAction>(
    context,
    title: 'Search Result',
    variant: FluxerBottomSheetVariant.menu,
    builder: (sheetContext, _) {
      void pop(_PinnedMessageAction action) {
        Navigator.of(sheetContext).pop(action);
      }

      return FluxerBottomSheetContent(
        child: FluxerMenuGroup(
          children: [
            FluxerBottomSheetMenuItem(
              label: 'Jump to Message',
              icon: PhosphorIconsBold.arrowSquareOut,
              onTap: () => pop(_PinnedMessageAction.jump),
            ),
            FluxerBottomSheetMenuItem(
              label: 'Copy Message Link',
              icon: PhosphorIconsBold.link,
              onTap: () => pop(_PinnedMessageAction.copyMessageLink),
            ),
            FluxerBottomSheetMenuItem(
              label: 'Copy Message ID',
              icon: PhosphorIconsRegular.snowflake,
              onTap: () => pop(_PinnedMessageAction.copyMessageId),
            ),
          ],
        ),
      );
    },
  );

  if (action == null || !context.mounted) {
    return;
  }
  switch (action) {
    case _PinnedMessageAction.jump:
      await _jumpToMessage(
        context,
        ref,
        entry.message,
        guildId: entry.guildId,
        close: close,
      );
    case _PinnedMessageAction.copyMessageId:
      await Clipboard.setData(ClipboardData(text: entry.message.id));
      ref
          .read(toastProvider.notifier)
          .show(
            const FluxerToast(
              message: 'Copied to clipboard',
              variant: FluxerToastVariant.success,
            ),
          );
    case _PinnedMessageAction.copyMessageLink:
      await Clipboard.setData(
        ClipboardData(
          text: _messageLink(
            channelId: entry.message.channelId,
            messageId: entry.message.id,
            guildId: entry.guildId,
          ),
        ),
      );
      ref
          .read(toastProvider.notifier)
          .show(
            const FluxerToast(
              message: 'Copied to clipboard',
              variant: FluxerToastVariant.success,
            ),
          );
    case _PinnedMessageAction.unpin:
      break;
  }
}

Future<bool> _canUnpinMessage(
  WidgetRef ref, {
  required String channelId,
  required String? guildId,
}) async {
  if (guildId == null) {
    return true;
  }
  try {
    final bits = await ref.read(
      _channelPermissionBitsProvider(channelId).future,
    );
    return hasPermission(bits, Permission.pinMessages) ||
        hasPermission(bits, Permission.manageMessages);
  } on Object {
    return false;
  }
}

Future<void> _updateGuildChannelOverride(
  WidgetRef ref, {
  required String guildId,
  required String channelId,
  bool? muted,
  int? durationSeconds,
  UserNotificationSettings? messageNotifications,
}) async {
  final database = ref.read(fluxerDatabaseProvider);
  final client = ref.read(fluxerClientProvider);
  final existing = await database.userGuildSettingsDao.getByGuildId(guildId);
  final data = <String, dynamic>{
    ..._defaultUserGuildSettingsData(guildId),
    if (existing != null) ...jsonDecode(existing.data) as Map<String, dynamic>,
  };

  ChannelOverrides? previous;
  try {
    previous = UserGuildSettingsResponse.fromJson(
      data,
    ).channelOverrides?[channelId];
  } on Object {
    previous = null;
  }

  final isExplicitUnmute = !(muted ?? true);
  final isExplicitMute = muted ?? false;
  final muteConfig = isExplicitUnmute
      ? null
      : isExplicitMute
      ? ChannelOverridesMuteConfig(
          endTime: durationSeconds == null
              ? null
              : DateTime.now()
                    .add(Duration(seconds: durationSeconds))
                    .toUtc()
                    .toIso8601String(),
          selectedTimeWindow: durationSeconds ?? -1,
        )
      : previous?.muteConfig;
  final override = ChannelOverrides(
    collapsed: previous?.collapsed ?? false,
    messageNotifications:
        messageNotifications ??
        previous?.messageNotifications ??
        UserNotificationSettings.inherit,
    muted: muted ?? previous?.muted ?? false,
    muteConfig: muteConfig,
  );

  final overrides =
      (data['channel_overrides'] as Map<String, dynamic>?) ??
      <String, dynamic>{};
  overrides[channelId] = override.toJson();
  data['channel_overrides'] = overrides;

  await database.userGuildSettingsDao.upsert(
    db.UserGuildSettingsTableCompanion(
      guildId: Value(guildId),
      data: Value(jsonEncode(data)),
    ),
  );
  await client.users.updateGuildSettingsForUser(
    guildId: guildId,
    body: UserGuildSettingsUpdateRequest(
      channelOverrides: {channelId: override},
    ),
  );
}

Map<String, dynamic> _defaultUserGuildSettingsData(String guildId) {
  return UserGuildSettingsResponse(
    guildId: guildId == '@me' ? null : guildId,
    messageNotifications: guildId == '@me'
        ? UserNotificationSettings.allMessages
        : UserNotificationSettings.inherit,
    muted: false,
    muteConfig: null,
    mobilePush: true,
    suppressEveryone: false,
    suppressRoles: false,
    hideMutedChannels: false,
    channelOverrides: null,
    version: -1,
  ).toJson();
}

String? _detailsSubtitle({
  required Channel? channel,
  required DmConversation? dm,
}) {
  if (dm != null) {
    if (dm.isPersonalNotes) {
      return 'Your private space';
    }
    if (dm.isGroup) {
      return 'Group DM · ${dm.memberCount} members';
    }
    final username = dm.recipientUsername;
    if (username != null &&
        username.isNotEmpty &&
        username != dm.recipientName) {
      return '@$username';
    }
    return dm.isSystem ? 'System message' : null;
  }
  if (channel != null) {
    return switch (channel.type) {
      ChannelType.text => 'Text channel',
      ChannelType.voice => 'Voice channel',
      ChannelType.announcement => 'Announcement channel',
      ChannelType.stage => 'Stage channel',
      ChannelType.category => 'Category',
      ChannelType.link => 'Linked channel',
    };
  }
  return null;
}

String? _dmAvatarUrl(DmConversation dm) {
  final avatar = dm.recipientAvatar;
  if (avatar == null) {
    return null;
  }
  return '$fluxerMediaCdn/avatars/${dm.recipientId}/$avatar.png';
}

String? _groupIconUrl(DmConversation dm) {
  final icon = dm.icon;
  if (icon == null) {
    return null;
  }
  return '$fluxerMediaCdn/icons/${dm.id}/$icon.png';
}

String? _memberAvatarUrl(GroupMemberInfo member) {
  final avatar = member.avatar;
  if (avatar == null) {
    return null;
  }
  return '$fluxerMediaCdn/avatars/${member.id}/$avatar.png';
}

String _channelLink(String channelId, String? guildId) {
  final scope = guildId == null || guildId.isEmpty ? '@me' : guildId;
  return 'https://fluxer.app/channels/$scope/$channelId';
}

String _messageLink({
  required String channelId,
  required String messageId,
  required String? guildId,
}) {
  return '${_channelLink(channelId, guildId)}/$messageId';
}

Future<void> _jumpToMessage(
  BuildContext context,
  WidgetRef ref,
  Message message, {
  required VoidCallback close,
  String? guildId,
}) async {
  final database = ref.read(fluxerDatabaseProvider);
  await database.messageDao.upsertMessage(message.toCompanion());
  final resolvedGuildId =
      guildId ??
      (await database.channelDao.getChannelById(message.channelId))?.guildId;

  if (!context.mounted) {
    return;
  }

  close();
  final path = resolvedGuildId == null || resolvedGuildId.isEmpty
      ? RoutePaths.dmChannelMessage(message.channelId, message.id)
      : RoutePaths.guildChannelMessage(
          resolvedGuildId,
          message.channelId,
          message.id,
        );
  ref.read(fluxerRouterProvider).go(path);
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day}/${local.year} $h:$m';
}

String _scopeLabel(MessageSearchScopeFilter value) => switch (value) {
  MessageSearchScopeFilter.current => 'Current',
  MessageSearchScopeFilter.openDms => 'Open DMs',
  MessageSearchScopeFilter.allDms => 'All DMs',
  MessageSearchScopeFilter.allGuilds => 'All communities',
  MessageSearchScopeFilter.all => 'All',
};

String _sortLabel(MessageSearchSortFilter value) => switch (value) {
  MessageSearchSortFilter.newest => 'Newest',
  MessageSearchSortFilter.oldest => 'Oldest',
  MessageSearchSortFilter.relevance => 'Relevance',
};

String _contentLabel(MessageSearchContentFilter value) => switch (value) {
  MessageSearchContentFilter.any => 'Any content',
  MessageSearchContentFilter.images => 'Images',
  MessageSearchContentFilter.videos => 'Videos',
  MessageSearchContentFilter.files => 'Files',
  MessageSearchContentFilter.links => 'Links',
  MessageSearchContentFilter.embeds => 'Embeds',
  MessageSearchContentFilter.stickers => 'Stickers',
};
