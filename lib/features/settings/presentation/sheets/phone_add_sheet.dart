import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_dart/export.dart';

enum _Step { phone, code }

class PhoneAddSheet extends ConsumerStatefulWidget {
  const PhoneAddSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return FluxerBottomSheet.show<void>(
      context,
      title: FluxerLocalizations.of(context).phoneAddTitle,
      useRootNavigator: true,
      builder: (_, _) => const PhoneAddSheet(),
    );
  }

  @override
  ConsumerState<PhoneAddSheet> createState() => _PhoneAddSheetState();
}

class _PhoneAddSheetState extends ConsumerState<PhoneAddSheet> {
  _Step _step = _Step.phone;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _phoneToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _e164Phone {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) return digits;
    return '+$digits';
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    }
    return e.message ?? 'An error occurred';
  }

  Future<void> _handleSendCode() async {
    final phone = _e164Phone;
    if (phone.length < 4) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(fluxerClientProvider);
      await client.users.sendPhoneVerificationCode(
        body: PhoneSendVerificationRequest(phone: phone),
      );
      setState(() {
        _step = _Step.code;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = _extractError(e);
      });
    }
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(fluxerClientProvider);
      final response = await client.users.verifyPhoneCode(
        body: PhoneVerifyRequest(phone: _e164Phone, code: code),
      );

      _phoneToken = response.phoneToken;

      await client.users.addPhoneToAccount(
        body: PhoneAddRequest(phoneToken: _phoneToken!),
      );

      final l10n = FluxerLocalizations.of(context);
      ref.read(toastProvider.notifier).show(
        FluxerToast(
          message: l10n.phoneAddSuccess,
          variant: FluxerToastVariant.success,
        ),
      );

      await ref.read(userSettingsViewModelProvider.notifier).loadProfile();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = _extractError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_step == _Step.phone) ...[
            Text(
              l10n.phoneAddFooter,
              style: context.textStyles.bodySmall
                  .copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: layout.s4),
            FluxerInput(
              controller: _phoneController,
              label: l10n.phoneAddLabel,
              hint: '+1234567890',
              autofocus: true,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSendCode(),
              errorText: _error,
            ),
            SizedBox(height: layout.s4),
            Row(
              children: [
                Expanded(
                  child: FluxerButton.secondary(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    label: l10n.cancel,
                    fitContent: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FluxerButton.primary(
                    onPressed: _loading ? null : _handleSendCode,
                    label: l10n.phoneAddSendCode,
                    isLoading: _loading,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              l10n.phoneVerifyDescription,
              style: context.textStyles.bodySmall
                  .copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: layout.s4),
            FluxerInput(
              controller: _codeController,
              label: l10n.verificationCode,
              hint: 'XXXX-XXXX',
              autofocus: true,
              maxLength: 9,
              keyboardType: TextInputType.text,
              autofillHints: const [AutofillHints.oneTimeCode],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleVerify(),
              errorText: _error,
            ),
            SizedBox(height: layout.s4),
            Row(
              children: [
                Expanded(
                  child: FluxerButton.secondary(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _step = _Step.phone;
                              _error = null;
                            }),
                    label: l10n.back,
                    fitContent: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FluxerButton.primary(
                    onPressed: _loading ? null : _handleVerify,
                    label: l10n.verify,
                    isLoading: _loading,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
