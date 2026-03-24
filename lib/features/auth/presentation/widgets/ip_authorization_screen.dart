import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/domain/ip_authorization_challenge.dart';
import 'package:fluxeron/features/auth/providers/ip_authorization_view_model.dart';
import 'package:fluxeron/features/ui/button/fluxer_button.dart';
import 'package:fluxeron/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IpAuthorizationScreen extends ConsumerWidget {
  const IpAuthorizationScreen({
    required this.challenge,
    required this.onAuthorized,
    required this.onBack,
    super.key,
  });

  final IpAuthorizationChallenge challenge;
  final VoidCallback onAuthorized;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(
      ipAuthorizationViewModelProvider(
        challenge.ticket,
        challenge.resendAvailableIn,
      ),
    );
    final notifier = ref.read(
      ipAuthorizationViewModelProvider(
        challenge.ticket,
        challenge.resendAvailableIn,
      ).notifier,
    );

    ref.listen(
      ipAuthorizationViewModelProvider(
        challenge.ticket,
        challenge.resendAvailableIn,
      ),
      (_, next) {
        if (next.completedSession != null) {
          onAuthorized();
        }
      },
    );

    final strings = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final isError = vm.pollingState == IpAuthPollingState.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isError
              ? PhosphorIconsFill.warningCircle
              : PhosphorIconsFill.envelopeSimple,
          size: 48,
          color: isError ? colors.textDanger : colors.textPrimary,
        ),
        SizedBox(height: layout.s4),
        Text(
          isError ? strings.ipAuthConnectionLost : strings.ipAuthCheckEmail,
          style: context.textStyles.heading,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.s2),
        Text(
          isError
              ? strings.ipAuthConnectionLostDescription
              : strings.ipAuthDescription(challenge.email),
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimaryMuted,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.s6),
        if (isError)
          FluxerButton.primary(onPressed: notifier.retry, label: strings.retry)
        else
          FluxerButton.secondary(
            onPressed: vm.resendIn > 0 || vm.resendUsed
                ? null
                : notifier.resend,
            label: _resendLabel(strings, vm),
          ),
        SizedBox(height: layout.s2),
        FluxerButton.secondary(onPressed: onBack, label: strings.back),
      ],
    );
  }

  String _resendLabel(FluxerLocalizations strings, IpAuthViewState vm) {
    final base = vm.resendUsed
        ? strings.ipAuthResent
        : strings.ipAuthResendEmail;
    if (vm.resendIn > 0) {
      return '$base (${strings.ipAuthResendCountdown(vm.resendIn)})';
    }
    return base;
  }
}
