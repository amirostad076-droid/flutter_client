import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_dart/export.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MuteSelection {
  const MuteSelection({required this.muted, this.durationSeconds});

  final bool muted;
  final int? durationSeconds;
}

const List<int> kMuteDurationsSeconds = <int>[
  900,
  1800,
  3600,
  10800,
  14400,
  28800,
  86400,
  259200,
];

String muteDurationLabel(int seconds, FluxerLocalizations l10n) {
  return switch (seconds) {
    900 => l10n.dmMuteFor15Min,
    1800 => l10n.dmMuteFor30Min,
    3600 => l10n.dmMuteFor1Hour,
    10800 => l10n.dmMuteFor3Hours,
    14400 => l10n.dmMuteFor4Hours,
    28800 => l10n.dmMuteFor8Hours,
    86400 => l10n.dmMuteFor24Hours,
    259200 => l10n.dmMuteFor3Days,
    _ => 'For ${seconds ~/ 60} minutes',
  };
}

String? formatMutedHintText(ChannelOverridesMuteConfig? config) {
  if (config == null) {
    return null;
  }
  final endTimeStr = config.endTime;
  if (endTimeStr == null) {
    return 'Muted';
  }
  final end = DateTime.tryParse(endTimeStr)?.toLocal();
  if (end == null) {
    return 'Muted';
  }
  return 'Muted until ${_formatMuteEnd(end)}';
}

String _formatMuteEnd(DateTime t) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour12 = t.hour > 12
      ? t.hour - 12
      : t.hour == 0
      ? 12
      : t.hour;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.hour >= 12 ? 'PM' : 'AM';
  return '${months[t.month - 1]} ${t.day}, ${t.year} $hour12:$minute $period';
}

class MuteDurationSheetBody extends StatelessWidget {
  const MuteDurationSheetBody({
    required this.isMuted,
    required this.onSelected,
    this.muteConfig,
    super.key,
  });

  final bool isMuted;
  final ChannelOverridesMuteConfig? muteConfig;
  final ValueChanged<MuteSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final mutedText = isMuted ? formatMutedHintText(muteConfig) : null;

    return FluxerBottomSheetGroupColumn(
      children: [
        if (mutedText != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.backgroundSecondaryAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'Currently: $mutedText',
                  style: context.textStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        FluxerMenuGroup(
          children: isMuted
              ? [
                  FluxerBottomSheetMenuItem(
                    label: l10n.dmUnmuteConversation,
                    onTap: () => onSelected(const MuteSelection(muted: false)),
                  ),
                ]
              : [
                  for (final seconds in kMuteDurationsSeconds)
                    FluxerBottomSheetMenuItem(
                      label: muteDurationLabel(seconds, l10n),
                      trailing: muteConfig?.selectedTimeWindow == seconds
                          ? PhosphorIcon(
                              PhosphorIconsBold.check,
                              size: 20,
                              color: colors.textPrimary,
                            )
                          : null,
                      onTap: () => onSelected(
                        MuteSelection(muted: true, durationSeconds: seconds),
                      ),
                    ),
                  FluxerBottomSheetMenuItem(
                    label: l10n.dmMuteForever,
                    trailing: muteConfig != null && muteConfig!.endTime == null
                        ? PhosphorIcon(
                            PhosphorIconsBold.check,
                            size: 20,
                            color: colors.textPrimary,
                          )
                        : null,
                    onTap: () => onSelected(const MuteSelection(muted: true)),
                  ),
                ],
        ),
      ],
    );
  }
}

Future<MuteSelection?> showMuteDurationSheet(
  BuildContext context, {
  required bool isMuted,
  ChannelOverridesMuteConfig? muteConfig,
  String? muteTitle,
  String? unmuteTitle,
  bool useRootNavigator = false,
}) {
  return FluxerBottomSheet.show<MuteSelection>(
    context,
    title: isMuted ? (unmuteTitle ?? 'Unmute') : (muteTitle ?? 'Mute'),
    variant: FluxerBottomSheetVariant.menu,
    useRootNavigator: useRootNavigator,
    builder: (sheetContext, _) => FluxerBottomSheetContent(
      child: MuteDurationSheetBody(
        isMuted: isMuted,
        muteConfig: muteConfig,
        onSelected: (selection) => Navigator.of(sheetContext).pop(selection),
      ),
    ),
  );
}
