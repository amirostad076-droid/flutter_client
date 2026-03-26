import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/auth/providers/login_view_model.dart';
import 'package:fluxeron/features/ui/button/fluxer_button.dart';
import 'package:fluxeron/features/ui/input/fluxer_input.dart';
import 'package:fluxeron/features/ui/text_link/fluxer_text_link.dart';
import 'package:fluxeron/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginViewModelProvider);
    final l10n = FluxerLocalizations.of(context);

    if (vm.forgotPasswordEmailSent) {
      return _EmailSentView(onBack: widget.onBack);
    }

    return _EmailEntryView(
      controller: _emailController,
      isSubmitting: vm.isLoggingIn,
      errorMessage: vm.errorMessage,
      fieldErrors: vm.fieldErrors,
      onSubmit: () {
        unawaited(
          ref
              .read(loginViewModelProvider.notifier)
              .submitForgotPassword(_emailController.text),
        );
      },
      onBack: widget.onBack,
      l10n: l10n,
    );
  }
}

class _EmailEntryView extends StatelessWidget {
  const _EmailEntryView({
    required this.controller,
    required this.isSubmitting,
    required this.errorMessage,
    required this.fieldErrors,
    required this.onSubmit,
    required this.onBack,
    required this.l10n,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final FluxerLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    return AbsorbPointer(
      absorbing: isSubmitting,
      child: AnimatedOpacity(
        opacity: isSubmitting ? 0.6 : 1.0,
        duration: context.motion.fast,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.forgotPasswordTitle,
              style: textStyles.heading.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.s2),
            Text(
              l10n.forgotPasswordDescription,
              style: textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.s6),
            FluxerInput(
              controller: controller,
              label: l10n.email,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => onSubmit(),
              errorText: fieldErrors['email'],
            ),
            SizedBox(height: layout.s6),
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              Text(
                errorMessage!,
                style: textStyles.bodySmall.copyWith(color: colors.textDanger),
              ),
              SizedBox(height: layout.s2),
            ],
            FluxerButton.primary(
              onPressed: onSubmit,
              label: l10n.forgotPasswordSubmit,
              isLoading: isSubmitting,
            ),
            SizedBox(height: layout.s5),
            FluxerButton.ghost(
              onPressed: onBack,
              label: l10n.forgotPasswordBackToLogin,
            ),
            SizedBox(height: layout.s2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.needAccountPrompt,
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                FluxerTextLink(
                  text: l10n.register,
                  onTap: () {},
                  style: textStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailSentView extends StatelessWidget {
  const _EmailSentView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIconsFill.envelopeSimple,
          size: 48,
          color: colors.brandPrimary,
        ),
        SizedBox(height: layout.s4),
        Text(
          l10n.forgotPasswordSentTitle,
          style: textStyles.heading.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.s2),
        Text(
          l10n.forgotPasswordSentDescription,
          style: textStyles.bodySmall.copyWith(color: colors.textPrimaryMuted),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.s6),
        FluxerButton.ghost(
          onPressed: onBack,
          label: l10n.forgotPasswordBackToLogin,
        ),
      ],
    );
  }
}
