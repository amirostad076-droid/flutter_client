import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/character_counter/fluxer_character_counter.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const int _kMaxDisplayNameLength = 32;
const int _kMaxPronounsLength = 40;
const int _kMaxBioLength = 320;
const double _kBannerHeight = 120;

class UserProfile extends ConsumerStatefulWidget {
  const UserProfile({super.key});

  @override
  ConsumerState<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends ConsumerState<UserProfile> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _pronounsController;
  late final TextEditingController _bioController;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _pronounsController = TextEditingController();
    _bioController = TextEditingController()..addListener(_onBioChanged);
  }

  @override
  void dispose() {
    _bioController.removeListener(_onBioChanged);
    _displayNameController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onBioChanged() {
    setState(() {});
  }

  void _syncControllers(UserSettingsViewState state) {
    if (!_controllersInitialized && state.isProfileLoaded) {
      _displayNameController.text = state.displayName;
      _pronounsController.text = state.pronouns ?? '';
      _bioController.text = state.bio ?? '';
      _controllersInitialized = true;
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
    final textStyles = context.textStyles;

    return SingleChildScrollView(
      padding: EdgeInsets.all(layout.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Customization',
            style: textStyles.heading.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: layout.s1),
          Text(
            'Edit your profile appearance and see a live preview',
            style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: layout.s6),
          _buildUsernameSection(state, colors, textStyles, layout),
          SizedBox(height: layout.s5),
          FluxerInput(
            controller: _displayNameController,
            label: 'Display Name',
            hint: state.username,
            maxLength: _kMaxDisplayNameLength,
            onChanged: vm.updateDisplayName,
          ),
          SizedBox(height: layout.s5),
          FluxerInput(
            controller: _pronounsController,
            label: 'Pronouns',
            maxLength: _kMaxPronounsLength,
            onChanged: vm.updatePronouns,
          ),
          SizedBox(height: layout.s5),
          _buildAvatarSection(state, vm, colors, textStyles, layout),
          SizedBox(height: layout.s5),
          _buildBannerSection(state, vm, colors, textStyles, layout),
          SizedBox(height: layout.s5),
          FluxerColorPickerField(
            label: 'Accent Color',
            value: state.isEditedAccentColorSet
                ? (state.editedAccentColor ?? 0)
                : (state.accentColor ?? 0),
            onChanged: vm.updateAccentColor,
          ),
          SizedBox(height: layout.s5),
          FluxerInput.multiline(
            controller: _bioController,
            label: 'Bio',
            maxLength: _kMaxBioLength,
            maxLines: 6,
            onChanged: vm.updateBio,
          ),
          SizedBox(height: layout.s1),
          Align(
            alignment: Alignment.centerRight,
            child: FluxerCharacterCounter(
              current: _bioController.text.length,
              max: _kMaxBioLength,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameSection(
    UserSettingsViewState state,
    FluxerColorTheme colors,
    FluxerTextTheme textStyles,
    FluxerLayoutTheme layout,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: textStyles.label.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: layout.s2),
        Row(
          children: [
            Expanded(
              child: Text(
                '${state.username}#${state.discriminator}',
                style: textStyles.bodyMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const FluxerButton.primary(
              onPressed: null,
              label: 'Change FluxerTag',
              size: FluxerButtonSize.small,
              fitContent: true,
            ),
          ],
        ),
        SizedBox(height: layout.s1),
        Text(
          'Change your username and 4-digit tag',
          style: textStyles.smallText.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    FluxerColorTheme colors,
    FluxerTextTheme textStyles,
    FluxerLayoutTheme layout,
  ) {
    final hasAvatar =
        (state.avatarUrl != null || state.editedAvatarBase64 != null) &&
        !state.avatarCleared;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avatar',
          style: textStyles.label.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: layout.s3),
        Row(
          children: [
            FluxerAvatar.user(
              fallbackText: state.displayName,
              userId: state.userId,
              imageUrl: state.avatarCleared ? null : state.avatarUrl,
              avatarColor: state.avatarColor,
              size: 80,
              showStatus: false,
            ),
            SizedBox(width: layout.s4),
            Expanded(
              child: Wrap(
                spacing: layout.s2,
                runSpacing: layout.s2,
                children: [
                  FluxerButton.secondary(
                    onPressed: () {},
                    label: 'Upload Avatar',
                    icon: PhosphorIconsRegular.uploadSimple,
                    size: FluxerButtonSize.small,
                    fitContent: true,
                  ),
                  if (hasAvatar)
                    FluxerButton.dangerSecondary(
                      onPressed: vm.clearAvatar,
                      label: 'Remove',
                      size: FluxerButtonSize.small,
                      fitContent: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBannerSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    FluxerColorTheme colors,
    FluxerTextTheme textStyles,
    FluxerLayoutTheme layout,
  ) {
    final hasBanner =
        (state.bannerUrl != null || state.editedBannerBase64 != null) &&
        !state.bannerCleared;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banner',
          style: textStyles.label.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: layout.s3),
        ClipRRect(
          borderRadius: layout.radiusLg,
          child: Container(
            width: double.infinity,
            height: _kBannerHeight,
            color: Color(state.accentColor ?? 0xFF5865F2),
            child: hasBanner && state.bannerUrl != null
                ? Image.network(state.bannerUrl!, fit: BoxFit.cover)
                : const SizedBox.shrink(),
          ),
        ),
        SizedBox(height: layout.s3),
        Wrap(
          spacing: layout.s2,
          runSpacing: layout.s2,
          children: [
            FluxerButton.secondary(
              onPressed: () {},
              label: 'Upload Banner',
              icon: PhosphorIconsRegular.uploadSimple,
              size: FluxerButtonSize.small,
              fitContent: true,
            ),
            if (hasBanner)
              FluxerButton.dangerSecondary(
                onPressed: vm.clearBanner,
                label: 'Remove',
                size: FluxerButtonSize.small,
                fitContent: true,
              ),
          ],
        ),
      ],
    );
  }
}
