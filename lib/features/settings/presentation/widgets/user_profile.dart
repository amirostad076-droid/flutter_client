import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/character_counter/fluxer_character_counter.dart';
import 'package:fluxer_app/features/ui/ui.dart';

const int _kMaxDisplayNameLength = 32;
const int _kMaxPronounsLength = 40;
const int _kMaxBioLength = 320;

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
      padding: EdgeInsets.all(layout.s4),
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
          SizedBox(height: layout.s6),
          FluxerInput(
            controller: _displayNameController,
            label: 'Display Name',
            hint: state.username,
            maxLength: _kMaxDisplayNameLength,
            onChanged: vm.updateDisplayName,
          ),
          SizedBox(height: layout.s6),
          FluxerInput(
            controller: _pronounsController,
            label: 'Pronouns',
            maxLength: _kMaxPronounsLength,
            onChanged: vm.updatePronouns,
          ),
          SizedBox(height: layout.s6),
          _buildAvatarSection(state, vm, colors, textStyles, layout),
          SizedBox(height: layout.s6),
          _buildBannerSection(state, vm, colors, textStyles, layout),
          SizedBox(height: layout.s6),
          FluxerColorPickerField(
            label: 'Accent Color',
            description:
                'Customizes the border and banner color on '
                'your profile',
            value: state.isEditedAccentColorSet
                ? (state.editedAccentColor ?? 0)
                : (state.accentColor ?? 0),
            onChanged: vm.updateAccentColor,
            defaultValue: 0x4641D9,
          ),
          SizedBox(height: layout.s6),
          FluxerInput.multiline(
            controller: _bioController,
            label: 'About Me',
            maxLength: _kMaxBioLength,
            maxLines: 6,
            onChanged: vm.updateBio,
          ),
          SizedBox(height: layout.s1),
          Row(
            children: [
              Expanded(
                child: Text(
                  'You can use links, emoji, and Markdown.',
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              FluxerCharacterCounter(
                current: _bioController.text.length,
                max: _kMaxBioLength,
              ),
            ],
          ),
          SizedBox(height: layout.s8),
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
          style: textStyles.bodySmall.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: layout.s2),
        const FluxerButton.primary(
          onPressed: null,
          label: 'Change FluxerTag',
          size: FluxerButtonSize.small,
          fitContent: true,
        ),
        SizedBox(height: layout.s3),
        Text(
          'Change your username and 4-digit tag',
          style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
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
          style: textStyles.bodySmall.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: layout.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FluxerButton.primary(
              onPressed: () {},
              label: 'Upload Avatar',
              size: FluxerButtonSize.small,
            ),
            if (hasAvatar) ...[
              SizedBox(height: layout.s2),
              FluxerButton.dangerSecondary(
                onPressed: vm.clearAvatar,
                label: 'Remove Avatar',
                size: FluxerButtonSize.small,
              ),
            ],
          ],
        ),
        SizedBox(height: layout.s3),
        Text(
          'Recommended: 512×512 or larger, PNG or '
          'JPG under 10 MB',
          style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
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
          style: textStyles.bodySmall.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: layout.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FluxerButton.primary(
              onPressed: () {},
              label: 'Upload Banner',
              size: FluxerButtonSize.small,
            ),
            if (hasBanner) ...[
              SizedBox(height: layout.s2),
              FluxerButton.dangerSecondary(
                onPressed: vm.clearBanner,
                label: 'Remove Banner',
                size: FluxerButtonSize.small,
              ),
            ],
          ],
        ),
        SizedBox(height: layout.s3),
        Text(
          'Recommended: 1500×500 or larger, PNG or '
          'JPG under 10 MB',
          style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
