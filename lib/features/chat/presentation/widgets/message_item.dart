import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_list_renderer.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/embeds/embed_image.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/embeds/embed_invite.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/embeds/embed_link.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/embeds/embed_rich.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/embeds/embed_theme.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/embeds/embed_video.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/expression_picker.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/forward_indicator.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/forwarded_message_content.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/message_bottom_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/message_context_menu.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_markdown.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/reply_preview.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/spoiler_overlay.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/swipe_to_reply.dart';
import 'package:fluxer_app/features/chat/providers/spoiler_reveal_provider.dart';
import 'package:fluxer_app/features/chat/utils/spoiler_utils.dart';
import 'package:fluxer_app/features/chat/utils/uploading_attachment_utils.dart';
import 'package:fluxer_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/providers/guild_user_display_provider.dart';
import 'package:fluxer_app/shared/providers/member_role_color.dart';
import 'package:fluxer_app/shared/utils/emoji_utils.dart';
import 'package:fluxer_app/shared/utils/guild_user_display.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Mention highlight color matching web app's
/// `--message-mention-color: rgb(234 197 50)`.
const _kMentionColor = Color.from(
  alpha: 1,
  red: 234 / 255,
  green: 197 / 255,
  blue: 50 / 255,
);

/// Avatar column width: 40px avatar + 16px gap to the
/// right.
const _kAvatarColumnWidth = 56.0;

/// Height of the compact reply-preview row.
const _kReplyRowHeight = 20.0;

/// Gap between the reply-preview row and the main message
/// row (avatar).
const _kReplyBottomGap = 4.0;

/// Horizontal gap between the end of the connector line
/// and the reply content.
const _kReplyLineEndGap = 6.0;

const _kMessageStickerSize = 160.0;
const _kMessageStickerRequestSize = 320;
const _kReactionEmojiSize = 16.0;
const double _kMessageSendingOpacity = 0.5;

/// A single message row -- avatar, username, timestamp,
/// content, embeds, reactions, and action buttons on hover.
///
/// When the message is a reply, a compact preview of the
/// replied-to message is rendered above, with a curved
/// connector line from the replier's avatar to the reply
/// preview (matching Discord's layout).
class MessageItem extends ConsumerStatefulWidget {
  final Message message;
  final bool isGrouped;
  final String? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canDelete;
  final VoidCallback? onRetry;
  final VoidCallback? onDeleteFailed;
  final VoidCallback? onMarkAsUnread;
  final void Function(String emoji, {String? emojiId, bool animated})?
  onReaction;
  final bool inboxPreviewMode;
  final bool hideMentionHighlight;

  /// When set, resolves author guild role highlight for inbox previews
  /// (active guild sheet may differ from the channel's guild).
  final String? previewRoleGuildId;

  const MessageItem({
    required this.message,
    this.isGrouped = false,
    this.currentUserId,
    this.onReply,
    this.onForward,
    this.onEdit,
    this.onDelete,
    this.canDelete = false,
    this.onRetry,
    this.onDeleteFailed,
    this.onMarkAsUnread,
    this.onReaction,
    this.inboxPreviewMode = false,
    this.hideMentionHighlight = false,
    this.previewRoleGuildId,
    super.key,
  });

