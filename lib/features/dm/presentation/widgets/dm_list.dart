import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/router/navigate_to_content.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/dm/domain/dm_conversation.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DmList extends ConsumerWidget {
  const DmList({super.key});

  void personalNote(WidgetRef ref, BuildContext context) {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      navigateToContent(
        context,
        '/channels/@me/$userId',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(dmViewModelProvider);
    final convos = vm.conversations;
    final selectedId = vm.selectedConversationId;

    final isMobile = isMobileLayout(context);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      color: context.colors.channelSidebarBackground,
      child: Column(
        children: [
          if (isMobile)
            _buildMobileHeader(context)
          else ...[
            _buildQuickSwitcher(context),
            Divider(
              color: context.colors.borderColor,
              height: 1,
            ),
            Builder(
              builder: (context) {
                final location = GoRouterState.of(
                  context,
                ).matchedLocation;
                final userId =
                    ref.watch(currentUserIdProvider);
                final isFriends =
                    location == '/channels/@me';
                final isNotes = userId != null &&
                    location ==
                        '/channels/@me/$userId';

                return Padding(
                  padding:
                      const EdgeInsets.only(top: 7),
                  child: Column(
                    children: [
                      _buildNavButton(
                        context,
                        icon: PhosphorIconsFill.users,
                        label: 'Friends',
                        isSelected: isFriends,
                        onTap: () => context
                            .go('/channels/@me'),
                      ),
                      _buildNavButton(
                        context,
                        icon: PhosphorIconsFill
                            .notePencil,
                        label: 'Personal Notes',
                        isSelected: isNotes,
                        onTap: () {
                          if (userId != null) {
                            navigateToContent(
                              context,
                              '/channels/@me/$userId',
                            );
                          }
                        },
                      ),
                      _buildNavButton(
                        context,
                        icon: PhosphorIconsFill.skull,
                        label: 'Plutonium',
                        onTap: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(
              color: context.colors.borderColor,
              height: 1,
            ),
            _buildDmHeader(context),
          ],
          Expanded(
            child: vm.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color:
                          context.colors.brandPrimary,
                    ),
                  )
                : _buildConvoList(
                    context,
                    ref,
                    convos,
                    selectedId,
                    isMobile: isMobile,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSwitcher(
    BuildContext context,
  ) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Quick Switcher',
                    style: TextStyle(
                      color: context
                          .colors.textPrimaryMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                _buildKbdBadge(context, 'CTRL'),
                const SizedBox(width: 3),
                _buildKbdBadge(context, 'K'),
              ],
            ),
          ),
        ),
      );

  Widget _buildKbdBadge(
    BuildContext context,
    String label,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: context
              .colors.backgroundModifierSelected,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: context.colors.textPrimaryMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 1, 8, 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              decoration: isSelected
                  ? BoxDecoration(
                      color: context.colors
                          .backgroundModifierSelected,
                      borderRadius:
                          BorderRadius.circular(4),
                    )
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context
                              .colors.brandPrimary
                          : context.colors
                              .backgroundModifierAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? context
                                .colors.textPrimary
                            : context.colors
                                .interactiveNormal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? context.colors.textChat
                          : context.colors
                              .interactiveNormal,
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

  Widget _buildMobileHeader(
    BuildContext context,
  ) =>
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Messages',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: PhosphorIcon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 22,
                color:
                    context.colors.interactiveNormal,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () =>
                  context.go('/channels/@me'),
              borderRadius:
                  BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors
                      .backgroundModifierAccent,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsFill.userPlus,
                      size: 16,
                      color: context.colors.textChat,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add Friends',
                      style: TextStyle(
                        color:
                            context.colors.textChat,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildConvoList(
    BuildContext context,
    WidgetRef ref,
    List<DmConversation> convos,
    String? selectedId, {
    required bool isMobile,
  }) {
    final userId = ref.watch(currentUserIdProvider);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount:
          convos.length + (isMobile ? 1 : 0),
      itemBuilder: (context, index) {
        if (isMobile && index == 0) {
          return _buildMobilePersonalNotes(
            context,
            ref,
            userId,
          );
        }
        final convoIndex =
            isMobile ? index - 1 : index;
        final convo = convos[convoIndex];
        final isSelected = convo.id == selectedId;
        return _buildConvoTile(
          context,
          ref,
          convo: convo,
          isSelected: isSelected,
        );
      },
    );
  }

  Widget _buildMobilePersonalNotes(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (userId != null) {
              navigateToContent(
                context,
                '/channels/@me/$userId',
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors
                        .backgroundModifierAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      PhosphorIconsFill.notePencil,
                      size: 20,
                      color: context
                          .colors.interactiveNormal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Notes',
                  style: TextStyle(
                    color: context.colors.textChat,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildDmHeader(BuildContext context) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          8,
          4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'DIRECT MESSAGES',
                style:
                    context.textStyles.categoryName,
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.plus,
              size: 16,
              color:
                  context.colors.textPrimaryMuted,
            ),
          ],
        ),
      );

  static const double _convoAvatarSize = 32;

  Widget _buildConvoTile(
    BuildContext context,
    WidgetRef ref, {
    DmConversation? convo,
    required bool isSelected,
    IconData? leadingIcon,
    String? leadingLabel,
    VoidCallback? onCustomTap,
  }) {
    final isIconTile = leadingIcon != null &&
        leadingLabel != null &&
        onCustomTap != null;
    if (isIconTile) {
      return _buildConvoStyleTile(
        context: context,
        leading: _buildCircleIcon(
          context,
          leadingIcon,
          isSelected,
        ),
        label: leadingLabel,
        isSelected: isSelected,
        onTap: onCustomTap,
      );
    }
    final c = convo!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref
              .read(dmViewModelProvider.notifier)
              .selectConversation(c.id);
          navigateToContent(
            context,
            '/channels/@me/${c.id}',
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors
                    .backgroundModifierSelected
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              UserAvatar(
                displayName: c.recipientName,
                avatarUrl: _avatarUrl(c),
                status: c.recipientStatus,
                size: _convoAvatarSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.recipientName,
                      style: TextStyle(
                        color: isSelected
                            ? context
                                .colors.textPrimary
                            : c.unreadCount > 0
                                ? context
                                    .colors.textChat
                                : context.colors
                                    .textTertiary,
                        fontSize: 16,
                        fontWeight:
                            c.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                      ),
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                    if (c.lastMessage.isNotEmpty)
                      Text(
                        c.lastMessage,
                        style: TextStyle(
                          color: context.colors
                              .textPrimaryMuted,
                          fontSize: 12,
                        ),
                        overflow:
                            TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              if (c.unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color:
                        context.colors.textDanger,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${c.unreadCount}',
                    style: TextStyle(
                      color: context
                          .colors.textPrimary,
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
  }

  Widget _buildCircleIcon(
    BuildContext context,
    IconData icon,
    bool isSelected,
  ) {
    return Container(
      width: _convoAvatarSize,
      height: _convoAvatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? context.colors.brandPrimary
            : context.colors.backgroundTertiary,
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        icon,
        size: 20,
        color: isSelected
            ? context.colors.textPrimary
            : context.colors.interactiveNormal,
      ),
    );
  }

  Widget _buildConvoStyleTile({
    required BuildContext context,
    required Widget leading,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 1,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors
                      .backgroundModifierSelected
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? context
                              .colors.textPrimary
                          : context
                              .colors.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow:
                        TextOverflow.ellipsis,
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
