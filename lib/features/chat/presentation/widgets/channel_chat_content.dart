import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel_header.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/channel_textarea.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_chat_field.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/direct_voice_session_strip.dart';
import 'package:fluxer_app/features/voice/presentation/widgets/dm_call_e2ee_footer.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/dm_embedded_voice_call_panel.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/inline_expression_panel.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_list.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/neko_sprite.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/slowmode_indicator.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/typing_indicator_bar.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/upload_drop_overlay.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/expression_panel_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/features/chat/utils/inline_expression_panel_layout.dart';
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/shell/providers/reveal_side_provider.dart';

/// Composite chat view that assembles the top bar, message list,
/// and input field. Works for both server channels and DMs.
class ChannelChatContent extends ConsumerStatefulWidget {
  final String channelId;
  final bool showTopBar;
  final bool showInlineEmojiPicker;
  final String? targetMessageId;

  const ChannelChatContent({
    required this.channelId,
    this.showTopBar = true,
    this.showInlineEmojiPicker = true,
    this.targetMessageId,
    super.key,
  });

  @override
  ConsumerState<ChannelChatContent> createState() => _ChannelChatContentState();
}

class _ChannelChatContentState extends ConsumerState<ChannelChatContent> {
  ({String channelId, String? targetMessageId, bool loadMessages})?
  _lastSwitchRequest;
  ({String channelId, String? targetMessageId})? _lastClosedPanelRequest;

  final ComposerAutocompletePanelHost _composerAutocompletePanelHost =
      ComposerAutocompletePanelHost(null);
  final ScrollController _composerAutocompletePanelScroll = ScrollController();

  @override
  void dispose() {
    _composerAutocompletePanelScroll.dispose();
    _composerAutocompletePanelHost.dispose();
    super.dispose();
  }

  void _scheduleChannelSync({required bool loadMessages}) {
    final request = (
      channelId: widget.channelId,
      targetMessageId: widget.targetMessageId,
      loadMessages: loadMessages,
    );
    if (_lastSwitchRequest == request) {
      return;
    }
    _lastSwitchRequest = request;
    unawaited(
      Future(() async {
        if (!mounted) {
          return;
        }
        final closeRequest = (
          channelId: request.channelId,
          targetMessageId: request.targetMessageId,
        );
        if (_lastClosedPanelRequest != closeRequest) {
          _lastClosedPanelRequest = closeRequest;
          ref.read(expressionPanelProvider.notifier).close();
        }
        await ref
            .read(chatViewModelProvider.notifier)
            .switchChannel(
              request.channelId,
              targetMessageId: request.targetMessageId,
              loadMessages: request.loadMessages,
            );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileLayout(context);
    final revealSide = isMobile
        ? ref.watch(currentRevealSideProvider)
        : RevealSide.main;
    final shouldLoadMessages = channelChatShouldLoadMessages(
      isMobile: isMobile,
      revealSide: revealSide,
    );
    final isPanelOpen = ref.watch(expressionPanelProvider);
    final showNeko = ref.watch(
      appearancePreferencesProvider.select((state) => state.showNeko),
    );
    final panelBottomOffset = inlineExpressionPanelBottomOffset(
      keyboardInset: MediaQuery.viewInsetsOf(context).bottom,
    );
    _scheduleChannelSync(loadMessages: shouldLoadMessages);
    ref.listen<String?>(
      chatViewModelProvider.select((ChatViewState s) => s.errorMessage),
      (String? previous, String? next) {
        if (next == null || next == previous) {
          return;
        }
        ref.read(toastProvider.notifier).show(
          FluxerToast(message: next, variant: FluxerToastVariant.danger),
        );
        ref.read(chatViewModelProvider.notifier).clearErrorMessage();
      },
    );

    return ColoredBox(
      color: context.colors.chatBackground,
      child: SafeArea(
        child: UploadDropOverlay(
          channelId: widget.channelId,
          child: Stack(
            children: [
              Column(
                children: [
                  if (widget.showTopBar) const ChannelHeader(),
                  DmCallE2eeFooter(channelId: widget.channelId),
                  DirectVoiceSessionStrip(channelId: widget.channelId),
                  if (layoutModeOf(
                        layoutReferenceExtentOf(MediaQuery.sizeOf(context)),
                      ) ==
                      LayoutMode.desktop)
                    DmEmbeddedVoiceCallPanel(channelId: widget.channelId),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            child: shouldLoadMessages
                                ? MessageList(
                                    targetMessageId: widget.targetMessageId,
                                  )
                                : const SizedBox.expand(),
                          ),
                        ),

                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 0,
                          child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: TypingIndicatorBar(),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (showNeko) const NekoSprite(),
                                  const SlowmodeIndicator(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ComposerAutocompletePanelStrip(
                            host: _composerAutocompletePanelHost,
                            scrollController: _composerAutocompletePanelScroll,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ChannelTextarea(
                    autocompletePanelHost: _composerAutocompletePanelHost,
                    autocompletePanelScrollController:
                        _composerAutocompletePanelScroll,
                  ),
                  if (isMobile && isPanelOpen)
                    const SizedBox(height: kCollapsedPanelHeight),
                ],
              ),
              if (isMobile && isPanelOpen && widget.showInlineEmojiPicker)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: panelBottomOffset,
                  child: InlineExpressionPanel(
                    onClose: () =>
                        ref.read(expressionPanelProvider.notifier).close(),
                    onEmojiSelect: (name, surrogates) {
                      ref
                          .read(pendingEmojiInsertProvider.notifier)
                          .emit(name, surrogates);
                    },
                    onGifSelect: (selection) {
                      ref
                          .read(pendingGifSelectionProvider.notifier)
                          .emit(selection);
                    },
                    onStickerSelect: (selection) {
                      ref
                          .read(pendingStickerSelectionProvider.notifier)
                          .emit(selection);
                    },
                    onFavoriteMemeSelect: (selection) {
                      ref
                          .read(pendingFavoriteMemeSelectionProvider.notifier)
                          .emit(selection);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
bool channelChatShouldLoadMessages({
  required bool isMobile,
  required RevealSide revealSide,
}) {
  return !isMobile || revealSide == RevealSide.main;
}
