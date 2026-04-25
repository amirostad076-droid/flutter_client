import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_mode.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/theme_swatch_button.dart';
import 'package:fluxer_app/features/settings/providers/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserLookAndFeel extends ConsumerWidget {
  const UserLookAndFeel({required this.scrollController, super.key});

  final ScrollController scrollController;

  static const _darkSwatch = Color(0xFF1E222C);
  static const _coalSwatch = Color(0xFF050608);
  static const _lightSwatch = Color(0xFFFBFBFC);
  static const _systemDarkSwatch = Color(0xFF0A0B0F);

  static const _chatFontSizeMarkers = <double>[12, 14, 15, 16, 18, 20, 24];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = FluxerLocalizations.of(context);
    final themePref = ref.watch(themePreferenceProvider);
    final appearance = ref.watch(appearancePreferencesProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final layout = context.layout;

    final systemSwatchColor = platformBrightness == Brightness.dark
        ? _systemDarkSwatch
        : _lightSwatch;

    final isSystem = themePref.mode == FluxerThemeMode.system;

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluxerSettingsSection(
            title: l10n.lookAndFeelThemeSectionTitle,
            description: l10n.lookAndFeelThemeSectionDescription,
            isFirst: true,
            children: [
              Row(
                spacing: layout.s3,
                children: [
                  Expanded(
                    child: ThemeSwatchButton(
                      label: l10n.lookAndFeelThemeDark,
                      backgroundColor: _darkSwatch,
                      isSelected: themePref.mode == FluxerThemeMode.dark,
                      onTap: () => unawaited(
                        ref
                            .read(themePreferenceProvider.notifier)
                            .setTheme(FluxerThemeMode.dark),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ThemeSwatchButton(
                      label: l10n.lookAndFeelThemeCoal,
                      backgroundColor: _coalSwatch,
                      isSelected: themePref.mode == FluxerThemeMode.coal,
                      onTap: () => unawaited(
                        ref
                            .read(themePreferenceProvider.notifier)
                            .setTheme(FluxerThemeMode.coal),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ThemeSwatchButton(
                      label: l10n.lookAndFeelThemeLight,
                      backgroundColor: _lightSwatch,
                      isSelected: themePref.mode == FluxerThemeMode.light,
                      onTap: () => unawaited(
                        ref
                            .read(themePreferenceProvider.notifier)
                            .setTheme(FluxerThemeMode.light),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ThemeSwatchButton(
                      label: l10n.lookAndFeelThemeSystem,
                      backgroundColor: systemSwatchColor,
                      isSelected: isSystem,
                      centerIcon: PhosphorIconsFill.arrowsCounterClockwise,
                      onTap: () => unawaited(
                        ref
                            .read(themePreferenceProvider.notifier)
                            .setTheme(FluxerThemeMode.system),
                      ),
                    ),
                  ),
                ],
              ),
              FluxerSwitchGroup(
                children: [
                  FluxerSwitchGroupItem(
                    label: l10n.lookAndFeelSyncThemeAcrossDevicesLabel,
                    description: isSystem
                        ? l10n.lookAndFeelSyncThemeAcrossDevicesSystemDescription
                        : l10n.lookAndFeelSyncThemeAcrossDevicesDescription,
                    value: themePref.syncAcrossDevices && !isSystem,
                    enabled: !isSystem,
                    onChanged: (value) => unawaited(
                      ref
                          .read(themePreferenceProvider.notifier)
                          .setSyncAcrossDevices(value: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.lookAndFeelChatFontScalingTitle,
            description: l10n.lookAndFeelChatFontScalingDescription,
            children: [
              FluxerSlider(
                defaultValue: themePref.chatFontSize.toDouble(),
                factoryDefaultValue: 16,
                minValue: 12,
                maxValue: 24,
                markers: _chatFontSizeMarkers,
                stickToMarkers: true,
                onMarkerRender: (value) => Text('${value.toInt()}px'),
                onValueRender: (value) => Text('${value.toInt()}px'),
                onValueChange: (value) => unawaited(
                  ref
                      .read(themePreferenceProvider.notifier)
                      .setChatFontSize(value.toInt()),
                ),
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.lookAndFeelInterfaceTitle,
            description: l10n.lookAndFeelInterfaceDescription,
            children: [
              FluxerSettingsSubsection(
                title: l10n.lookAndFeelChannelTypingIndicatorsTitle,
                description: l10n.lookAndFeelChannelTypingIndicatorsDescription,
                children: [
                  FluxerRadioGroup<ChannelTypingIndicatorMode>(
                    value: appearance.channelTypingIndicatorMode,
                    onChanged: (value) => unawaited(
                      ref
                          .read(appearancePreferencesProvider.notifier)
                          .setChannelTypingIndicatorMode(value),
                    ),
                    items: [
                      FluxerRadioItem(
                        value: ChannelTypingIndicatorMode.avatars,
                        label: l10n.lookAndFeelChannelTypingIndicatorAvatarsName,
                        description: l10n
                            .lookAndFeelChannelTypingIndicatorAvatarsDescription,
                      ),
                      FluxerRadioItem(
                        value: ChannelTypingIndicatorMode.indicatorOnly,
                        label: l10n.lookAndFeelChannelTypingIndicatorOnlyName,
                        description: l10n
                            .lookAndFeelChannelTypingIndicatorOnlyDescription,
                      ),
                      FluxerRadioItem(
                        value: ChannelTypingIndicatorMode.hidden,
                        label: l10n.lookAndFeelChannelTypingIndicatorHiddenName,
                        description: l10n
                            .lookAndFeelChannelTypingIndicatorHiddenDescription,
                      ),
                    ],
                  ),
                  FluxerSwitchGroup(
                    children: [
                      FluxerSwitchGroupItem(
                        label: l10n
                            .lookAndFeelShowSelectedChannelTypingIndicatorLabel,
                        description: l10n
                            .lookAndFeelShowSelectedChannelTypingIndicatorDescription,
                        value: appearance.showSelectedChannelTypingIndicator,
                        onChanged: (value) => unawaited(
                          ref
                              .read(appearancePreferencesProvider.notifier)
                              .setShowSelectedChannelTypingIndicator(
                                value: value,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FluxerSettingsSubsection(
                title: l10n.lookAndFeelGuildSidebarTitle,
                description: l10n.lookAndFeelGuildSidebarDescription,
                children: [
                  FluxerSwitchGroup(
                    children: [
                      FluxerSwitchGroupItem(
                        label: l10n.lookAndFeelCollapseDMsLabel,
                        description: l10n.lookAndFeelCollapseDMsDescription,
                        value: appearance.collapseDMs,
                        onChanged: (value) => unawaited(
                          ref
                              .read(appearancePreferencesProvider.notifier)
                              .setCollapseDMs(value: value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.lookAndFeelChannelListSectionTitle,
            description: l10n.lookAndFeelChannelListSectionDescription,
            children: [
              FluxerSwitchGroup(
                children: [
                  FluxerSwitchGroupItem(
                    label: l10n
                        .lookAndFeelShowFadedUnreadOnMutedChannelsLabel,
                    description: l10n
                        .lookAndFeelShowFadedUnreadOnMutedChannelsDescription,
                    value: appearance.showFadedUnreadOnMutedChannels,
                    onChanged: (value) => unawaited(
                      ref
                          .read(appearancePreferencesProvider.notifier)
                          .setShowFadedUnreadOnMutedChannels(value: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.lookAndFeelActiveNowSectionTitle,
            description: l10n.lookAndFeelActiveNowSectionDescription,
            children: [
              FluxerSwitchGroup(
                children: [
                  FluxerSwitchGroupItem(
                    label: l10n.lookAndFeelShowActiveNowLabel,
                    description: l10n.lookAndFeelShowActiveNowDescription,
                    value: appearance.showActiveNow,
                    onChanged: (value) => unawaited(
                      ref
                          .read(appearancePreferencesProvider.notifier)
                          .setShowActiveNow(value: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
          FluxerSettingsSection(
            title: l10n.lookAndFeelFavoritesSectionTitle,
            description: l10n.lookAndFeelFavoritesSectionDescription,
            children: [
              FluxerSwitchGroup(
                children: [
                  FluxerSwitchGroupItem(
                    label: l10n.lookAndFeelEnableFavoritesLabel,
                    description: l10n.lookAndFeelEnableFavoritesDescription,
                    value: appearance.showFavorites,
                    onChanged: (value) => unawaited(
                      ref
                          .read(appearancePreferencesProvider.notifier)
                          .setShowFavorites(value: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
