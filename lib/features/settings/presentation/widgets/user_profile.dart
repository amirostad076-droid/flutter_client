import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/expression_picker.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/fluxer_tag_change_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/image_crop_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/profile_preview_card.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/ui/input/emoji_text_editing_controller.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/utils/image_utils.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const int _kMaxDisplayNameLength = 32;
const int _kMaxPronounsLength = 40;
const int _kMaxBioLength = 320;

class UserProfile extends ConsumerStatefulWidget {
  const UserProfile({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends ConsumerState<UserProfile> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _pronounsController;
  late final EmojiTextEditingController _bioController;
  final _expressionPickerKey = GlobalKey<FluxerEmojiPickerPopoutState>();

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _pronounsController = TextEditingController();
    _bioController = EmojiTextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncControllers(UserSettingsViewState state) {
    if (!_controllersInitialized && state.isProfileLoaded) {
      _displayNameController.text = state.displayName;
      _pronounsController.text = state.pronouns ?? '';
      _bioController.loadWithTokens(state.bio ?? '');
      _controllersInitialized = true;
    }
  }

  void _onSmileyTap() {
    if (isMobileLayout(context)) {
      unawaited(
        FluxerEmojiPickerSheet.show(
          context,
          title: FluxerLocalizations.of(context).emojiPickerTitle,
          maxHeight: 0.88,
          onEmojiSelected: (emoji) =>
              _bioController.insertEmoji(emoji.name, emoji.surrogates),
          visibleTabs: const [ExpressionPickerTab.emojis],
        ),
      );
    } else {
      _expressionPickerKey.currentState?.toggle();
    }
  }

  Widget _buildUnclaimedAccountBar(
    FluxerLayoutTheme layout,
    FluxerLocalizations l10n,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundSecondaryAlt,
        border: Border(
          top: BorderSide(color: colors.accentWarning, width: 2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: layout.s4,
          right: layout.s4,
          top: layout.s3,
          bottom: bottomPadding > 0 ? bottomPadding : layout.s3,
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsBold.warning,
              color: colors.accentWarning,
              size: 20,
            ),
            SizedBox(width: layout.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.unclaimedAccountTitle,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: layout.s1),
                  Text(
                    l10n.unclaimedAccountDescription,
                    style: textStyles.smallText.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlutoniumSheet(BuildContext context) {
    final l10n = FluxerLocalizations.of(context);
    unawaited(
      FluxerBottomSheet.show<void>(
        context,
        title: l10n.plutoniumNotAvailableTitle,
        builder: (sheetContext, _) => Padding(
          padding: EdgeInsets.all(sheetContext.layout.s4),
          child: Text(
            l10n.plutoniumNotAvailableBody,
            style: sheetContext.textStyles.bodyMedium.copyWith(
              color: sheetContext.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleImageUpload({
    required bool isAvatar,
  }) async {
    final picked = await ImageUtils.pickImage();
    if (picked == null || !mounted) {
      return;
    }

    if (ImageUtils.isOverSizeLimit(picked.bytes)) {
      if (!mounted) {
        return;
      }
      final l10n = FluxerLocalizations.of(context);
      ref.read(toastProvider.notifier).show(
        FluxerToast(
          message: l10n.imageFileTooLarge,
          variant: FluxerToastVariant.danger,
        ),
      );
      return;
    }

    final animCheck = ImageUtils.checkAnimated(picked.bytes);
    final state = ref.read(userSettingsViewModelProvider);

    if (animCheck.isAnimated) {
      if (!state.isPremium) {
        if (!mounted) {
          return;
        }
        final l10n = FluxerLocalizations.of(context);
        ref.read(toastProvider.notifier).show(
          FluxerToast(
            message: isAvatar
                ? l10n.animatedAvatarsRequirePlutonium
                : l10n.animatedBannersRequirePlutonium,
            variant: FluxerToastVariant.warning,
          ),
        );
        return;
      }

      if (animCheck.format == 'avif') {
        if (!mounted) {
          return;
        }
        final l10n = FluxerLocalizations.of(context);
        final confirmed = await FluxerBottomSheet.show<bool>(
          context,
          title: l10n.animatedAvifNotSupported,
          builder: (sheetContext, _) => Padding(
            padding: EdgeInsets.all(sheetContext.layout.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.animatedAvifNotSupportedBody,
                  style: sheetContext.textStyles.bodyMedium.copyWith(
                    color: sheetContext.colors.textSecondary,
                  ),
                ),
                SizedBox(height: sheetContext.layout.s4),
                FluxerButton.primary(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  label: l10n.uploadAsIs,
                ),
                SizedBox(height: sheetContext.layout.s2),
                FluxerButton.secondary(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  label: l10n.cancel,
                ),
              ],
            ),
          ),
        );
        if (confirmed != true || !mounted) {
          return;
        }
      } else {
        ref.read(toastProvider.notifier).show(
          FluxerToast(
            message: FluxerLocalizations.of(context)
                .croppingAnimatedNotSupported,
          ),
        );
      }

      final dataUri = ImageUtils.toDataUri(picked.bytes);
      final vm = ref.read(userSettingsViewModelProvider.notifier);
      if (isAvatar) {
        vm.setAvatar(dataUri);
      } else {
        vm.setBanner(dataUri);
      }
      return;
    }

    if (!mounted) {
      return;
    }
    final croppedBytes = await showImageCropSheet(
      context,
      imageBytes: picked.bytes,
      aspectRatio: isAvatar ? 1.0 : 17.0 / 6.0,
      title: isAvatar
          ? FluxerLocalizations.of(context).cropAvatar
          : FluxerLocalizations.of(context).cropBanner,
      maskShape: isAvatar ? CropMaskShape.circle : CropMaskShape.rectangle,
    );

    if (croppedBytes == null || !mounted) {
      return;
    }

    final dataUri = ImageUtils.toDataUri(croppedBytes);
    final vm = ref.read(userSettingsViewModelProvider.notifier);
    if (isAvatar) {
      vm.setAvatar(dataUri);
    } else {
      vm.setBanner(dataUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsViewModelProvider);
    _syncControllers(state);

    if (!state.isProfileLoaded) {
      return const Center(child: FluxerLoadingSpinner());
    }

    final vm = ref.read(userSettingsViewModelProvider.notifier);
    final layout = context.layout;
    final colors = context.colors;
    final l10n = FluxerLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: EdgeInsets.all(layout.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FluxerSectionHeading(
                  title: l10n.profileCustomizationTitle,
                  description: l10n.profileCustomizationDescription,
                ),
                if (state.isOutOfBandTrialActive) ...[
                  SizedBox(height: layout.s6),
                  _buildPremiumTrialBanner(state, layout),
                ],
                SizedBox(height: layout.s6),
                _buildUsernameSection(state, layout, l10n),
                SizedBox(height: layout.s6),
                FluxerInput(
                  controller: _displayNameController,
                  label: l10n.displayNameLabel,
                  hint: state.username,
                  maxLength: _kMaxDisplayNameLength,
                  onChanged: vm.updateDisplayName,
                ),
                SizedBox(height: layout.s6),
                FluxerInput(
                  controller: _pronounsController,
                  label: l10n.pronounsLabel,
                  maxLength: _kMaxPronounsLength,
                  onChanged: vm.updatePronouns,
                ),
                SizedBox(height: layout.s6),
                _buildAvatarSection(state, vm, layout, l10n),
                SizedBox(height: layout.s6),
                _buildBannerSection(state, vm, layout, l10n),
                SizedBox(height: layout.s6),
                FluxerColorPickerField(
                  label: l10n.accentColorLabel,
                  description: l10n.accentColorDescription,
                  value: state.isEditedAccentColorSet
                      ? (state.editedAccentColor ?? 0)
                      : (state.accentColor ?? 0),
                  onChanged: vm.updateAccentColor,
                  defaultValue: 0x4641D9,
                ),
                SizedBox(height: layout.s6),
                FluxerInput.multiline(
                  controller: _bioController,
                  label: l10n.aboutMeLabel,
                  maxLength: _kMaxBioLength,
                  maxLines: 6,
                  showCounter: true,
                  helperText: l10n.aboutMeHelperText,
                  onChanged: (_) => vm.updateBio(_bioController.actualText),
                  suffixIcon: FluxerEmojiPickerPopout(
                    key: _expressionPickerKey,
                    visibleTabs: const [ExpressionPickerTab.emojis],
                    onEmojiSelected: (emoji) =>
                      _bioController.insertEmoji(
                        emoji.name,
                        emoji.surrogates,
                      ),
                    child: PhosphorIcon(
                      PhosphorIconsFill.smiley,
                      size: 20,
                      color: colors.textTertiary,
                    ),
                  ),
                  onSuffixTap: _onSmileyTap,
                ),
                SizedBox(height: layout.s8),
                ProfilePreviewCard(state: state),
                if (state.isPremium) ...[
                  SizedBox(height: layout.s8),
                  _buildPremiumBadgeSection(state, vm, layout, l10n),
                ],
                SizedBox(height: layout.s8),
              ],
            ),
          ),
        ),
        if (!state.hasVerifiedEmail)
          _buildUnclaimedAccountBar(layout, l10n),
      ],
    );
  }

  Widget _buildUsernameSection(
    UserSettingsViewState state,
    FluxerLayoutTheme layout,
    FluxerLocalizations l10n,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluxerFieldLabel(l10n.usernameLabel),
        SizedBox(height: layout.s2),
        Wrap(
          spacing: layout.s2,
          runSpacing: layout.s2,
          children: [
            if (!state.hasVerifiedEmail)
              FluxerTooltip(
                message: l10n.claimAccountToChangeFluxerTag,
                child: FluxerButton.primary(
                  onPressed: null,
                  label: l10n.changeFluxerTag,
                  size: FluxerButtonSize.small,
                ),
              )
            else
              FluxerButton.primary(
                onPressed: () => showFluxerTagChangeSheet(context),
                label: l10n.changeFluxerTag,
                size: FluxerButtonSize.small,
              ),
            if (!state.isPremium)
              FluxerTooltip(
                message: l10n.customizeTagWithPlutoniumTooltip(
                  state.discriminator,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brandPrimary,
                    borderRadius: layout.radiusSm,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.s2,
                      vertical: layout.s1_5,
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsFill.crown,
                      size: 16,
                      color: colors.textOnBrandPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: layout.s3),
        FluxerHintText(l10n.changeUsernameAndTagHint),
        if (state.premiumDiscriminator && !state.hasLifetimePremium) ...[
          SizedBox(height: layout.s2),
          Text(
            l10n.customTagSubscriptionWarning(state.discriminator),
            style: textStyles.bodySmall.copyWith(
              color: colors.accentWarning,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumTrialBanner(
    UserSettingsViewState state,
    FluxerLayoutTheme layout,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final l10n = FluxerLocalizations.of(context);

    final expiryDate = state.premiumOutOfBandTrialEndsAt;
    final expiryLabel = expiryDate != null
        ? DateFormat.yMMMd().format(expiryDate)
        : null;
    final hasActiveSubscription = state.premiumBillingCycle != null;

    final String title;
    final String? description;

    if (hasActiveSubscription && expiryLabel != null) {
      title = l10n.premiumTrialSubscriptionStarts(expiryLabel);
      description = l10n.premiumTrialSubscriptionStartsDescription;
    } else {
      title = expiryLabel != null
          ? l10n.premiumTrialExpiresOnProfile(expiryLabel)
          : l10n.premiumTrialActiveProfile;
      description = null;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandPrimary,
        borderRadius: layout.radiusMd,
      ),
      child: Padding(
        padding: EdgeInsets.all(layout.s3),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(right: layout.s3),
              child: PhosphorIcon(
                PhosphorIconsFill.crown,
                size: 32,
                color: colors.textOnBrandPrimary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textOnBrandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: layout.s1),
                    Text(
                      description,
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textOnBrandPrimary
                            .withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    FluxerLayoutTheme layout,
    FluxerLocalizations l10n,
  ) {
    final hasAvatar =
        (state.avatarUrl != null || state.editedAvatarBase64 != null) &&
        !state.avatarCleared;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluxerFieldLabel(l10n.avatarLabel),
        SizedBox(height: layout.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FluxerButton.primary(
              onPressed: () => _handleImageUpload(isAvatar: true),
              label: l10n.changeAvatar,
              size: FluxerButtonSize.small,
            ),
            if (hasAvatar) ...[
              SizedBox(height: layout.s2),
              FluxerButton.secondary(
                onPressed: vm.clearAvatar,
                label: l10n.removeAvatar,
                size: FluxerButtonSize.small,
              ),
            ],
          ],
        ),
        SizedBox(height: layout.s3),
        FluxerHintText(
          state.isPremium
              ? l10n.avatarDescription
              : l10n.avatarDescriptionNonPremium,
        ),
      ],
    );
  }

  Widget _buildBannerSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    FluxerLayoutTheme layout,
    FluxerLocalizations l10n,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    if (!state.isPremium) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FluxerFieldLabel(l10n.bannerLabel),
          SizedBox(height: layout.s2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.brandPrimary,
              borderRadius: layout.radiusMd,
            ),
            child: Padding(
              padding: EdgeInsets.all(layout.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2, right: layout.s2),
                    child: PhosphorIcon(
                      PhosphorIconsFill.crown,
                      size: 16,
                      color: colors.textOnBrandPrimary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.bannerPlutoniumUpsell,
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textOnBrandPrimary,
                          ),
                        ),
                        SizedBox(height: layout.s2),
                        FluxerButton.inverted(
                          onPressed: () => _showPlutoniumSheet(context),
                          label: l10n.getPlutonium,
                          size: FluxerButtonSize.small,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final hasBanner =
        (state.bannerUrl != null || state.editedBannerBase64 != null) &&
        !state.bannerCleared;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluxerFieldLabel(l10n.bannerLabel),
        SizedBox(height: layout.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FluxerButton.primary(
              onPressed: () => _handleImageUpload(isAvatar: false),
              label: l10n.changeBanner,
              size: FluxerButtonSize.small,
            ),
            if (hasBanner) ...[
              SizedBox(height: layout.s2),
              FluxerButton.secondary(
                onPressed: vm.clearBanner,
                label: l10n.removeBanner,
                size: FluxerButtonSize.small,
              ),
            ],
          ],
        ),
        SizedBox(height: layout.s3),
        FluxerHintText(l10n.bannerDescription),
      ],
    );
  }

  Widget _buildPremiumBadgeSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    FluxerLayoutTheme layout,
    FluxerLocalizations l10n,
  ) {
    final badgeHidden = state.effectivePremiumBadgeHidden;
    final badgeMasked = state.effectivePremiumBadgeMasked;

    String timestampLabel = l10n.hidePlutoniumPurchaseDate;
    if (state.premiumSince != null) {
      final date = DateTime.tryParse(state.premiumSince!);
      if (date != null) {
        final formatted = DateFormat.yMMMd().format(date);
        timestampLabel = l10n.hidePlutoniumPurchaseDateWithDate(formatted);
      }
    }

    String sequenceLabel = l10n.hideVisionaryIdBadge;
    if (state.premiumLifetimeSequence != null) {
      sequenceLabel = l10n.hideVisionaryIdBadgeWithSequence(
        state.premiumLifetimeSequence!,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FluxerSectionHeading(
          title: l10n.plutoniumBadgePrivacyTitle,
          description: l10n.plutoniumBadgePrivacyDescription,
        ),
        SizedBox(height: layout.s4),
        FluxerSwitchGroupItem(
          label: l10n.hidePlutoniumBadgeLabel,
          description: l10n.hidePlutoniumBadgeDescription,
          value: badgeHidden,
          onChanged: (value) =>
              vm.setPremiumBadgeHidden(value: value),
        ),
        FluxerSwitchGroupItem(
          label: timestampLabel,
          description: l10n.hidePurchaseDateDescription,
          value: state.effectivePremiumBadgeTimestampHidden,
          enabled: !badgeHidden,
          onChanged: (value) =>
              vm.setPremiumBadgeTimestampHidden(value: value),
        ),
        if (state.hasLifetimePremium) ...[
          FluxerSwitchGroupItem(
            label: l10n.maskVisionaryAsSubscription,
            description: l10n.maskVisionaryDescription,
            value: badgeMasked,
            enabled: !badgeHidden,
            onChanged: (value) =>
                vm.setPremiumBadgeMasked(value: value),
          ),
          FluxerSwitchGroupItem(
            label: sequenceLabel,
            description: l10n.hideVisionaryIdDescription,
            value: state.effectivePremiumBadgeSequenceHidden,
            enabled: !badgeHidden && !badgeMasked,
            onChanged: (value) =>
                vm.setPremiumBadgeSequenceHidden(value: value),
          ),
        ],
      ],
    );
  }
}
