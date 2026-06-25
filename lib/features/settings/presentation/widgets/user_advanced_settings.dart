import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/measure/measure_reporting_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

class UserAdvancedSettings extends ConsumerWidget {
  const UserAdvancedSettings({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(measureReportingProvider.notifier);
    final bool isAvailable = measureReportingIsAvailable();
    final bool isEnabled = ref.watch(measureReportingProvider);
    final layout = context.layout;
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluxerSettingsSection(
            title: l10n.advancedPerformanceReportingTitle,
            description: l10n.advancedPerformanceReportingSectionDescription,
            isFirst: true,
            children: [
              FluxerSettingsSwitchItem(
                label: l10n.advancedPerformanceReportingLabel,
                description: l10n.advancedPerformanceReportingDescription,
                value: isEnabled,
                enabled: isAvailable,
                onChanged: (bool value) => notifier.setEnabled(value: value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
