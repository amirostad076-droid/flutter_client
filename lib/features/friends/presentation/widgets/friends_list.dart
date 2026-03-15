import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
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

    final showActiveNow = MediaQuery.sizeOf(context).width >= _kActiveNowMinWidth;

    return ColoredBox(
      color: FluxerColors.chatBackground,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopBar(ref, activeTab, showActiveNow: showActiveNow),
                const Divider(color: FluxerColors.divider, height: 1),
                _buildSearchBar(ref, activeTab),
                _buildSectionHeader(vm),
                Expanded(child: _buildFriendsList(vm)),
              ],
            ),
          ),
          if (showActiveNow) _buildActiveNowPanel(),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    WidgetRef ref,
    FriendsTab activeTab, {
    required bool showActiveNow,
  }) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        const PhosphorIcon(
          PhosphorIconsFill.users,
          color: FluxerColors.textMuted,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'My Friends',
          style: TextStyle(
            color: FluxerColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        const VerticalDivider(
          color: FluxerColors.divider,
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
                _tabButton(ref, 'Online', FriendsTab.online, activeTab),
                _tabButton(ref, 'All', FriendsTab.all, activeTab),
                _tabButton(ref, 'Pending', FriendsTab.pending, activeTab),
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
              backgroundColor: FluxerColors.online,
              foregroundColor: FluxerColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 28),
              textStyle: const TextStyle(fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
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
    WidgetRef ref,
    String label,
    FriendsTab tab,
    FriendsTab activeTab,
  ) {
    final isActive = tab == activeTab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => ref.read(dmViewModelProvider.notifier).selectTab(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? FluxerColors.backgroundModifierSelected
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? FluxerColors.channelActive
                  : FluxerColors.interactiveNormal,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref, FriendsTab activeTab) => Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      onChanged: ref.read(dmViewModelProvider.notifier).updateSearch,
      style: const TextStyle(
        color: FluxerColors.textNormal,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search ${_tabLabel(activeTab).toLowerCase()} friends',
        hintStyle: const TextStyle(
          color: FluxerColors.textMuted,
          fontSize: 14,
        ),
        prefixIcon: const PhosphorIcon(
          PhosphorIconsRegular.magnifyingGlass,
          size: 24,
          color: FluxerColors.textMuted,
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

  Widget _buildSectionHeader(DmViewState vm) {
    final filtered = vm.filteredFriends;
    final label = _tabLabel(vm.activeTab).toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$label \u2014 ${filtered.length}',
          style: const TextStyle(
            color: FluxerColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveNowPanel() => Container(
    width: _kActiveNowWidth,
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: FluxerColors.divider)),
    ),
    child: Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Active Now',
            style: TextStyle(
              color: FluxerColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Divider(color: FluxerColors.divider, height: 1),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'z\u1DBB',
                    style: TextStyle(
                      color: FluxerColors.textMuted,
                      fontSize: 48,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "It's quiet for now...",
                    style: TextStyle(
                      color: FluxerColors.textNormal,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'When friends are active in voice channels, their activity will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FluxerColors.textMuted,
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

  Widget _buildFriendsList(DmViewState vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: FluxerColors.blurple),
      );
    }
    final filtered = vm.filteredFriends;
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No friends found',
          style: TextStyle(color: FluxerColors.textMuted, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final friend = filtered[index];
        return _buildFriendTile(friend);
      },
    );
  }

  Widget _buildFriendTile(Friend friend) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: FluxerColors.divider)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              UserAvatar(
                displayName: friend.displayName,
                avatarUrl: _friendAvatarUrl(friend),
                avatarColor: friend.avatarColor,
                status: friend.status,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: const TextStyle(
                        color: FluxerColors.textNormal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _statusText(friend),
                      style: const TextStyle(
                        color: FluxerColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (friend.friendStatus == FriendStatus.accepted) ...[
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsFill.chatCircle),
                  color: FluxerColors.interactiveNormal,
                  iconSize: 20,
                  onPressed: () {},
                ),
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsRegular.dotsThreeVertical),
                  color: FluxerColors.interactiveNormal,
                  iconSize: 20,
                  onPressed: () {},
                ),
              ],
              if (friend.friendStatus == FriendStatus.pendingIncoming) ...[
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsFill.checkCircle),
                  color: FluxerColors.online,
                  iconSize: 20,
                  onPressed: () {},
                ),
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsFill.xCircle),
                  color: FluxerColors.textDanger,
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
    return '$fluxerMediaCdn/avatars/${friend.id}/$avatar.png';
  }

  String _statusText(Friend friend) {
    switch (friend.friendStatus) {
      case FriendStatus.accepted:
        return friend.customStatus ??
            friend.status[0].toUpperCase() + friend.status.substring(1);
      case FriendStatus.pendingIncoming:
        return 'Incoming Friend Request';
      case FriendStatus.pendingOutgoing:
        return 'Outgoing Friend Request';
      case FriendStatus.blocked:
        return 'Blocked';
    }
  }
}
