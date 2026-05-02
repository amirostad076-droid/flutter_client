import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/chat/domain/gif_selection.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/emoji_search_bar.dart'
    show kSkinToneSurrogates, skinToneToName;
import 'package:fluxer_app/features/chat/presentation/widgets/expression_picker.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/reply_preview.dart';
import 'package:fluxer_app/features/chat/providers/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/expression_panel_provider.dart';
import 'package:fluxer_app/features/chat/providers/slowmode_blocked_provider.dart';
import 'package:fluxer_app/features/chat/providers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _kVoiceMicDeniedOpacity = 0.45;

/// Visual weight for the message field when the user cannot send messages.
const double _kMessageInputDisabledOpacity = 0.55;

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
    _focusNode.dispose();
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
    if (event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final channelId = ref.read(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final AsyncValue<ChannelMessagePermissions> permsAsync = ref.read(
      channelMessagePermissionsProvider(channelId),
    );
    final ChannelMessagePermissions perms = switch (permsAsync) {
      AsyncData<ChannelMessagePermissions>(:final value) => value,
      _ => ChannelMessagePermissions.none,
    };
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
      });

    final vm = ref.watch(chatViewModelProvider);
    final chatNotifier = ref.read(chatViewModelProvider.notifier);
    final replyTo = vm.replyingTo;
    final forwardFrom = vm.forwardingFrom;
    final channelId = ref.watch(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final AsyncValue<ChannelMessagePermissions> permsAsync = ref.watch(
      channelMessagePermissionsProvider(channelId),
    );
    final ChannelMessagePermissions perms = switch (permsAsync) {
      AsyncData<ChannelMessagePermissions>(:final value) => value,
      _ => ChannelMessagePermissions.none,
    };

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
    final hasText = ref.watch(
      chatViewModelProvider.select((s) => s.messageText.isNotEmpty),
    );
    return Row(
      children: [
        if (perms.canAttachFiles) ...[
          FluxerButton.secondary(
            icon: PhosphorIconsFill.plusCircle,
            isSquare: true,
            size: FluxerButtonSize.compact,
            onPressed: () {},
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
              onEmojiSelected: (emoji) =>
                  _insertEmoji(emoji.name, emoji.surrogates),
              onGifSelected: _handleGifSelection,
              onStickerSelected: (sticker) {
                _handleStickerSelection(sticker);
                _gifPickerKey.currentState?.close();
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
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsFill.image, size: 24),
              color: context.colors.interactiveNormal,
              onPressed: perms.canSendMessages ? () {} : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          FluxerEmojiPickerPopout(
            key: _stickerPickerKey,
            initialTab: ExpressionPickerTab.stickers,
            onEmojiSelected: (emoji) =>
                _insertEmoji(emoji.name, emoji.surrogates),
            onGifSelected: _handleGifSelection,
            onStickerSelected: (sticker) {
              _handleStickerSelection(sticker);
              _stickerPickerKey.currentState?.close();
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
            onEmojiSelected: (emoji) =>
                _insertEmoji(emoji.name, emoji.surrogates),
            onGifSelected: _handleGifSelection,
            onStickerSelected: (sticker) {
              _handleStickerSelection(sticker);
              _expressionPickerKey.currentState?.close();
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
    final hasText = ref.watch(
      chatViewModelProvider.select((s) => s.messageText.isNotEmpty),
    );

    return Row(
      children: [
        if (perms.canAttachFiles) ...[
          FluxerButton.circle(
            icon: PhosphorIconsBold.plus,
            variant: FluxerButtonVariant.secondary,
            size: FluxerButtonSize.small,
            iconSize: 20,
            onPressed: () {},
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
                    vertical: 4,
                    horizontal: 7,
                  ),
                  child: _buildMobilePickerButton(context, perms),
                ),
                suffixIconConstraints: const BoxConstraints(),
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
}
