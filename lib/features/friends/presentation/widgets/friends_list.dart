import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/features/friends/domain/friend.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';

class FriendsList extends ConsumerWidget {
  const FriendsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(dmViewModelProvider);
    final activeTab = vm.activeTab;

    return ColoredBox(
      color: FluxerColors.chatBackground,
      child: Column(
        children: [
          _buildTopBar(ref, activeTab),
          const Divider(color: FluxerColors.divider, height: 1),
          _buildSearchBar(ref),
          Expanded(child: _buildFriendsList(vm)),
        ],
      ),
    );
  }

  Widget _buildTopBar(WidgetRef ref, FriendsTab activeTab) => Container(
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
          'Friends',
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
        _tabButton(ref, 'Online', FriendsTab.online, activeTab),
        _tabButton(ref, 'All', FriendsTab.all, activeTab),
        _tabButton(ref, 'Pending', FriendsTab.pending, activeTab),
        _tabButton(ref, 'Blocked', FriendsTab.blocked, activeTab),
        const SizedBox(width: 16),
        ElevatedButton(
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
          child: const Text('Add Friend'),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(dmViewModelProvider.notifier).selectTab(tab),
          borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(16),
    child: Container(
      height: 32,
      decoration: BoxDecoration(
        color: FluxerColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        onChanged: ref.read(dmViewModelProvider.notifier).updateSearch,
        style: const TextStyle(color: FluxerColors.textNormal, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: FluxerColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 6),
          suffixIcon: PhosphorIcon(
            PhosphorIconsFill.magnifyingGlass,
            size: 18,
            color: FluxerColors.textMuted,
          ),
          suffixIconConstraints: BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ),
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
                  icon: const PhosphorIcon(PhosphorIconsFill.dotsThreeVertical),
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
    return 'https://fluxerusercontent.com'
        '/avatars/${friend.id}/$avatar.png';
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
