import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

class UserAccessibility extends ConsumerWidget {
  const UserAccessibility({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userSettingsViewModelProvider);
    final notifier = ref.read(userSettingsViewModelProvider.notifier);
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluxerSettingsSection(
            title: l10n.accessibilityUnreadGroupTitle,
            description: l10n.accessibilityUnreadGroupDescription,
            isFirst: true,
            children: [
              FluxerSettingsSwitchItem(
                label: l10n.accessibilityShowFadedUnreadOnMutedChannelsLabel,
                description:
                    l10n.accessibilityShowFadedUnreadOnMutedChannelsDescription,
                value: state.showFadedUnreadOnMutedChannels,
                onChanged: (value) =>
                    notifier.setShowFadedUnreadOnMutedChannels(value: value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
