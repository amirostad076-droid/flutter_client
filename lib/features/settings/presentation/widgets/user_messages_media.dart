import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/external_links/external_link_utils.dart';
import 'package:fluxer_dart/export.dart';

enum _HideMutedChoice { applyAll, newOnly }

class UserMessagesMedia extends ConsumerWidget {
  const UserMessagesMedia({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userSettingsViewModelProvider);
    final notifier = ref.read(userSettingsViewModelProvider.notifier);
    final chat = ref.watch(chatPreferencesProvider);
    final chatNotifier = ref.read(chatPreferencesProvider.notifier);
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);

    final mediaSizeItems = [
      FluxerRadioItem(
        value: MediaDimensionSize.small,
        label: l10n.messagesMediaSizeCompactName,
        description: l10n.messagesMediaSizeCompactDescription,
      ),
      FluxerRadioItem(
        value: MediaDimensionSize.large,
        label: l10n.messagesMediaSizeComfortableName,
        description: l10n.messagesMediaSizeComfortableDescription,
      ),
    ];

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluxerSettingsSection(
            title: l10n.messagesMediaDisplayGroupTitle,
            description: l10n.messagesMediaDisplayGroupDescription,
            isFirst: true,
            children: [
              FluxerSettingsSubsection(
                title: l10n.messagesMediaDisplaySectionTitle,
                description: l10n.messagesMediaDisplaySectionDescription,
                children: [
                  FluxerSettingsSwitchGroup(
                    children: [
                      FluxerSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaDisplayInlineEmbedLabel,
                        value: state.inlineEmbedMedia,
                        onChanged: (value) =>
                            notifier.setInlineEmbedMedia(value: value),
                      ),
                      FluxerSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaDisplayInlineAttachmentLabel,
                        value: state.inlineAttachmentMedia,
                        onChanged: (value) =>
                            notifier.setInlineAttachmentMedia(value: value),
                      ),
                    ],
                  ),
                ],
              ),
              FluxerSettingsSubsection(
                title: l10n.messagesMediaLinkPreviewsSectionTitle,
                description: l10n.messagesMediaLinkPreviewsSectionDescription,
                children: [
                  FluxerSettingsSwitchItem(
                    label: l10n.messagesMediaLinkPreviewsToggleLabel,
                    value: state.renderEmbeds,
                    onChanged: (value) =>
                        notifier.setRenderEmbeds(value: value),
                  ),
                ],
              ),
              FluxerSettingsSubsection(
                title: l10n.messagesMediaReactionsSectionTitle,
                description: l10n.messagesMediaReactionsSectionDescription,
                children: [
                  FluxerSettingsSwitchItem(
                    label: l10n.messagesMediaReactionsToggleLabel,
                    value: state.renderReactions,
                    onChanged: (value) =>
                        notifier.setRenderReactions(value: value),
                  ),
                ],
              ),
              FluxerSettingsSubsection(
                title: l10n.messagesMediaSpoilersSectionTitle,
                description: l10n.messagesMediaSpoilersSectionDescription,
                children: [
                  FluxerRadioGroup<RenderSpoilers>(
                    label: l10n.messagesMediaSpoilersRadioLabel,
                    value: state.renderSpoilers,
                    onChanged: notifier.setRenderSpoilers,
                    items: [
                      FluxerRadioItem(
                        value: RenderSpoilers.onClick,
                        label: l10n.messagesMediaSpoilersOnClickName,
                        description:
                            l10n.messagesMediaSpoilersOnClickDescription,
                      ),
                      FluxerRadioItem(
                        value: RenderSpoilers.ifModerator,
                        label: l10n.messagesMediaSpoilersIfModeratorName,
                        description:
                            l10n.messagesMediaSpoilersIfModeratorDescription,
                      ),
                      FluxerRadioItem(
                        value: RenderSpoilers.always,
                        label: l10n.messagesMediaSpoilersAlwaysName,
                        description:
                            l10n.messagesMediaSpoilersAlwaysDescription,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.messagesMediaMediaGroupTitle,
            description: l10n.messagesMediaMediaGroupDescription,
            children: [
              FluxerSettingsSubsection(
                title: l10n.messagesMediaSizeSectionTitle,
                description: l10n.messagesMediaSizeSectionDescription,
                children: [
                  FluxerRadioGroup<MediaDimensionSize>(
                    label: l10n.messagesMediaSizeEmbedLabel,
                    value: chat.embedMediaDimensionSize,
                    onChanged: chatNotifier.setEmbedMediaDimensionSize,
                    items: mediaSizeItems,
                  ),
                  FluxerRadioGroup<MediaDimensionSize>(
                    label: l10n.messagesMediaSizeAttachmentLabel,
                    value: chat.attachmentMediaDimensionSize,
                    onChanged: chatNotifier.setAttachmentMediaDimensionSize,
                    items: mediaSizeItems,
                  ),
                ],
              ),
              FluxerSettingsSubsection(
                title: l10n.messagesMediaGifsSectionTitle,
                description: l10n.messagesMediaGifsSectionDescription,
                children: [
                  FluxerSettingsSwitchItem(
                    label: l10n.messagesMediaGifsAutoSendLabel,
                    value: chat.autoSendKlipyGifs,
                    onChanged: (value) =>
                        chatNotifier.setAutoSendKlipyGifs(value: value),
                  ),
                ],
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.messagesMediaInputGroupTitle,
            description: l10n.messagesMediaInputGroupDescription,
            children: [
              FluxerSettingsSubsection(
                title: l10n.messagesMediaAutocompleteSectionTitle,
                description: l10n.messagesMediaAutocompleteSectionDescription,
                children: [
                  FluxerSettingsSwitchGroup(
                    children: [
                      FluxerSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteDefaultEmojisLabel,
                        value: chat.showDefaultEmojisInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowDefaultEmojisInExpressionAutocomplete(
                              value: value,
                            ),
                      ),
                      FluxerSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteCustomEmojisLabel,
                        value: chat.showCustomEmojisInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowCustomEmojisInExpressionAutocomplete(
                              value: value,
                            ),
                      ),
                      FluxerSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteStickersLabel,
                        value: chat.showStickersInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowStickersInExpressionAutocomplete(
                              value: value,
                            ),
                      ),
                      FluxerSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteSavedMediaLabel,
                        value: chat.showMemesInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowMemesInExpressionAutocomplete(value: value),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.externalLinksSectionTitle,
            description: l10n.externalLinksSectionDescription,
            children: [
              FluxerSettingsSwitchItem(
                label: l10n.externalLinkTrustAllLabel,
                description: trustedDomainsDescription(
                  l10n: l10n,
                  trustAll: state.trustAllDomains,
                  trustedCount: state.trustedDomainsCount,
                ),
                value: state.trustAllDomains,
                onChanged: (value) =>
                    _handleTrustAllChange(context, ref, value),
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.messagesMediaSidebarGroupTitle,
            description: l10n.messagesMediaSidebarGroupDescription,
            children: [
              FluxerSettingsSwitchItem(
                label: l10n.messagesMediaDefaultHideMutedChannelsLabel,
                description:
                    l10n.messagesMediaDefaultHideMutedChannelsDescription,
                value: state.defaultHideMutedChannels,
                onChanged: (value) =>
                    _handleDefaultHideMutedChannelsChange(context, ref, value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleTrustAllChange(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(userSettingsViewModelProvider.notifier);
    final l10n = FluxerLocalizations.of(context);

    if (value) {
      final confirmed = await _showTrustConfirmSheet(
        context,
        title: l10n.externalLinkTrustAllConfirmTitle,
        description: l10n.externalLinkTrustAllConfirmDescription,
        confirmLabel: l10n.externalLinkTrustAllConfirmAction,
        isDanger: true,
      );

      if (confirmed != true) {
        return;
      }

      await notifier.setTrustAllDomains(trustAll: true);
      return;
    }

    final confirmed = await _showTrustConfirmSheet(
      context,
      title: l10n.externalLinkStopTrustingAllTitle,
      description: l10n.externalLinkStopTrustingAllDescription,
      confirmLabel: l10n.externalLinkStopTrustingAllAction,
    );

    if (confirmed != true) {
      return;
    }

    await notifier.setTrustAllDomains(trustAll: false);
  }

  Future<void> _handleDefaultHideMutedChannelsChange(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(userSettingsViewModelProvider.notifier);
    final choice = await _showHideMutedChannelsConfirmSheet(
      context,
      value: value,
    );

    if (choice == null) {
      return;
    }

    await notifier.setDefaultHideMutedChannels(value: value);

    if (choice == _HideMutedChoice.applyAll) {
      await notifier.applyDefaultHideMutedChannelsToExistingGuilds(
        value: value,
      );
    }
  }

  Future<bool?> _showTrustConfirmSheet(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
    bool isDanger = false,
  }) {
    return FluxerBottomSheet.show<bool>(
      context,
      title: title,
      builder: (sheetContext, close) {
        final layout = sheetContext.layout;
        final colors = sheetContext.colors;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                description,
                style: sheetContext.textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: layout.s5),
              if (isDanger)
                FluxerButton.dangerPrimary(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  label: confirmLabel,
                )
              else
                FluxerButton.primary(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  label: confirmLabel,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_HideMutedChoice?> _showHideMutedChannelsConfirmSheet(
    BuildContext context, {
    required bool value,
  }) {
    final l10n = FluxerLocalizations.of(context);
    final title = value
        ? l10n.messagesMediaDefaultHideMutedChannelsEnableTitle
        : l10n.messagesMediaDefaultHideMutedChannelsDisableTitle;
    final description = value
        ? l10n.messagesMediaDefaultHideMutedChannelsEnableDescription
        : l10n.messagesMediaDefaultHideMutedChannelsDisableDescription;
    final primaryLabel = value
        ? l10n.messagesMediaDefaultHideMutedChannelsApplyAllAction
        : l10n.messagesMediaDefaultHideMutedChannelsShowAllAction;

    return FluxerBottomSheet.show<_HideMutedChoice>(
      context,
      title: title,
      builder: (sheetContext, close) {
        final layout = sheetContext.layout;
        final colors = sheetContext.colors;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                description,
                style: sheetContext.textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: layout.s5),
              FluxerButton.primary(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(_HideMutedChoice.applyAll),
                label: primaryLabel,
              ),
              SizedBox(height: layout.s2),
              FluxerButton.secondary(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(_HideMutedChoice.newOnly),
                label: l10n.messagesMediaDefaultHideMutedChannelsNewOnlyAction,
              ),
            ],
          ),
        );
      },
    );
  }
}
