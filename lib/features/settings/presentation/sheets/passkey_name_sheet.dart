import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_dart/export.dart';

class PasskeyNameSheet extends ConsumerStatefulWidget {
  const PasskeyNameSheet({
    super.key,
    this.initialName,
    this.credentialId,
    this.onSubmitted,
  });

  final String? initialName;
  final String? credentialId;
  final VoidCallback? onSubmitted;

  static Future<void> showForCreate(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? onCreated,
  }) {
    final l10n = FluxerLocalizations.of(context);
    return FluxerBottomSheet.show<void>(
      context,
      title: l10n.securityPasskeyNameTitle,
      useRootNavigator: true,
      builder: (_, _) => PasskeyNameSheet(
        onSubmitted: onCreated,
      ),
    );
  }

  static Future<void> showForRename(
    BuildContext context,
    WidgetRef ref, {
    required String credentialId,
    required String currentName,
    VoidCallback? onRenamed,
  }) {
    final l10n = FluxerLocalizations.of(context);
    return FluxerBottomSheet.show<void>(
      context,
      title: l10n.securityPasskeyNameTitle,
      useRootNavigator: true,
      builder: (_, _) => PasskeyNameSheet(
        initialName: currentName,
        credentialId: credentialId,
        onSubmitted: onRenamed,
      ),
    );
  }

  @override
  ConsumerState<PasskeyNameSheet> createState() => _PasskeyNameSheetState();
}

class _PasskeyNameSheetState extends ConsumerState<PasskeyNameSheet> {
  late final TextEditingController _nameController;
  bool _loading = false;
  String? _error;

  bool get _isRename => widget.credentialId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(fluxerClientProvider);

      if (_isRename) {
        await client.users.updateWebauthnCredential(
          credentialId: widget.credentialId!,
          body: WebAuthnCredentialUpdateRequest(name: name),
        );
      } else {
        // For create flow: get registration options, perform WebAuthn ceremony,
        // then register the credential with the chosen name.
        // The WebAuthn ceremony itself is platform-specific.
        // For now, we get registration options and attempt registration.
        await client.users.getWebauthnRegistrationOptions(
          body: const SudoVerificationSchema(),
        );

        // TODO: Integrate with WebAuthnService to perform the platform
        // registration ceremony using options.challenge, then call
        // registerWebauthnCredential with the response.
        // For now we just close since the WebAuthn bridge needs platform work.
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSubmitted?.call();
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitted?.call();
      }
    } on DioException catch (e) {
      final l10n = FluxerLocalizations.of(context);
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? (data['message'] as String?) ?? l10n.genericError
          : l10n.genericError;
      setState(() {
        _loading = false;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FluxerLocalizations.of(context);
    final layout = context.layout;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FluxerInput(
            controller: _nameController,
            label: l10n.securityPasskeyNameLabel,
            hint: l10n.securityPasskeyNameHint,
            autofocus: true,
            maxLength: 64,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
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
                  onPressed: _loading ? null : _handleSubmit,
                  label: l10n.save,
                  isLoading: _loading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
