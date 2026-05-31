import 'package:flutter/material.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

class VoiceChannelJoinButton extends StatelessWidget {
  const VoiceChannelJoinButton({
    required this.onPressed,
    this.disabledTooltip,
    super.key,
  });

  final VoidCallback? onPressed;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final Widget button = FluxerButton.primary(
      onPressed: onPressed,
      label: l10n.voiceChannelJoin,
    );
    if (onPressed != null || disabledTooltip == null) {
      return button;
    }
    return Tooltip(message: disabledTooltip, child: button);
  }
}
