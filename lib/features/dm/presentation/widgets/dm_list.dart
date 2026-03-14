import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/navigate_to_content.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/dm/domain/dm_conversation.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DmList extends ConsumerWidget {
  const DmList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(dmViewModelProvider);
    final convos = vm.conversations;
    final selectedId = vm.selectedConversationId;

    return Container(
      width: 240,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: FluxerColors.channelSidebarBackground,
      child: Column(
        children: [
          if (!isMobileLayout(context)) ...[
            _buildQuickSwitcher(),
            const Divider(color: FluxerColors.divider, height: 1),
          ],

          _buildFriendsButton(context),
          _buildNavButton(
            icon: PhosphorIconsFill.notePencil,
            label: 'Personal Notes',
            onTap: () {
              final userId = ref.read(currentUserIdProvider);
              if (userId != null) {
                navigateToContent(context, '/channels/@me/$userId');
              }
            },
          ),
          _buildNavButton(
            icon: PhosphorIconsFill.skull,
            label: 'Plutonium',
            onTap: () {},
          ),
          const Divider(color: FluxerColors.divider, height: 1),
          _buildDmHeader(),
          Expanded(
            child: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: FluxerColors.blurple,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: convos.length,
                    itemBuilder: (context, index) {
                      final convo = convos[index];
                      final isSelected = convo.id == selectedId;
                      return _buildConvoTile(context, ref, convo, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSwitcher() => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        // decoration: const BoxDecoration(
        //   border: Border(
        //     bottom: BorderSide(color: FluxerColors.divider),
        //   ),
        // ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Quick Switcher',
                style: TextStyle(color: FluxerColors.textMuted, fontSize: 13),
              ),
            ),
            _buildKbdBadge('CTRL'),
            const SizedBox(width: 3),
            _buildKbdBadge('K'),
          ],
        ),
      ),
    ),
  );

  Widget _buildKbdBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: FluxerColors.backgroundModifierSelected,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: FluxerColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 1, 8, 1),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              PhosphorIcon(
                icon,
                size: 20,
                color: FluxerColors.interactiveNormal,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: FluxerColors.interactiveNormal,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildFriendsButton(BuildContext context) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.go('/channels/@me'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: const Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsFill.users,
                    size: 20,
                    color: FluxerColors.interactiveNormal,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Friends',
                    style: TextStyle(
                      color: FluxerColors.interactiveNormal,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildDmHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
    child: Row(
      children: [
        Expanded(
          child: Text('DIRECT MESSAGES', style: FluxerTextStyles.categoryName),
        ),
        const PhosphorIcon(
          PhosphorIconsRegular.plus,
          size: 16,
          color: FluxerColors.textMuted,
        ),
      ],
    ),
  );

  Widget _buildConvoTile(
    BuildContext context,
    WidgetRef ref,
    DmConversation convo,
    bool isSelected,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        ref.read(dmViewModelProvider.notifier).selectConversation(convo.id);
        navigateToContent(context, '/channels/@me/${convo.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? FluxerColors.backgroundModifierSelected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            UserAvatar(
              displayName: convo.recipientName,
              avatarUrl: _avatarUrl(convo),
              status: convo.recipientStatus,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    convo.recipientName,
                    style: TextStyle(
                      color: isSelected
                          ? FluxerColors.channelActive
                          : convo.unreadCount > 0
                          ? FluxerColors.textNormal
                          : FluxerColors.channelDefault,
                      fontSize: 16,
                      fontWeight: convo.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (convo.lastMessage.isNotEmpty)
                    Text(
                      convo.lastMessage,
                      style: const TextStyle(
                        color: FluxerColors.textMuted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            if (convo.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: FluxerColors.textDanger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${convo.unreadCount}',
                  style: const TextStyle(
                    color: FluxerColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  String? _avatarUrl(DmConversation convo) {
    final avatar = convo.recipientAvatar;
    if (avatar == null) {
      return null;
    }
    return 'https://fluxerusercontent.com'
        '/avatars/${convo.recipientId}/$avatar.png';
  }
}

