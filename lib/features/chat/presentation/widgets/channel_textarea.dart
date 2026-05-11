import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/chat/domain/cloud_composer_attachments.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/domain/gif_selection.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel_attachment_area.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/emoji_search_bar.dart'
    show kSkinToneSurrogates, skinToneToName;
import 'package:fluxer_app/features/chat/presentation/widgets/expression_picker.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/reply_preview.dart';
import 'package:fluxer_app/features/chat/providers/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/cloud_upload_controller.dart';
import 'package:fluxer_app/features/chat/providers/expression_panel_provider.dart';
import 'package:fluxer_app/features/chat/providers/slowmode_blocked_provider.dart';
import 'package:fluxer_app/features/chat/providers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/chat/utils/clipboard_attachment_reader.dart';
import 'package:fluxer_app/features/chat/utils/file_upload_constants.dart';
import 'package:fluxer_app/features/chat/utils/file_upload_validator.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _kVoiceMicDeniedOpacity = 0.45;

/// Visual weight for the message field when the user cannot send messages.
const double _kMessageInputDisabledOpacity = 0.55;

const double _kMobileComposerSuffixHorizontalPadding = 7;
const double _kMobileComposerSuffixVerticalPadding = 4;
const double _kMobileComposerSuffixButtonExtent = 32;
const double _kMobileComposerSuffixWidth =
    _kMobileComposerSuffixHorizontalPadding * 2 +
    _kMobileComposerSuffixButtonExtent;
const double _kMobileComposerSuffixHeight =
    _kMobileComposerSuffixVerticalPadding * 2 +
    _kMobileComposerSuffixButtonExtent;

/// The chat input bar at the bottom of the chat area.
class ChannelTextarea extends ConsumerStatefulWidget {
  const ChannelTextarea({super.key});

  @override
  ConsumerState<ChannelTextarea> createState() => _ChannelTextareaState();
}

