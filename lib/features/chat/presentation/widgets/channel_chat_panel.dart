import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/channel_textarea.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_chat_field.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/inline_expression_panel.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_list.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/neko_sprite.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/slowmode_indicator.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/typing_indicator_bar.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/expression_panel_provider.dart';
import 'package:fluxer_app/features/chat/utils/inline_expression_panel_layout.dart';
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_sheet_identity_header.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:fluxer_app/features/ui/ui.dart';

void listenChatViewModelErrors(WidgetRef ref) {
  ref.listen<String?>(
    chatViewModelProvider.select((ChatViewState s) => s.errorMessage),
    (String? previous, String? next) {
      if (next == null || next == previous) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(
            FluxerToast(message: next, variant: FluxerToastVariant.danger),
          );
      ref.read(chatViewModelProvider.notifier).clearErrorMessage();
    },
  );
}

/// Shared message list, composer, and overlay chrome for channel chat surfaces.
class ChannelChatPanel extends ConsumerWidget {
  const ChannelChatPanel({
    required this.composerAutocompletePanelHost,
    required this.composerAutocompletePanelScrollController,
    this.displayChannelId,
    this.targetMessageId,
    this.loadMessages = true,
    this.showInlineEmojiPicker = true,
    this.onClose,
    super.key,
  });

  final ComposerAutocompletePanelHost composerAutocompletePanelHost;
  final ScrollController composerAutocompletePanelScrollController;
  final String? displayChannelId;
  final String? targetMessageId;
  final bool loadMessages;
  final bool showInlineEmojiPicker;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = isMobileLayout(context);
    final String activeChannelId = ref.watch(
      chatViewModelProvider.select((ChatViewState state) => state.channelId),
    );
    final bool isMessageListReady =
        displayChannelId == null || activeChannelId == displayChannelId;
    final bool isPanelOpen = ref.watch(expressionPanelProvider);
    final bool showNeko = ref.watch(
      appearancePreferencesProvider.select((state) => state.showNeko),
    );
    final double panelBottomOffset = inlineExpressionPanelBottomOffset(
      keyboardInset: MediaQuery.viewInsetsOf(context).bottom,
    );
    return ColoredBox(
      color: context.colors.chatBackground,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        child: !loadMessages
                            ? const SizedBox.expand()
                            : isMessageListReady
                            ? MessageList(targetMessageId: targetMessageId)
                            : Center(
                                child: FluxerLoadingSpinner(
                                  color: context.colors.brandPrimary,
                                ),
                              ),
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
                        children: <Widget>[
                          const Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: TypingIndicatorBar(),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              if (onClose != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Material(
                                    color: context.colors.backgroundPrimary,
                                    shape: const CircleBorder(),
                                    child: FluxerSheetCloseButton(onTap: onClose!),
                                  ),
                                ),
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
                        host: composerAutocompletePanelHost,
                        scrollController:
                            composerAutocompletePanelScrollController,
                      ),
                    ),
                  ],
                ),
              ),
              ChannelTextarea(
                autocompletePanelHost: composerAutocompletePanelHost,
                autocompletePanelScrollController:
                    composerAutocompletePanelScrollController,
              ),
              if (isMobile && isPanelOpen)
                const SizedBox(height: kCollapsedPanelHeight),
            ],
          ),
          if (isMobile && isPanelOpen && showInlineEmojiPicker)
            Positioned(
              left: 0,
              right: 0,
              bottom: panelBottomOffset,
              child: InlineExpressionPanel(
                onClose: () =>
                    ref.read(expressionPanelProvider.notifier).close(),
                onEmojiSelect: (String name, String surrogates) {
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
    );
  }
}
