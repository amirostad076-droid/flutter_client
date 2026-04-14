import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/account_delete_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/account_disable_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/backup_codes_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/claim_account_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/email_change_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/passkey_name_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/password_change_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/phone_add_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/totp_disable_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/totp_enable_sheet.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_size.dart';
import 'package:fluxer_app/features/ui/modal/fluxer_modal.dart';
import 'package:fluxer_app/features/ui/text/fluxer_field_label.dart';
import 'package:fluxer_app/features/ui/text/fluxer_section_heading.dart';
import 'package:fluxer_app/features/ui/text_link/fluxer_text_link.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/features/ui/tooltip/fluxer_tooltip.dart';
import 'package:fluxer_app/features/ui/warning_alert/fluxer_warning_alert.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_dart/export.dart';

const int _kFlagStaff = 1 << 0;
const int _kFlagPartner = 1 << 2;
const int _kMaxPasskeys = 10;

class UserSecurityLogin extends ConsumerStatefulWidget {
  const UserSecurityLogin({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserSecurityLogin> createState() => _UserSecurityLoginState();
}

class _UserSecurityLoginState extends ConsumerState<UserSecurityLogin> {
  bool _emailRevealed = false;
  bool _phoneRevealed = false;
  List<WebAuthnCredentialResponse>? _passkeys;
  bool _loadingPasskeys = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPasskeys());
  }