class _ChannelTextareaState extends ConsumerState<ChannelTextarea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _expressionPickerKey = GlobalKey<FluxerEmojiPickerPopoutState>();
  final _gifPickerKey = GlobalKey<FluxerEmojiPickerPopoutState>();
  final _mediaPickerKey = GlobalKey<FluxerEmojiPickerPopoutState>();
  final _stickerPickerKey = GlobalKey<FluxerEmojiPickerPopoutState>();

  bool get _isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = _handleKeyEvent;
    _controller.addListener(() {
      ref
          .read(chatViewModelProvider.notifier)
          .updateMessageText(_controller.text);
    });
  }

  @override
  void dispose() {
    _focusNode
      ..unfocus()
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Enter sends, Shift+Enter inserts newline.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isDesktop) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed)) {
      unawaited(_pasteClipboardAttachments());
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final channelId = ref.read(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final ChannelMessagePermissions perms =
        channelMessagePermissionsForComposer(
          ref.read(channelMessagePermissionsProvider(channelId)),
        );
    if (!perms.canSendMessages) {
      return KeyEventResult.ignored;
    }
    unawaited(ref.read(chatViewModelProvider.notifier).sendMessage());
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen<String>(
        chatViewModelProvider.select((state) => state.messageText),
        (_, messageText) {
          if (_controller.text == messageText) {
            return;
          }
          _controller.value = TextEditingValue(
            text: messageText,
            selection: TextSelection.collapsed(offset: messageText.length),
          );
        },
      )
      ..listen<({String name, String surrogates})?>(
        pendingEmojiInsertProvider,
        (_, pending) {
          if (pending == null) {
            return;
          }
          ref.read(pendingEmojiInsertProvider.notifier).consume();
          _insertEmoji(pending.name, pending.surrogates);
        },
      )
      ..listen<FluxerSelectedGif?>(pendingGifSelectionProvider, (_, pending) {
        if (pending == null) {
          return;
        }
        ref.read(pendingGifSelectionProvider.notifier).consume();
        _handleGifSelection(pending);
      })
      ..listen<StickerEntry?>(pendingStickerSelectionProvider, (_, pending) {
        if (pending == null) {
          return;
        }
        ref.read(pendingStickerSelectionProvider.notifier).consume();
        _handleStickerSelection(pending);
      })
      ..listen<FavoriteMemeSelection?>(pendingFavoriteMemeSelectionProvider, (
        _,
        pending,
      ) {
        if (pending == null) {
          return;
        }
        ref.read(pendingFavoriteMemeSelectionProvider.notifier).consume();
        _handleFavoriteMemeSelection(pending);
      });

    final vm = ref.watch(chatViewModelProvider);
    final chatNotifier = ref.read(chatViewModelProvider.notifier);
    final replyTo = vm.replyingTo;
    final forwardFrom = vm.forwardingFrom;
    final editingMessage = vm.editingMessage;
    final channelId = ref.watch(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final ChannelMessagePermissions perms =
        channelMessagePermissionsForComposer(
          ref.watch(channelMessagePermissionsProvider(channelId)),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyTo != null)
          ReplyInputBar(replyTo: replyTo, onCancel: chatNotifier.cancelReply),
        if (forwardFrom != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: context.colors.chatInputBackground,
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsFill.shareFat,
                  size: 16,
                  color: context.colors.textPrimaryMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Forwarding message from '
                    '${forwardFrom.authorName}',
                    style: TextStyle(
                      color: context.colors.textPrimaryMuted,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsFill.x, size: 16),
                  color: context.colors.textPrimaryMuted,
                  onPressed: chatNotifier.cancelForward,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
        if (editingMessage != null)
          EditingInputBar(onCancel: chatNotifier.cancelEdit),
        ChannelAttachmentArea(channelId: channelId),
        Container(
          decoration: BoxDecoration(
            color: context.colors.chatInputBackground,
            border: Border(
              top: BorderSide(color: context.colors.userAreaDividerColor),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ResponsiveLayout(
            builder: (context, mode) {
              switch (mode) {
                case LayoutMode.desktop:
                  return _buildLargeLayout(context, chatNotifier, perms);
                case LayoutMode.tablet:
                  return _buildLargeLayout(context, chatNotifier, perms);
                case LayoutMode.mobile:
                  return _buildMobileLayout(context, chatNotifier, perms);
              }
            },
          ),
        ),
        Container(
          height: MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(color: context.colors.chatInputBackground),
        ),
      ],
    );
  }

  String _resolveHintText() {
    final bool isEditing = ref.read(
      chatViewModelProvider.select((s) => s.editingMessage != null),
    );
    if (isEditing) {
      return FluxerLocalizations.of(context).chatEditMessageHint;
    }
    final channelId = ref.read(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final channelState = ref.read(channelListViewModelProvider);
    final channel = findChannelById(channelState, channelId);
    if (channel != null) {
      return 'Message #${channel.name}';
    }
    final conversations = ref.read(
      dmViewModelProvider.select((s) => s.conversations),
    );
    final dm = findDmById(conversations, channelId);
    if (dm != null) {
      return 'Message @${dm.recipientName}';
    }
    return 'Message';
  }

  Widget _buildLargeLayout(
    BuildContext context,
    ChatViewModel chatNotifier,
    ChannelMessagePermissions perms,
  ) {
    final String channelId = ref.watch(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final bool hasMessageText = ref.watch(
      chatViewModelProvider.select((s) => s.messageText.isNotEmpty),
    );
    final bool hasPendingUploads = ref.watch(
      cloudUploadControllerProvider(
        channelId,
      ).select((CloudComposerAttachments a) => a.items.isNotEmpty),
    );
    final bool hasText = hasMessageText || hasPendingUploads;
    return Row(
      children: [
        if (perms.canAttachFiles) ...[
          FluxerButton.secondary(
            icon: PhosphorIconsFill.plusCircle,
            isSquare: true,
            size: FluxerButtonSize.compact,
            onPressed: perms.canSendMessages
                ? () => unawaited(_pickAttachments(context))
                : null,
          ),
          if (_isDesktop) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsFill.clipboard, size: 22),
              color: context.colors.interactiveNormal,
              tooltip: FluxerLocalizations.of(
                context,
              ).chatAttachmentPasteTooltip,
              onPressed: perms.canSendMessages
                  ? () => unawaited(_pasteClipboardAttachments())
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Opacity(
            opacity: perms.canSendMessages
                ? 1.0
                : _kMessageInputDisabledOpacity,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: perms.canSendMessages,
              style: context.textStyles.inputText,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: perms.canSendMessages
                    ? _resolveHintText()
                    : FluxerLocalizations.of(
                        context,
                      ).channelNoSendPermissionHint,
                hintMaxLines: 1,
                hintStyle: TextStyle(
                  color: context.colors.textTertiaryMuted,
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                ),
                filled: true,
                fillColor: context.colors.backgroundTertiary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        if (!hasText) ...[
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.gift, size: 24),
            color: context.colors.interactiveNormal,
            onPressed: perms.canSendMessages ? () {} : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          if (perms.canEmbedLinks)
            FluxerEmojiPickerPopout(
              key: _gifPickerKey,
              initialTab: ExpressionPickerTab.gifs,
              channelId: channelId,
              onEmojiSelected: (emoji) =>
                  _insertEmoji(emoji.name, emoji.surrogates),
              onGifSelected: _handleGifSelection,
              onStickerSelected: (sticker) {
                _handleStickerSelection(sticker);
                _gifPickerKey.currentState?.close();
              },
              onFavoriteMemeSelected: (selection) {
                _handleFavoriteMemeSelection(selection);
                if (selection.autoSend) {
                  _gifPickerKey.currentState?.close();
                }
              },
              child: IconButton(
                icon: const PhosphorIcon(PhosphorIconsFill.gif, size: 24),
                color: context.colors.interactiveNormal,
                onPressed: perms.canSendMessages
                    ? () => _gifPickerKey.currentState?.toggle()
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          if (perms.canAttachFiles)
            FluxerEmojiPickerPopout(
              key: _mediaPickerKey,
              initialTab: ExpressionPickerTab.memes,
              channelId: channelId,
              onEmojiSelected: (emoji) =>
                  _insertEmoji(emoji.name, emoji.surrogates),
              onGifSelected: _handleGifSelection,
              onStickerSelected: (sticker) {
                _handleStickerSelection(sticker);
                _mediaPickerKey.currentState?.close();
              },
              onFavoriteMemeSelected: (selection) {
                _handleFavoriteMemeSelection(selection);
                if (selection.autoSend) {
                  _mediaPickerKey.currentState?.close();
                }
              },
              child: IconButton(
                icon: const PhosphorIcon(PhosphorIconsFill.image, size: 24),
                color: context.colors.interactiveNormal,
                onPressed: perms.canSendMessages
                    ? () => _mediaPickerKey.currentState?.toggle()
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          FluxerEmojiPickerPopout(
            key: _stickerPickerKey,
            initialTab: ExpressionPickerTab.stickers,
            channelId: channelId,
            onEmojiSelected: (emoji) =>
                _insertEmoji(emoji.name, emoji.surrogates),
            onGifSelected: _handleGifSelection,
            onStickerSelected: (sticker) {
              _handleStickerSelection(sticker);
              _stickerPickerKey.currentState?.close();
            },
            onFavoriteMemeSelected: (selection) {
              _handleFavoriteMemeSelection(selection);
              if (selection.autoSend) {
                _stickerPickerKey.currentState?.close();
              }
            },
            child: IconButton(
              icon: const PhosphorIcon(PhosphorIconsFill.sticker, size: 24),
              color: context.colors.interactiveNormal,
              onPressed: perms.canSendMessages
                  ? () => _stickerPickerKey.currentState?.toggle()
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          FluxerEmojiPickerPopout(
            key: _expressionPickerKey,
            channelId: channelId,
            onEmojiSelected: (emoji) =>
                _insertEmoji(emoji.name, emoji.surrogates),
            onGifSelected: _handleGifSelection,
            onStickerSelected: (sticker) {
              _handleStickerSelection(sticker);
              _expressionPickerKey.currentState?.close();
            },
            onFavoriteMemeSelected: (selection) {
              _handleFavoriteMemeSelection(selection);
              if (selection.autoSend) {
                _expressionPickerKey.currentState?.close();
              }
            },
            child: IconButton(
              icon: const PhosphorIcon(PhosphorIconsFill.smiley, size: 24),
              color: context.colors.interactiveNormal,
              onPressed: perms.canSendMessages
                  ? () => _expressionPickerKey.currentState?.toggle()
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
        SizedBox(
          height: 24,
          child: VerticalDivider(
            color: context.colors.borderColor,
            width: 16,
            thickness: 1,
          ),
        ),
        _sendAndVoiceButton(
          context,
          chatNotifier,
          perms: perms,
          hasText: hasText,
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ChatViewModel chatNotifier,
    ChannelMessagePermissions perms,
  ) {
    final String channelId = ref.watch(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final bool hasMessageText = ref.watch(
      chatViewModelProvider.select((s) => s.messageText.isNotEmpty),
    );
    final bool hasPendingUploads = ref.watch(
      cloudUploadControllerProvider(
        channelId,
      ).select((CloudComposerAttachments a) => a.items.isNotEmpty),
    );
    final bool hasText = hasMessageText || hasPendingUploads;

    return Row(
      children: [
        if (perms.canAttachFiles) ...[
          FluxerButton.circle(
            icon: PhosphorIconsBold.plus,
            variant: FluxerButtonVariant.secondary,
            size: FluxerButtonSize.small,
            iconSize: 20,
            onPressed: perms.canSendMessages
                ? () => unawaited(_pickAttachments(context))
                : null,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Opacity(
            opacity: perms.canSendMessages
                ? 1.0
                : _kMessageInputDisabledOpacity,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: perms.canSendMessages,
              style: context.textStyles.inputText,
              minLines: 1,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: perms.canSendMessages
                    ? _resolveHintText()
                    : FluxerLocalizations.of(
                        context,
                      ).channelNoSendPermissionHint,
                hintMaxLines: 1,
                hintStyle: TextStyle(
                  color: context.colors.textTertiaryMuted,
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                ),
                filled: true,
                fillColor: context.colors.backgroundTertiary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                suffixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: _kMobileComposerSuffixVerticalPadding,
                    horizontal: _kMobileComposerSuffixHorizontalPadding,
                  ),
                  child: _buildMobilePickerButton(context, perms),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: _kMobileComposerSuffixWidth,
                  maxWidth: _kMobileComposerSuffixWidth,
                  minHeight: _kMobileComposerSuffixHeight,
                  maxHeight: _kMobileComposerSuffixHeight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsetsGeometry.only(bottom: 1),
          child: _sendAndVoiceButton(
            context,
            chatNotifier,
            perms: perms,
            hasText: hasText,
            size: FluxerButtonSize.small,
          ),
        ),
      ],
    );
  }

  void _handleGifSelection(FluxerSelectedGif selection) {
    if (selection.autoSend) {
      unawaited(
        ref
            .read(chatViewModelProvider.notifier)
            .sendStandaloneMessage(selection.url),
      );
      return;
    }

    _insertGifUrl(selection.url);
    _focusNode.requestFocus();
  }

  void _handleStickerSelection(StickerEntry sticker) {
    unawaited(
      ref.read(chatViewModelProvider.notifier).sendStickerMessage(sticker),
    );
    ref.read(expressionPanelProvider.notifier).close();
    _focusNode.requestFocus();
  }

  void _handleFavoriteMemeSelection(FavoriteMemeSelection selection) {
    unawaited(_processFavoriteMemeSelection(selection));
  }

  Future<void> _processFavoriteMemeSelection(
    FavoriteMemeSelection selection,
  ) async {
    final meme = selection.meme;
    if (!selection.autoSend) {
      _insertGifUrl(meme.shareUrl);
      _focusNode.requestFocus();
      return;
    }

    final perms = await _currentPermissions();
    if (_hasProviderShareUrl(meme)) {
      await ref
          .read(chatViewModelProvider.notifier)
          .sendStandaloneMessage(meme.shareUrl);
    } else if (perms.canAttachFiles && perms.canEmbedLinks) {
      await ref
          .read(chatViewModelProvider.notifier)
          .sendFavoriteMemeMessage(meme);
    } else {
      _insertGifUrl(meme.url);
    }

    ref.read(expressionPanelProvider.notifier).close();
    _focusNode.requestFocus();
  }

  bool _hasProviderShareUrl(FavoriteMeme meme) =>
      (meme.klipySlug?.trim().isNotEmpty ?? false) ||
      (meme.tenorSlugId?.trim().isNotEmpty ?? false);

  Future<ChannelMessagePermissions> _currentPermissions() async {
    final channelId = ref.read(
      chatViewModelProvider.select((state) => state.channelId),
    );
    return channelMessagePermissionsForComposer(
      ref.read(channelMessagePermissionsProvider(channelId)),
    );
  }

  void _insertGifUrl(String url) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid
        ? _clampOffset(selection.start, text.length)
        : text.length;
    final end = selection.isValid
        ? _clampOffset(selection.end, text.length)
        : text.length;
    final selectionStart = start < end ? start : end;
    final selectionEnd = start < end ? end : start;
    final needsLeadingSpace =
        selectionStart > 0 &&
        !_isWhitespace(text.substring(selectionStart - 1, selectionStart));
    final needsTrailingSpace =
        selectionEnd >= text.length ||
        !_isWhitespace(text.substring(selectionEnd, selectionEnd + 1));
    final insertText =
        '${needsLeadingSpace ? ' ' : ''}$url'
        '${needsTrailingSpace ? ' ' : ''}';
    final newText = text.replaceRange(selectionStart, selectionEnd, insertText);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selectionStart + insertText.length,
      ),
    );
  }

  bool _isWhitespace(String text) => text.trim().isEmpty;

  int _clampOffset(int value, int max) {
    if (value < 0) {
      return 0;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  void _insertEmoji(String name, String surrogates) {
    final String token;
    if (surrogates.startsWith('<')) {
      token = surrogates;
    } else {
      token = _buildUnicodeShortcode(name, surrogates);
    }
    final text = _controller.text;
    final sel = _controller.selection;
    final pos = sel.isValid ? sel.baseOffset : text.length;
    final newText = text.substring(0, pos) + token + text.substring(pos);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + token.length),
    );
  }

  String _buildUnicodeShortcode(String name, String surrogates) {
    for (final tone in kSkinToneSurrogates) {
      if (surrogates.contains(tone)) {
        final toneName = skinToneToName(tone);
        if (toneName != null) {
          return ':$name::$toneName:';
        }
        break;
      }
    }
    return ':$name:';
  }

  Widget _buildMobilePickerButton(
    BuildContext context,
    ChannelMessagePermissions perms,
  ) {
    final isPanelOpen = ref.watch(expressionPanelProvider);

    return FluxerButton.ghost(
      icon: isPanelOpen ? PhosphorIconsFill.keyboard : PhosphorIconsFill.smiley,
      isSquare: true,
      size: FluxerButtonSize.compact,
      onPressed: !perms.canSendMessages
          ? null
          : () {
              if (isPanelOpen) {
                ref.read(expressionPanelProvider.notifier).close();
                _focusNode.requestFocus();
              } else {
                FocusScope.of(context).unfocus();
                ref.read(expressionPanelProvider.notifier).open();
              }
            },
    );
  }

  Widget _sendAndVoiceButton(
    BuildContext context,
    ChatViewModel chatNotifier, {
    required ChannelMessagePermissions perms,
    required bool hasText,
    FluxerButtonSize size = FluxerButtonSize.compact,
  }) {
    final channelId = ref.watch(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final isBlocked =
        ref.watch(isSlowmodeBlockedProvider(channelId)).value ?? false;
    final canPressSend = perms.canSendMessages && !isBlocked;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: hasText
          ? FluxerButton.circle(
              key: const ValueKey('send'),
              icon: PhosphorIconsBold.arrowUp,
              iconSize: 20,
              size: size,
              onPressed: canPressSend ? chatNotifier.sendMessage : null,
            )
          : Opacity(
              key: const ValueKey('voice'),
              opacity: perms.canSendMessages ? 1.0 : _kVoiceMicDeniedOpacity,
              child: FluxerButton.circle(
                icon: PhosphorIconsFill.microphone,
                variant: FluxerButtonVariant.secondary,
                iconSize: 20,
                size: size,
                onPressed: perms.canSendMessages ? () {} : null,
              ),
            ),
    );
  }

  Future<void> _pickAttachments(BuildContext context) async {
    final String channelId = ref.read(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final CloudUploadController notifier = ref.read(
      cloudUploadControllerProvider(channelId).notifier,
    );
    if (isMobileLayout(context)) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext sheetContext) {
          final FluxerLocalizations l10n = FluxerLocalizations.of(sheetContext);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.chatAttachmentSourceGallery),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final ImagePicker picker = ImagePicker();
                    final List<XFile> media = await picker.pickMultipleMedia(
                      limit: kMaxAttachmentsPerMessage,
                    );
                    if (media.isEmpty) {
                      return;
                    }
                    if (!mounted) {
                      return;
                    }
                    final FileUploadValidationResult r =
                        await notifier.addFiles(media);
                    if (mounted) {
                      _toastUploadValidation(r);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.chatAttachmentSourceCamera),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image == null) {
                      return;
                    }
                    if (!mounted) {
                      return;
                    }
                    final FileUploadValidationResult r = await notifier
                        .addFiles(<XFile>[image]);
                    if (mounted) {
                      _toastUploadValidation(r);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(l10n.chatAttachmentSourceBrowse),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final FilePickerResult? res = await FilePicker.pickFiles(
                      allowMultiple: true,
                    );
                    if (res == null) {
                      return;
                    }
                    if (!mounted) {
                      return;
                    }
                    final List<XFile> files = <XFile>[];
                    for (final PlatformFile p in res.files) {
                      if (p.path != null && p.path!.isNotEmpty) {
                        files.add(XFile(p.path!, name: p.name));
                      }
                    }
                    if (files.isEmpty) {
                      return;
                    }
                    final FileUploadValidationResult r = await notifier
                        .addFiles(files);
                    if (mounted) {
                      _toastUploadValidation(r);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
      return;
    }
    final FilePickerResult? res = await FilePicker.pickFiles(
      allowMultiple: true,
    );
    if (res == null || !mounted) {
      return;
    }
    final List<XFile> files = <XFile>[];
    for (final PlatformFile p in res.files) {
      if (p.path != null && p.path!.isNotEmpty) {
        files.add(XFile(p.path!, name: p.name));
      }
    }
    if (files.isEmpty) {
      return;
    }
    final FileUploadValidationResult r = await notifier.addFiles(files);
    if (mounted) {
      _toastUploadValidation(r);
    }
  }

  void _toastUploadValidation(FileUploadValidationResult result) {
    if (result.isValid || !mounted) {
      return;
    }
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String msg = switch (result.error!) {
      FileUploadValidationError.tooManyAttachments =>
        l10n.chatAttachmentTooMany(kMaxAttachmentsPerMessage),
      FileUploadValidationError.fileTooLarge => l10n.chatAttachmentFileTooLarge,
      FileUploadValidationError.multipartRequestTooLarge =>
        l10n.chatAttachmentPayloadTooLarge,
      FileUploadValidationError.noFiles => '',
    };
    if (msg.isEmpty) {
      return;
    }
    ref
        .read(toastProvider.notifier)
        .show(FluxerToast(message: msg, variant: FluxerToastVariant.warning));
  }

  Future<void> _pasteClipboardAttachments() async {
    final List<XFile> files = await readClipboardImageFiles();
    if (files.isEmpty) {
      return;
    }
    final String channelId = ref.read(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final FileUploadValidationResult r = await ref
        .read(cloudUploadControllerProvider(channelId).notifier)
        .addFiles(files);
    if (mounted) {
      _toastUploadValidation(r);
    }
  }
}
