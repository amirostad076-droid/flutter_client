import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/features/friends/domain/friend.dart';
import 'package:fluxeron/features/servers/domain/server.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kActiveNowMinWidth = 1100.0;
const _kActiveNowWidth = 340.0;

class FriendsList extends ConsumerWidget {
  const FriendsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(dmViewModelProvider);
    final activeTab = vm.activeTab;

    final showActiveNow =
        MediaQuery.sizeOf(context).width >=
            _kActiveNowMinWidth;

    return ColoredBox(
      color: context.colors.chatBackground,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopBar(
                  context,
                  ref,
                  activeTab,
                  showActiveNow: showActiveNow,
                ),
                Divider(
                  color: context.colors.borderColor,
                  height: 1,
                ),
                _buildSearchBar(
                  context,
                  ref,
                  activeTab,
                ),
                _buildSectionHeader(context, vm),
                Expanded(
                  child: _buildFriendsList(
                    context,
                    vm,
                  ),
                ),
              ],
            ),
          ),
          if (showActiveNow)
            _buildActiveNowPanel(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    FriendsTab activeTab, {
    required bool showActiveNow,
  }) =>
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsFill.users,
              color:
                  context.colors.textPrimaryMuted,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'My Friends',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            VerticalDivider(
              color: context.colors.borderColor,
              width: 1,
              indent: 12,
              endIndent: 12,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tabButton(
                      context,
                      ref,
                      'Online',
                      FriendsTab.online,
                      activeTab,
                    ),
                    _tabButton(
                      context,
                      ref,
                      'All',
                      FriendsTab.all,
                      activeTab,
                    ),
                    _tabButton(
                      context,
                      ref,
                      'Pending',
                      FriendsTab.pending,
                      activeTab,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              flex: 0,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      context.colors.statusOnline,
                  foregroundColor:
                      context.colors.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  minimumSize: const Size(0, 28),
                  textStyle: const TextStyle(
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(3),
                  ),
                ),
                child: const Text(
                  'Add Friend',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tabButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    FriendsTab tab,
    FriendsTab activeTab,
  ) {
    final isActive = tab == activeTab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => ref
            .read(dmViewModelProvider.notifier)
            .selectTab(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? context.colors
                    .backgroundModifierSelected
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? context.colors.textPrimary
                  : context
                      .colors.interactiveNormal,
              fontSize: 14,
              fontWeight: isActive
                  ? FontWeight.w500
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    WidgetRef ref,
    FriendsTab activeTab,
  ) =>
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: ref
              .read(dmViewModelProvider.notifier)
              .updateSearch,
          style: TextStyle(
            color: context.colors.textChat,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search '
                '${_tabLabel(activeTab).toLowerCase()}'
                ' friends',
            hintStyle: TextStyle(
              color:
                  context.colors.textPrimaryMuted,
              fontSize: 14,
            ),
            prefixIcon: PhosphorIcon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 24,
              color:
                  context.colors.textPrimaryMuted,
            ),
          ),
        ),
      );

  String _tabLabel(FriendsTab tab) {
    switch (tab) {
      case FriendsTab.online:
        return 'Online';
      case FriendsTab.all:
        return 'All';
      case FriendsTab.pending:
        return 'Pending';
      case FriendsTab.blocked:
        return 'Blocked';
    }
  }

  Widget _buildSectionHeader(
    BuildContext context,
    DmViewState vm,
  ) {
    final filtered = vm.filteredFriends;
    final label =
        _tabLabel(vm.activeTab).toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$label \u2014 ${filtered.length}',
          style: TextStyle(
            color: context.colors.textPrimaryMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveNowPanel(
    BuildContext context,
  ) =>
      Container(
        width: _kActiveNowWidth,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: context.colors.borderColor,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'Active Now',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(
              color: context.colors.borderColor,
              height: 1,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'z\u1DBB',
                        style: TextStyle(
                          color: context.colors
                              .textPrimaryMuted,
                          fontSize: 48,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "It's quiet for now...",
                        style: TextStyle(
                          color: context
                              .colors.textChat,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When friends are active '
                        'in voice channels, their '
                        'activity will appear '
                        'here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors
                              .textPrimaryMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildFriendsList(
    BuildContext context,
    DmViewState vm,
  ) {
    if (vm.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colors.brandPrimary,
        ),
      );
    }
    final filtered = vm.filteredFriends;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No friends found',
          style: TextStyle(
            color: context.colors.textPrimaryMuted,
            fontSize: 16,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final friend = filtered[index];
        return _buildFriendTile(context, friend);
      },
    );
  }

  Widget _buildFriendTile(
    BuildContext context,
    Friend friend,
  ) =>
      DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: context.colors.borderColor,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Row(
                children: [
                  UserAvatar(
                    displayName:
                        friend.displayName,
                    avatarUrl:
                        _friendAvatarUrl(friend),
                    avatarColor: friend.avatarColor,
                    status: friend.status,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayName,
                          style: TextStyle(
                            color: context
                                .colors.textChat,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        Text(
                          _statusText(friend),
                          style: TextStyle(
                            color: context.colors
                                .textPrimaryMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (friend.friendStatus ==
                      FriendStatus.accepted) ...[
                    IconButton(
                      icon: const PhosphorIcon(
                        PhosphorIconsFill
                            .chatCircle,
                      ),
                      color: context
                          .colors.interactiveNormal,
                      iconSize: 20,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const PhosphorIcon(
                        PhosphorIconsRegular
                            .dotsThreeVertical,
                      ),
                      color: context
                          .colors.interactiveNormal,
                      iconSize: 20,
                      onPressed: () {},
                    ),
                  ],
                  if (friend.friendStatus ==
                      FriendStatus
                          .pendingIncoming) ...[
                    IconButton(
                      icon: const PhosphorIcon(
                        PhosphorIconsFill
                            .checkCircle,
                      ),
                      color: context
                          .colors.statusOnline,
                      iconSize: 20,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const PhosphorIcon(
                        PhosphorIconsFill.xCircle,
                      ),
                      color: context
                          .colors.textDanger,
                      iconSize: 20,
                      onPressed: () {},
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  String? _friendAvatarUrl(Friend friend) {
    final avatar = friend.avatar;
    if (avatar == null) {
      return null;
    }
    return '$fluxerMediaCdn'
        '/avatars/${friend.id}/$avatar.png';
  }

  String _statusText(Friend friend) {
    switch (friend.friendStatus) {
      case FriendStatus.accepted:
        return friend.customStatus ??
            friend.status[0].toUpperCase() +
                friend.status.substring(1);
      case FriendStatus.pendingIncoming:
        return 'Incoming Friend Request';
      case FriendStatus.pendingOutgoing:
        return 'Outgoing Friend Request';
      case FriendStatus.blocked:
        return 'Blocked';
    }
  }
}