  @override
  ConsumerState<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends ConsumerState<MessageItem> {
  var _isHovered = false;
  final _reactionPickerKey = GlobalKey<FluxerEmojiPickerPopoutState>();
  final _spoilerSyncController = FluxerSpoilerSyncController();
  var _isReactionPickerOpen = false;

  @override
  void dispose() {
    _spoilerSyncController.dispose();
    super.dispose();
  }

  void _addReactionFromPicker(FluxerSelectedEmoji emoji) {
    if (emoji.isCustom) {
      widget.onReaction?.call(
        emoji.name,
        emojiId: emoji.emojiId,
        animated: emoji.animated,
      );
      return;
    }

    widget.onReaction?.call(emoji.surrogates);
  }

  bool _canOpenAuthorProfile(Message msg) {
    if (widget.inboxPreviewMode || msg.isSystemMessage) {
      return false;
    }
    return msg.authorId.isNotEmpty;
  }

  void _openAuthorProfile(BuildContext context, Message msg) {
    if (!_canOpenAuthorProfile(msg)) {
      return;
    }
    final String? guildId =
        widget.previewRoleGuildId ?? ref.read(activeGuildIdProvider);
    unawaited(
      FluxerUserProfileSheet.show(
        context,
        userId: msg.authorId,
        guildId: guildId,
      ),
    );
  }

  void _handleAction(MessageAction? action, {required bool isMobile}) {
    switch (action) {
      case MessageAction.reply:
        widget.onReply?.call();
      case MessageAction.forward:
        widget.onForward?.call();
      case MessageAction.edit:
        widget.onEdit?.call();
      case MessageAction.delete:
        widget.onDelete?.call();
      case MessageAction.retry:
        widget.onRetry?.call();
      case MessageAction.deleteFailed:
        widget.onDeleteFailed?.call();
      case MessageAction.copyText:
      case MessageAction.copyMessageId:
        break;
      case MessageAction.addReaction:
        if (isMobile) {
          unawaited(
            FluxerEmojiPickerSheet.show(
              context,
              maxHeight: 0.88,
              onEmojiSelected: _addReactionFromPicker,
              visibleTabs: const [ExpressionPickerTab.emojis],
            ),
          );
        } else {
          setState(() {
            _isHovered = true;
            _isReactionPickerOpen = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            if (!(_reactionPickerKey.currentState?.isOpen ?? false)) {
              _reactionPickerKey.currentState?.toggle();
            }
          });
        }
      case MessageAction.pin:
      case MessageAction.bookmark:
      case MessageAction.copyMessageLink:
      case null:
        break;
      case MessageAction.markAsUnread:
        widget.onMarkAsUnread?.call();
    }
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showMessageBottomSheet(
      context,
      message: widget.message,
      isOwnMessage: widget.message.authorId == widget.currentUserId,
      canDelete: widget.canDelete,
    );
    if (!context.mounted) {
      return;
    }
    _handleAction(action, isMobile: true);
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    List<String>? frecent;
    try {
      final db = ProviderScope.containerOf(
        context,
      ).read(fluxerDatabaseProvider);
      frecent = await db.emojiUsageDao.getQuickReactionEmojis(4, const [
        '\u{1F44D}',
        '\u{1F44C}',
        '\u{1F389}',
        '\u{2764}\u{FE0F}',
      ]);
    } on Object {
      // Fall back to defaults.
    }

    if (!context.mounted) {
      return;
    }

    final action = await showMessageContextMenu(
      context,
      position: position,
      message: widget.message,
      isOwnMessage: widget.message.authorId == widget.currentUserId,
      canDelete: widget.canDelete,
      onQuickReaction: (emoji) => widget.onReaction?.call(emoji),
      quickEmojis: frecent,
    );
    if (!context.mounted) {
      return;
    }
    _handleAction(action, isMobile: false);
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isGrouped = widget.isGrouped;
    final isMobile = isMobileLayout(context);
    final isTouch =
        layoutModeOf(layoutReferenceExtentOf(MediaQuery.sizeOf(context))) !=
        LayoutMode.desktop;
    final guildId =
        widget.previewRoleGuildId ?? ref.watch(activeGuildIdProvider);
    final renderEmbeds = ref.watch(
      userSettingsViewModelProvider.select((s) => s.renderEmbeds),
    );
    final renderReactions = ref.watch(
      userSettingsViewModelProvider.select((s) => s.renderReactions),
    );
    final inlineAttachmentMedia = ref.watch(
      userSettingsViewModelProvider.select((s) => s.inlineAttachmentMedia),
    );
    final renderSpoilers = ref.watch(
      userSettingsViewModelProvider.select((s) => s.renderSpoilers),
    );
    final revealSpoilers = switch (renderSpoilers) {
      RenderSpoilers.always => true,
      RenderSpoilers.ifModerator =>
        ref.watch(spoilerAutoRevealProvider(msg.channelId)).value ?? false,
      RenderSpoilers.onClick || RenderSpoilers.$unknown => false,
    };
    final chatPreferences = ref.watch(chatPreferencesProvider);
    Color? authorRoleColor;
    if (guildId != null) {
      authorRoleColor = ref
          .watch(memberRoleColorProvider((msg.authorId, guildId)))
          .value;
    }
    final GuildUserDisplay fallbackAuthorDisplay =
        resolveGuildUserDisplayFromMessage(
          userId: msg.authorId,
          fallbackDisplayName: msg.authorName,
          fallbackAvatarHash: msg.authorAvatar,
          fallbackAvatarColor: msg.authorAvatarColor,
          member: null,
          guildId: null,
          animatedAvatar: false,
        );
    final GuildUserDisplay authorDisplay = guildId == null
        ? fallbackAuthorDisplay
        : ref.watch(guildUserDisplayProvider((msg.authorId, guildId))).value ??
              fallbackAuthorDisplay;
    final bool shouldHighlightMention =
        msg.isMentioned && !widget.hideMentionHighlight;
    final bool isFailed = msg.hasFailed;
    final bool isSending = msg.isSending;
    final bool hasUploadingPlaceholderAttachments =
        _hasUploadingPlaceholderAttachments(msg);
    final bool dimEntireMessage =
        isSending && !hasUploadingPlaceholderAttachments;
    final bool dimMessagePartsExceptAttachments =
        isSending && hasUploadingPlaceholderAttachments;

    final body = GestureDetector(
      onLongPress: isMobile && !widget.inboxPreviewMode
          ? () => _showActions(context)
          : null,
      onSecondaryTapUp: !isMobile && !widget.inboxPreviewMode
          ? (details) => _showContextMenu(context, details.globalPosition)
          : null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) {
          if (!_isReactionPickerOpen) {
            setState(() => _isHovered = false);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: shouldHighlightMention
                ? _kMentionColor.withValues(alpha: _isHovered ? 0.14 : 0.1)
                : _isHovered
                ? context.colors.backgroundModifierHover
                : Colors.transparent,
            border: shouldHighlightMention
                ? const Border(
                    left: BorderSide(color: _kMentionColor, width: 2),
                  )
                : null,
          ),
          padding: widget.inboxPreviewMode
              ? EdgeInsets.only(
                  left: shouldHighlightMention ? 7 : 8,
                  right: 8,
                  top: isGrouped ? 2 : 8,
                  bottom: isGrouped ? 2 : 8,
                )
              : EdgeInsets.only(
                  left: shouldHighlightMention ? 14 : 16,
                  right: 16,
                  top: isGrouped ? 2 : 8,
                  bottom: isGrouped ? 2 : 8,
                ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isGrouped && msg.isReply)
                    _wrapMessageSendingDim(
                      dim: dimMessagePartsExceptAttachments,
                      child: _buildReplyRow(msg),
                    ),
                  if (!isGrouped &&
                      msg.isForwarded &&
                      !msg.hasForwardSnapshots &&
                      msg.forwardedFrom != null)
                    _wrapMessageSendingDim(
                      dim: dimMessagePartsExceptAttachments,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: _kAvatarColumnWidth,
                        ),
                        child: ForwardIndicator(source: msg.forwardedFrom!),
                      ),
                    ),
                  if (isGrouped)
                    _buildGroupedRow(
                      context,
                      msg,
                      isMobile,
                      dimMessagePartsExceptAttachments:
                          dimMessagePartsExceptAttachments,
                      renderEmbeds: renderEmbeds,
                      renderReactions: renderReactions,
                      inlineAttachmentMedia: inlineAttachmentMedia,
                      revealSpoilers: revealSpoilers,
                      chatPreferences: chatPreferences,
                    )
                  else
                    _buildMainRow(
                      context,
                      msg,
                      authorDisplay,
                      authorRoleColor,
                      isMobile,
                      dimMessagePartsExceptAttachments:
                          dimMessagePartsExceptAttachments,
                      renderEmbeds: renderEmbeds,
                      renderReactions: renderReactions,
                      inlineAttachmentMedia: inlineAttachmentMedia,
                      revealSpoilers: revealSpoilers,
                      chatPreferences: chatPreferences,
                    ),
                ],
              ),
              if ((_isHovered || _isReactionPickerOpen) &&
                  !isMobile &&
                  !isFailed &&
                  !widget.inboxPreviewMode)
                Positioned(top: 0, right: 0, child: _buildActions(context)),
            ],
          ),
        ),
      ),
    );
    final onReply = widget.onReply;
    if (!isTouch || onReply == null || widget.inboxPreviewMode) {
      return _wrapMessageSendingDim(dim: dimEntireMessage, child: body);
    }
    return _wrapMessageSendingDim(
      dim: dimEntireMessage,
      child: SwipeToReply(onReply: onReply, child: body),
    );
  }

  bool _hasUploadingPlaceholderAttachments(Message msg) {
    return msg.attachments.any(isUploadingPlaceholderAttachment);
  }

  Widget _wrapMessageSendingDim({required bool dim, required Widget child}) {
    if (!dim) {
      return child;
    }
    return Opacity(opacity: _kMessageSendingOpacity, child: child);
  }

  /// Builds the reply preview row with space for the
  /// connector line.
  Widget _buildReplyRow(Message msg) {
    const replyAreaHeight = _kReplyRowHeight + _kReplyBottomGap;
    const avatarCenterX = 20.0;
    const lineTop = _kReplyRowHeight / 2;
    const lineBottom = replyAreaHeight - 5;
    const horizontalEnd = _kAvatarColumnWidth - 5;
    const replyContentLeft = horizontalEnd + _kReplyLineEndGap;

    return SizedBox(
      height: replyAreaHeight,
      child: CustomPaint(
        painter: ReplyConnectorPainter(
          avatarCenterX: avatarCenterX,
          lineTop: lineTop,
          lineBottom: lineBottom,
          horizontalEnd: horizontalEnd,
          color: context.colors.interactiveMuted,
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: replyContentLeft,
            bottom: _kReplyBottomGap,
          ),
          child: SizedBox(
            height: _kReplyRowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InlineReplyPreview(replyToId: msg.replyToId!),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the content, embeds, and reactions
  /// widgets for a message.
  List<Widget> _buildMessageContent(
    BuildContext context,
    Message msg,
    bool isMobile, {
    required bool dimMessagePartsExceptAttachments,
    required bool renderEmbeds,
    required bool renderReactions,
    required bool inlineAttachmentMedia,
    required bool revealSpoilers,
    required ChatPreferencesState chatPreferences,
  }) {
    Widget wrapPart(Widget child) => _wrapMessageSendingDim(
      dim: dimMessagePartsExceptAttachments,
      child: child,
    );
    final spoileredUrls = extractSpoileredUrls(msg.content);
    final attachmentSize = msg.hasCompactAttachments
        ? MediaDimensionSize.small
        : chatPreferences.attachmentMediaDimensionSize;

    return [
      if (msg.content.isNotEmpty &&
          !msg.shouldHideContent(renderEmbeds: renderEmbeds))
        wrapPart(
          _buildMessageTextWithEditedTag(
            context,
            msg,
            isMobile: isMobile,
            revealSpoilers: revealSpoilers,
          ),
        ),
      if (msg.hasForwardSnapshots)
        wrapPart(
          ForwardedMessageContent(
            message: msg,
            snapshot: msg.messageSnapshots.first,
            renderEmbeds: renderEmbeds,
            inlineAttachmentMedia: inlineAttachmentMedia,
            revealSpoilers: revealSpoilers,
            chatPreferences: chatPreferences,
            spoilerSyncController: _spoilerSyncController,
          ),
        ),
      ...msg.invites.map(
        (code) => wrapPart(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: EmbedInvite(code: code),
          ),
        ),
      ),
      ...msg.themes.map(
        (_) => wrapPart(
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: EmbedTheme(),
          ),
        ),
      ),
      if (renderEmbeds && !msg.suppressEmbeds)
        ...msg.embeds.map((embed) {
          final spoilerSyncKeys = spoilerSyncKeysForEmbed(embed, spoileredUrls);
          return wrapPart(
            _buildEmbed(
              embed,
              isSpoiler: spoilerSyncKeys.isNotEmpty,
              spoilerSyncKeys: spoilerSyncKeys,
              revealSpoilers: revealSpoilers,
              dimensionSize: chatPreferences.embedMediaDimensionSize,
            ),
          );
        }),
      if (msg.attachments.isNotEmpty)
        AttachmentListRenderer(
          attachments: msg.attachments,
          inlineAttachmentMedia: inlineAttachmentMedia,
          dimensionSize: attachmentSize,
          revealSpoilers: revealSpoilers,
          messageId: msg.id,
          messageNonce: msg.clientNonce,
          channelId: msg.channelId,
        ),
      if (msg.hasStickers)
        wrapPart(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: msg.stickers.map(_buildSticker).toList(),
            ),
          ),
        ),
      if (renderReactions && msg.reactions.isNotEmpty)
        wrapPart(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: msg.reactions
                  .map((r) => _buildReaction(context, r))
                  .toList(),
            ),
          ),
        ),
      if (msg.hasFailed) wrapPart(_buildDeliveryStatus(context, msg)),
    ];
  }

  Widget _buildDeliveryStatus(BuildContext context, Message msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsBold.warningCircle,
                size: 14,
                color: context.colors.textDanger,
              ),
              const SizedBox(width: 4),
              Text(
                FluxerLocalizations.of(context).chatMessageFailedToSend,
                style: TextStyle(
                  color: context.colors.textDanger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTextWithEditedTag(
    BuildContext context,
    Message msg, {
    required bool isMobile,
    required bool revealSpoilers,
  }) {
    final Widget markdown = MessageMarkdown(
      data: msg.content,
      selectable: !isMobile,
      channelId: msg.channelId,
      revealSpoilers: revealSpoilers,
      spoilerSyncController: _spoilerSyncController,
    );
    if (!msg.isEdited) {
      return markdown;
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [markdown, _buildEditedLabel(context, msg)],
    );
  }

  Widget _buildEditedLabel(BuildContext context, Message msg) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    const Widget label = Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Text(' '),
    );
    final Widget editedText = Text(l10n.chatMessageEdited);
    final TextStyle editedTextStyle = context.textStyles.smallText.copyWith(
      color: context.colors.textTertiaryMuted,
      fontSize: 10,
    );
    final DateTime? editedTimestamp = msg.editedTimestamp;
    if (editedTimestamp == null) {
      return DefaultTextStyle(
        style: editedTextStyle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [label, editedText],
        ),
      );
    }
    final DateTime localEditedTimestamp = editedTimestamp.toLocal();
    final MaterialLocalizations materialLocalizations =
        MaterialLocalizations.of(context);
    final TimeOfDay localEditedTime = TimeOfDay.fromDateTime(
      localEditedTimestamp,
    );
    final String editedTooltip =
        '${materialLocalizations.formatFullDate(localEditedTimestamp)} '
        '${materialLocalizations.formatTimeOfDay(localEditedTime)}';
    return Tooltip(
      message: editedTooltip,
      child: DefaultTextStyle(
        style: editedTextStyle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [label, editedText],
        ),
      ),
    );
  }

  /// Grouped message row: hover-reveal short timestamp
  /// in the left column, content on the right.
  Widget _buildGroupedRow(
    BuildContext context,
    Message msg,
    bool isMobile, {
    required bool dimMessagePartsExceptAttachments,
    required bool renderEmbeds,
    required bool renderReactions,
    required bool inlineAttachmentMedia,
    required bool revealSpoilers,
    required ChatPreferencesState chatPreferences,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _wrapMessageSendingDim(
        dim: dimMessagePartsExceptAttachments,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _canOpenAuthorProfile(msg)
              ? () => _openAuthorProfile(context, msg)
              : null,
          child: SizedBox(
            width: _kAvatarColumnWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 100),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatShortTimestamp(msg.timestamp.toLocal()),
                      style: TextStyle(
                        color: context.colors.textTertiaryMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildMessageContent(
            context,
            msg,
            isMobile,
            dimMessagePartsExceptAttachments:
                dimMessagePartsExceptAttachments,
            renderEmbeds: renderEmbeds,
            renderReactions: renderReactions,
            inlineAttachmentMedia: inlineAttachmentMedia,
            revealSpoilers: revealSpoilers,
            chatPreferences: chatPreferences,
          ),
        ),
      ),
    ],
  );

  String _formatShortTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Main message row: avatar on the left, content on
  /// the right.
  Widget _buildMainRow(
    BuildContext context,
    Message msg,
    GuildUserDisplay authorDisplay,
    Color? roleColor,
    bool isMobile, {
    required bool dimMessagePartsExceptAttachments,
    required bool renderEmbeds,
    required bool renderReactions,
    required bool inlineAttachmentMedia,
    required bool revealSpoilers,
    required ChatPreferencesState chatPreferences,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _wrapMessageSendingDim(
        dim: dimMessagePartsExceptAttachments,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _canOpenAuthorProfile(msg)
              ? () => _openAuthorProfile(context, msg)
              : null,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FluxerAvatar.user(
              fallbackText: authorDisplay.displayName,
              userId: msg.authorId,
              imageUrl: authorDisplay.avatarUrl,
              avatarColor: authorDisplay.avatarColor,
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _wrapMessageSendingDim(
              dim: dimMessagePartsExceptAttachments,
              child: Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _canOpenAuthorProfile(msg)
                          ? () => _openAuthorProfile(context, msg)
                          : null,
                      child: Text(
                        authorDisplay.displayName,
                        style: TextStyle(
                          color: roleColor ?? context.colors.textChat,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (msg.authorIsBot) ...[
                    const SizedBox(width: 6),
                    const FluxerBotBadge(),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(msg.timestamp.toLocal()),
                    style: context.textStyles.timestamp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            ..._buildMessageContent(
              context,
              msg,
              isMobile,
              dimMessagePartsExceptAttachments:
                  dimMessagePartsExceptAttachments,
              renderEmbeds: renderEmbeds,
              renderReactions: renderReactions,
              inlineAttachmentMedia: inlineAttachmentMedia,
              revealSpoilers: revealSpoilers,
              chatPreferences: chatPreferences,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildEmbed(
    Embed embed, {
    required bool isSpoiler,
    required List<String> spoilerSyncKeys,
    required bool revealSpoilers,
    required MediaDimensionSize dimensionSize,
  }) {
    final child = switch (embed.type) {
      EmbedType.rich => EmbedRich(
        embed: embed,
        dimensionSize: dimensionSize,
        revealSpoilers: revealSpoilers,
        spoilerSyncController: _spoilerSyncController,
      ),
      EmbedType.image || EmbedType.gifv => EmbedImage(
        embed: embed,
        dimensionSize: dimensionSize,
        isSpoiler: isSpoiler,
        revealSpoiler: revealSpoilers,
        spoilerSyncController: _spoilerSyncController,
        spoilerSyncKeys: spoilerSyncKeys,
      ),
      EmbedType.link => EmbedLink(
        embed: embed,
        dimensionSize: dimensionSize,
        revealSpoilers: revealSpoilers,
        spoilerSyncController: _spoilerSyncController,
      ),
      EmbedType.video => EmbedVideo(embed: embed, dimensionSize: dimensionSize),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: embed.type == EmbedType.image || embed.type == EmbedType.gifv
          ? child
          : SpoilerOverlay(
              isSpoiler: isSpoiler,
              initiallyRevealed: revealSpoilers,
              spoilerSyncController: _spoilerSyncController,
              syncKeys: spoilerSyncKeys,
              child: child,
            ),
    );
  }

  Widget _buildSticker(MessageSticker sticker) => Semantics(
    label: sticker.name,
    image: true,
    child: CachedNetworkImage(
      imageUrl: sticker.urlForSize(_kMessageStickerRequestSize),
      cacheKey: sticker.cacheKeyForSize(_kMessageStickerRequestSize),
      width: _kMessageStickerSize,
      height: _kMessageStickerSize,
      memCacheWidth: _kMessageStickerSize.toInt(),
      memCacheHeight: _kMessageStickerSize.toInt(),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      fit: BoxFit.contain,
      placeholder: (_, _) => const SizedBox(
        width: _kMessageStickerSize,
        height: _kMessageStickerSize,
      ),
      errorBuilder: (_, _, _) => SizedBox(
        width: _kMessageStickerSize,
        height: _kMessageStickerSize,
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsDuotone.sticker,
            size: 48,
            color: context.colors.textTertiaryMuted,
          ),
        ),
      ),
    ),
  );

  Widget _buildReaction(BuildContext context, Reaction reaction) =>
      GestureDetector(
        onTap: () => widget.onReaction?.call(
          reaction.emoji,
          emojiId: reaction.emojiId,
          animated: reaction.animated,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: reaction.hasReacted
                  ? context.colors.brandPrimary.withValues(alpha: 0.3)
                  : context.colors.backgroundSecondaryAlt.withValues(
                      alpha: 0.4,
                    ),
              border: Border.all(
                color: reaction.hasReacted
                    ? context.colors.brandPrimary
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reaction.isCustom)
                  CachedNetworkImage(
                    imageUrl: getCustomEmojiUrl(
                      id: reaction.emojiId!,
                      animated: reaction.animated,
                      size: _kReactionEmojiSize.toInt(),
                    ),
                    cacheKey:
                        'reaction_emoji_'
                        '${reaction.emojiId}_'
                        '${reaction.animated ? 'a' : 's'}_'
                        '${_kReactionEmojiSize.toInt()}',
                    width: _kReactionEmojiSize,
                    height: _kReactionEmojiSize,
                  )
                else
                  Text(reaction.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${reaction.count}',
                  style: TextStyle(
                    color: reaction.hasReacted
                        ? context.colors.brandPrimary
                        : context.colors.textChat,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildActions(BuildContext context) => Material(
    color: context.colors.backgroundPrimary,
    borderRadius: BorderRadius.circular(4),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FluxerEmojiPickerPopout(
            key: _reactionPickerKey,
            closeOnEmojiSelect: true,
            visibleTabs: const [ExpressionPickerTab.emojis],
            onClose: () => setState(() {
              _isReactionPickerOpen = false;
              _isHovered = false;
            }),
            onEmojiSelected: _addReactionFromPicker,
            child: _actionButton(
              context,
              PhosphorIconsFill.smiley,
              FluxerLocalizations.of(context).chatMessageAddReaction,
              () {
                _reactionPickerKey.currentState?.toggle();
                setState(() {
                  _isReactionPickerOpen =
                      _reactionPickerKey.currentState?.isOpen ?? false;
                });
              },
            ),
          ),
          _actionButton(
            context,
            PhosphorIconsFill.arrowBendUpLeft,
            FluxerLocalizations.of(context).chatMessageReply,
            widget.onReply,
          ),
          _actionButton(
            context,
            PhosphorIconsFill.shareFat,
            FluxerLocalizations.of(context).chatMessageForward,
            widget.onForward,
          ),
          _actionButton(
            context,
            PhosphorIconsFill.dotsThree,
            FluxerLocalizations.of(context).chatMessageMore,
            () {},
          ),
        ],
      ),
    ),
  );

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback? onTap,
  ) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: PhosphorIcon(
          icon,
          size: 18,
          color: context.colors.interactiveNormal,
        ),
      ),
    ),
  );

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (isToday) {
      return 'Today at $h:$m';
    }
    return '${dt.month}/${dt.day}/${dt.year}'
        ' $h:$m';
  }
}