  Future<void> _loadPasskeys() async {
    setState(() => _loadingPasskeys = true);
    try {
      final client = ref.read(fluxerClientProvider);
      final result = await client.users.listWebauthnCredentials();
      if (mounted) {
        setState(() {
          _passkeys = result;
          _loadingPasskeys = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _loadingPasskeys = false);
      }
    }
  }

  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) {
      return email;
    }
    return '${'*' * atIndex}${email.substring(atIndex)}';
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) {
      return '*' * phone.length;
    }
    return '${'*' * (phone.length - 2)}${phone.substring(phone.length - 2)}';
  }

  String _relativeDate(String isoDate, FluxerLocalizations l10n) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) {
      return isoDate;
    }
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) {
      return l10n.relativeTimeYears((diff.inDays / 365).floor());
    }
    if (diff.inDays > 30) {
      return l10n.relativeTimeMonths((diff.inDays / 30).floor());
    }
    if (diff.inDays > 0) {
      return l10n.relativeTimeDays(diff.inDays);
    }
    if (diff.inHours > 0) {
      return l10n.relativeTimeHours(diff.inHours);
    }
    if (diff.inMinutes > 0) {
      return l10n.relativeTimeMinutes(diff.inMinutes);
    }
    return l10n.relativeTimeJustNow;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsViewModelProvider);
    final colors = context.colors;
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluxerSectionHeading(
            title: l10n.securityAccountTitle,
            description: l10n.securityAccountDescription,
          ),
          SizedBox(height: layout.s4),
          _buildEmailSection(state, colors, l10n),
          _divider(colors),
          _buildPasswordSection(state, colors, l10n),

          _divider(colors),
          FluxerSectionHeading(
            title: l10n.securitySectionTitle,
            description: l10n.securitySectionDescription,
          ),
          SizedBox(height: layout.s4),
          _buildSecuritySection(state, colors, l10n),

          _divider(colors),
          _buildDangerZone(state, colors, l10n),
        ],
      ),
    );
  }

  Widget _divider(FluxerColorTheme colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Divider(color: colors.borderColor),
  );

  Widget _buildEmailSection(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(colors, l10n.securityLoginEmailSectionTitle,
            l10n.securityLoginEmailSectionDescription),
        const SizedBox(height: 20),
        if (!s.hasVerifiedEmail) ...[
          FluxerWarningAlert(
            variant: FluxerAlertVariant.warning,
            message: l10n.securityLoginNoEmailSet,
          ),
          const SizedBox(height: 12),
          FluxerButton.primary(
            onPressedAsync: () => ClaimAccountSheet.show(context, ref),
            label: l10n.securityLoginAddEmail,
            size: FluxerButtonSize.small,
          ),
        ] else ...[
          _responsiveRow(
            label: l10n.securityLoginEmailAddressLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _emailRevealed
                      ? s.email!
                      : _maskEmail(s.email!),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimaryMuted,
                  ),
                ),
                const SizedBox(height: 4),
                FluxerTextLink(
                  text: _emailRevealed
                      ? l10n.securityLoginHide
                      : l10n.securityLoginReveal,
                  onTap: () => setState(
                    () => _emailRevealed = !_emailRevealed,
                  ),
                ),
              ],
            ),
            button: FluxerButton.primary(
              onPressedAsync: () => EmailChangeSheet.show(context, ref),
              label: l10n.securityLoginChangeEmail,
              size: FluxerButtonSize.small,
            ),
          ),
          if (!s.verified) ...[
            const SizedBox(height: 16),
            FluxerWarningAlert(
              variant: FluxerAlertVariant.info,
              message: l10n.securityVerifyEmailRequired,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPasswordSection(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(colors, l10n.securityLoginPasswordSectionTitle,
            l10n.securityLoginPasswordSectionDescription),
        const SizedBox(height: 20),
        if (!s.hasVerifiedEmail) ...[
          Text(
            l10n.securityLoginNoPasswordSet,
            style: TextStyle(fontSize: 14, color: colors.statusWarning),
          ),
          const SizedBox(height: 12),
          FluxerButton.primary(
            onPressedAsync: () => ClaimAccountSheet.show(context, ref),
            label: l10n.securityLoginSetPassword,
            size: FluxerButtonSize.small,
          ),
        ] else ...[
          _responsiveRow(
            label: l10n.securityLoginCurrentPasswordLabel,
            child: Text(
              _passwordLastChanged(s, l10n),
              style: TextStyle(fontSize: 14, color: colors.textPrimaryMuted),
            ),
            button: FluxerButton.primary(
              onPressedAsync: () =>
                  PasswordChangeSheet.show(context, ref),
              label: l10n.securityLoginChangePassword,
              size: FluxerButtonSize.small,
            ),
          ),
        ],
      ],
    );
  }

  String _passwordLastChanged(
    UserSettingsViewState s,
    FluxerLocalizations l10n,
  ) {
    final lc = s.passwordLastChangedAt;
    if (lc == null) {
      return l10n.securityLoginPasswordNeverChanged;
    }
    return l10n.securityLoginPasswordLastChanged(
      _relativeDate(lc, l10n),
    );
  }

  Widget _buildSecuritySection(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    if (!s.hasVerifiedEmail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              colors, l10n.securityClaimTitle, l10n.securityClaimDescription),
          const SizedBox(height: 12),
          FluxerButton.primary(
            onPressedAsync: () => ClaimAccountSheet.show(context, ref),
            label: l10n.claimAccount,
            size: FluxerButtonSize.small,
          ),
        ],
      );
    }

    if (!s.verified) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            colors,
            l10n.securityTfaSectionTitle,
            l10n.securityTfaSectionDescription,
          ),
          const SizedBox(height: 12),
          FluxerWarningAlert(
            variant: FluxerAlertVariant.warning,
            message: l10n.securityVerifyEmailRequired,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTfaSubsection(s, colors, l10n),
        const SizedBox(height: 32),
        _buildPasskeysSubsection(s, colors, l10n),
        if (s.mfaEnabled) ...[
          const SizedBox(height: 32),
          _buildPhoneSubsection(s, colors, l10n),
        ],
        if (s.mfaEnabled && s.phone != null) ...[
          const SizedBox(height: 32),
          _buildSmsSubsection(s, colors, l10n),
        ],
      ],
    );
  }

  Widget _buildTfaSubsection(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          colors,
          l10n.securityTfaSectionTitle,
          l10n.securityTfaSectionDescription,
        ),
        const SizedBox(height: 20),
        _responsiveRow(
          label: l10n.securityTfaAuthenticatorApp,
          child: Text(
            s.hasTotpMfa
                ? l10n.securityTfaAuthenticatorEnabled
                : l10n.securityTfaAuthenticatorDisabled,
            style: TextStyle(fontSize: 14, color: colors.textPrimaryMuted),
          ),
          button: s.hasTotpMfa
              ? FluxerButton.dangerPrimary(
                  onPressedAsync: () =>
                      TotpDisableSheet.show(context, ref),
                  label: l10n.disable,
                  size: FluxerButtonSize.small,
                )
              : FluxerButton.primary(
                  onPressedAsync: () =>
                      TotpEnableSheet.show(context, ref),
                  label: l10n.enable,
                  size: FluxerButtonSize.small,
                ),
        ),
        if (s.hasTotpMfa) ...[
          const SizedBox(height: 20),
          _responsiveRow(
            label: l10n.securityTfaBackupCodes,
            child: Text(
              l10n.securityTfaBackupCodesDescription,
              style: TextStyle(fontSize: 14, color: colors.textPrimaryMuted),
            ),
            button: FluxerButton.secondary(
              onPressedAsync: () =>
                  BackupCodesSheet.showView(context, ref),
              label: l10n.securityTfaViewCodes,
              size: FluxerButtonSize.small,
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildPasskeysSubsection(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    final count = _passkeys?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(colors, l10n.securityPasskeysSectionTitle,
            l10n.securityPasskeysSectionDescription),
        const SizedBox(height: 20),
        _responsiveRow(
          label: l10n.securityPasskeysRegistered,
          child: Text(
            count == 0
                ? l10n.securityPasskeysNone
                : l10n.securityPasskeysCount(count),
            style: TextStyle(fontSize: 14, color: colors.textPrimaryMuted),
          ),
          button: FluxerButton.primary(
            onPressedAsync:
                _loadingPasskeys || count >= _kMaxPasskeys
                    ? null
                    : _handleAddPasskey,
            label: l10n.securityPasskeysAdd,
            size: FluxerButtonSize.small,
          ),
        ),
        if (_passkeys != null && _passkeys!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._passkeys!.map((pk) => _buildPasskeyItem(pk, colors, l10n)),
        ],
      ],
    );
  }

  Widget _buildPasskeyItem(
    WebAuthnCredentialResponse pk,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    final details = StringBuffer(
      l10n.securityPasskeysAdded(
        _relativeDate(pk.createdAt, l10n),
      ),
    );
    if (pk.lastUsedAt != null) {
      details.write(
        ' \u2022 '
        '${l10n.securityPasskeysLastUsed(_relativeDate(pk.lastUsedAt!, l10n))}',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pk.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            details.toString(),
            style: TextStyle(fontSize: 13, color: colors.textPrimaryMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FluxerButton.secondary(
                onPressedAsync: () => _handleRenamePasskey(pk),
                label: l10n.securityPasskeysRename,
                size: FluxerButtonSize.compact,
                fitContent: true,
              ),
              const SizedBox(width: 8),
              FluxerButton.dangerSecondary(
                onPressedAsync: () =>
                    _handleDeletePasskey(pk, l10n),
                label: l10n.delete,
                size: FluxerButtonSize.compact,
                fitContent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddPasskey() async {
    await PasskeyNameSheet.showForCreate(
      context,
      ref,
      onCreated: _loadPasskeys,
    );
  }

  Future<void> _handleRenamePasskey(WebAuthnCredentialResponse pk) async {
    await PasskeyNameSheet.showForRename(
      context,
      ref,
      credentialId: pk.id,
      currentName: pk.name,
      onRenamed: _loadPasskeys,
    );
  }

  Future<void> _handleDeletePasskey(
    WebAuthnCredentialResponse pk,
    FluxerLocalizations l10n,
  ) async {
    final confirmed = await FluxerConfirmModal.show(
      context,
      title: l10n.securityPasskeysDeleteTitle,
      description: l10n.securityPasskeysDeleteDescription(pk.name),
      confirmLabel: l10n.securityPasskeysDeleteTitle,
      isDanger: true,
      onConfirm: () {},
    );
    if (confirmed != true) {
      return;
    }

    try {
      final client = ref.read(fluxerClientProvider);
      await client.users.deleteWebauthnCredential(
        credentialId: pk.id,
        body: const SudoVerificationSchema(),
      );
      await _loadPasskeys();
    } on Exception {
      // TODO: show error toast
    }
  }

  Widget _buildPhoneSubsection(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(colors, l10n.securityPhoneSectionTitle,
            l10n.securityPhoneSectionDescription),
        const SizedBox(height: 20),
        if (s.phone != null)
          _responsiveRow(
            label: l10n.securityPhoneLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phoneRevealed ? s.phone! : _maskPhone(s.phone!),
                  style:
                      TextStyle(fontSize: 14, color: colors.textPrimaryMuted),
                ),
                const SizedBox(height: 4),
                FluxerTextLink(
                  text: _phoneRevealed
                      ? l10n.securityLoginHide
                      : l10n.securityLoginReveal,
                  onTap: () => setState(
                    () => _phoneRevealed = !_phoneRevealed,
                  ),
                ),
              ],
            ),
            button: FluxerButton.dangerSecondary(
              onPressedAsync: () => _handleRemovePhone(s, l10n),
              label: l10n.securityPhoneRemove,
              size: FluxerButtonSize.small,
            ),
          )
        else
          _responsiveRow(
            label: l10n.securityPhoneLabel,
            child: Text(
              l10n.securityPhoneNone,
              style: TextStyle(fontSize: 14, color: colors.textPrimaryMuted),
            ),
            button: FluxerButton.primary(
              onPressedAsync: () => PhoneAddSheet.show(context, ref),
              label: l10n.securityPhoneAdd,
              size: FluxerButtonSize.small,
            ),
          ),
      ],
    );
  }

  Future<void> _handleRemovePhone(
    UserSettingsViewState s,
    FluxerLocalizations l10n,
  ) async {
    final description = s.hasSmsMfa
        ? '${l10n.securityPhoneRemoveDescription}'
            '\n\n${l10n.securityPhoneRemoveWarning}'
        : l10n.securityPhoneRemoveDescription;

    final confirmed = await FluxerConfirmModal.show(
      context,
      title: l10n.securityPhoneRemoveTitle,
      description: description,
      confirmLabel: l10n.securityPhoneRemove,
      isDanger: true,
      onConfirm: () {},
    );
    if (confirmed != true) {
      return;
    }

    try {
      final client = ref.read(fluxerClientProvider);
      await client.users.removePhoneFromAccount(
        body: const SudoVerificationSchema(),
      );
      ref.read(toastProvider.notifier).show(
        FluxerToast(
          message: l10n.securityPhoneRemoved,
          variant: FluxerToastVariant.success,
        ),
      );
      await ref.read(userSettingsViewModelProvider.notifier).loadProfile();
    } on Exception {
      // TODO: show error toast
    }
  }

  Widget _buildSmsSubsection(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    final isDisabledForUser =
        s.publicFlags & _kFlagStaff != 0 || s.publicFlags & _kFlagPartner != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(colors, l10n.securitySmsSectionTitle,
            l10n.securitySmsSectionDescription),
        const SizedBox(height: 20),
        _responsiveRow(
          label: l10n.securitySmsBackup,
          child: Text(
            s.hasSmsMfa ? l10n.securitySmsEnabled : l10n.securitySmsDisabled,
            style: TextStyle(fontSize: 14, color: colors.textPrimaryMuted),
          ),
          button: s.hasSmsMfa
              ? FluxerButton.dangerPrimary(
                  onPressedAsync: () => _handleDisableSms(l10n),
                  label: l10n.disable,
                  size: FluxerButtonSize.small,
                )
              : isDisabledForUser
                  ? FluxerTooltip(
                      message: l10n.securitySmsDisabledForPartners,
                      child: FluxerButton.primary(
                        onPressed: null,
                        label: l10n.enable,
                        size: FluxerButtonSize.small,
                      ),
                    )
                  : FluxerButton.primary(
                      onPressedAsync: () => _handleEnableSms(l10n),
                      label: l10n.enable,
                      size: FluxerButtonSize.small,
                    ),
        ),
      ],
    );
  }

  Future<void> _handleEnableSms(FluxerLocalizations l10n) async {
    final confirmed = await FluxerConfirmModal.show(
      context,
      title: l10n.securitySmsEnableTitle,
      description: l10n.securitySmsEnableDescription,
      confirmLabel: l10n.enable,
      onConfirm: () {},
    );
    if (confirmed != true) {
      return;
    }

    try {
      final client = ref.read(fluxerClientProvider);
      await client.users.enableSmsMfa(body: const SudoVerificationSchema());
      await ref.read(userSettingsViewModelProvider.notifier).loadProfile();
    } on Exception {
      // TODO: show error toast
    }
  }

  Future<void> _handleDisableSms(FluxerLocalizations l10n) async {
    final confirmed = await FluxerConfirmModal.show(
      context,
      title: l10n.securitySmsDisableTitle,
      description: l10n.securitySmsDisableDescription,
      confirmLabel: l10n.disable,
      isDanger: true,
      onConfirm: () {},
    );
    if (confirmed != true) {
      return;
    }

    try {
      final client = ref.read(fluxerClientProvider);
      await client.users.disableSmsMfa(body: const SudoVerificationSchema());
      await ref.read(userSettingsViewModelProvider.notifier).loadProfile();
    } on Exception {
      // TODO: show error toast
    }
  }

  Widget _buildDangerZone(
    UserSettingsViewState s,
    FluxerColorTheme colors,
    FluxerLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluxerSectionHeading(
          title: l10n.dangerZoneSectionTitle,
          description: l10n.dangerZoneSectionDescription,
        ),
        SizedBox(height: context.layout.s4),

        if (s.hasVerifiedEmail) ...[
          _sectionHeader(colors, l10n.dangerZoneDisableTitle,
              l10n.dangerZoneDisableDescription),
          const SizedBox(height: 12),
          FluxerButton.dangerPrimary(
            onPressedAsync: () =>
                AccountDisableSheet.show(context, ref),
            label: l10n.dangerZoneDisableTitle,
            size: FluxerButtonSize.small,
          ),
          const SizedBox(height: 32),
        ],

        _sectionHeader(colors, l10n.dangerZoneDeleteTitle,
            l10n.dangerZoneDeleteDescription),
        if (s.hasActiveSubscription) ...[
          const SizedBox(height: 8),
          Text(
            l10n.dangerZoneDeleteCancelSubscription,
            style: TextStyle(fontSize: 13, color: colors.statusWarning),
          ),
        ],
        const SizedBox(height: 12),
        FluxerButton.dangerPrimary(
          onPressedAsync: s.hasActiveSubscription
              ? null
              : () => AccountDeleteSheet.show(context, ref),
          label: l10n.dangerZoneDeleteTitle,
          size: FluxerButtonSize.small,
        ),
      ],
    );
  }

  Widget _sectionHeader(FluxerColorTheme colors, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(fontSize: 13, color: colors.textPrimaryMuted),
        ),
      ],
    );
  }

  Widget _responsiveRow({
    required String label,
    required Widget child,
    required Widget button,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 500) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FluxerFieldLabel(label),
                    const SizedBox(height: 4),
                    child,
                  ],
                ),
              ),
              const SizedBox(width: 24),
              button,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FluxerFieldLabel(label),
            const SizedBox(height: 4),
            child,
            const SizedBox(height: 12),
            button,
          ],
        );
      },
    );
  }
}
