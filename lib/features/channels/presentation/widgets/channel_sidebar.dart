import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/navigate_to_content.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/domain/channel.dart';
import 'package:fluxeron/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/channels/providers/unread_provider.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';
import 'package:fluxeron/shared/widgets/unread_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChannelSidebar extends ConsumerWidget {
  const ChannelSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(channelListViewModelProvider);
    final serverName = state.serverName;
    final categories = state.categories;
    final selectedId = state.selectedChannelId;
    final collapsed = state.collapsedCategories;

    return Container(
      width: 240,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: context
            .colors.channelSidebarBackground,
        border: Border(
          right: BorderSide(
            color: context.colors.borderColor,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildServerHeader(
            context,
            ref,
            serverName,
          ),
          Expanded(
            child: _buildChannelList(
              context,
              ref,
              categories,
              selectedId,
              collapsed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerHeader(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) =>
      Material(
        color: context
            .colors.channelSidebarBackground,
        child: InkWell(
          onTap: () {
            final serverId = ref
                .read(serverListViewModelProvider)
                .selectedServerId;
            if (serverId != null) {
              context.go(
                '/settings/server/$serverId',
              );
            }
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colors.borderColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: context
                        .textStyles.channelName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PhosphorIcon(
                  PhosphorIconsFill.caretDown,
                  color: context.colors.textChat,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildChannelList(
    BuildContext context,
    WidgetRef ref,
    List<ChannelCategory> categories,
    String? selectedId,
    Set<String> collapsed,
  ) =>
      ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isCollapsed =
              collapsed.contains(category.id);
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(
                context,
                ref,
                category,
                isCollapsed,
              ),
              if (!isCollapsed)
                ...category.channels.map(
                  (channel) => _buildChannelTile(
                    context,
                    ref,
                    channel,
                    channel.id == selectedId,
                  ),
                ),
            ],
          );
        },
      );

  Widget _buildCategoryHeader(
    BuildContext context,
    WidgetRef ref,
    ChannelCategory category,
    bool isCollapsed,
  ) =>
      InkWell(
        onTap: () => ref
            .read(
              channelListViewModelProvider.notifier,
            )
            .toggleCategory(category.id),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 4,
            right: 8,
            top: 16,
            bottom: 4,
          ),
          child: Row(
            children: [
              PhosphorIcon(
                isCollapsed
                    ? PhosphorIconsFill.caretRight
                    : PhosphorIconsFill.caretDown,
                size: 12,
                color: context
                    .colors.textPrimaryMuted,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  category.name,
                  style: context
                      .textStyles.categoryName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PhosphorIcon(
                PhosphorIconsFill.plus,
                size: 16,
                color: context
                    .colors.textPrimaryMuted,
              ),
            ],
          ),
        ),
      );

  Widget _buildChannelTile(
    BuildContext context,
    WidgetRef ref,
    Channel channel,
    bool isSelected,
  ) {
    final unreadAsync =
        ref.watch(channelUnreadProvider(channel.id));
    final unread = unreadAsync.value;
    final hasUnread = unread?.hasUnread ?? false;
    final mentionCount = unread?.mentionCount ?? 0;

    final textColor = isSelected
        ? context.colors.textPrimary
        : hasUnread
            ? context.colors.textChat
            : context.colors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final serverId = ref
              .read(serverListViewModelProvider)
              .selectedServerId;
          ref
              .read(
                channelListViewModelProvider
                    .notifier,
              )
              .selectChannel(channel.id);
          if (serverId != null) {
            navigateToContent(
              context,
              '/servers/$serverId'
              '/channels/${channel.id}',
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
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
              ChannelIcon(
                type: channel.type,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  channel.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: hasUnread
                        ? FontWeight.w600
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isSelected &&
                  (hasUnread || mentionCount > 0))
                UnreadBadge(
                  mentionCount: mentionCount,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
