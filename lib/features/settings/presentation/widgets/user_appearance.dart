import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/core/theme/fluxer_theme_mode.dart';
import 'package:fluxeron/core/theme/providers/theme_preference_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserAppearance extends ConsumerWidget {
  final bool isCompact;
  final VoidCallback onToggleCompact;

  const UserAppearance({
    required this.isCompact,
    required this.onToggleCompact,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themePreferenceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: FluxerTextStyles.heading),
          const SizedBox(height: 32),
          const Text(
            'THEME',
            style: TextStyle(
              color: FluxerColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeCard(
                ref,
                label: 'Dark',
                icon: PhosphorIconsFill.moon,
                mode: FluxerThemeMode.dark,
                isSelected: themePref.mode == FluxerThemeMode.dark,
              ),
              const SizedBox(width: 12),
              _buildThemeCard(
                ref,
                label: 'Light',
                icon: PhosphorIconsFill.sun,
                mode: FluxerThemeMode.light,
                isSelected: themePref.mode == FluxerThemeMode.light,
              ),
              const SizedBox(width: 12),
              _buildThemeCard(
                ref,
                label: 'Coal',
                icon: PhosphorIconsFill.circleHalf,
                mode: FluxerThemeMode.coal,
                isSelected: themePref.mode == FluxerThemeMode.coal,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: FluxerColors.divider),
          const SizedBox(height: 32),
          const Text(
            'MESSAGE DISPLAY',
            style: TextStyle(
              color: FluxerColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildDisplayOption(
                'Cozy',
                'Discord classic \u2014 with big '
                    'avatars and lots of room',
                !isCompact,
                onToggleCompact,
              ),
              const SizedBox(height: 8),
              _buildDisplayOption(
                'Compact',
                'Fit more messages on screen '
                    'at once',
                isCompact,
                onToggleCompact,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: FluxerColors.divider),
          const SizedBox(height: 32),
          const Text(
            'CHAT FONT SCALING',
            style: TextStyle(
              color: FluxerColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: FluxerColors.blurple,
              thumbColor: FluxerColors.white,
              inactiveTrackColor: FluxerColors.backgroundAccent,
              overlayColor: FluxerColors.blurple.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: themePref.scaleFactor,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label: '${(themePref.scaleFactor * 100).round()}%',
              onChanged: (value) => ref
                  .read(themePreferenceProvider.notifier)
                  .setScaleFactor(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required FluxerThemeMode mode,
    required bool isSelected,
  }) =>
      Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                ref.read(themePreferenceProvider.notifier).setTheme(mode),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? FluxerColors.backgroundModifierSelected
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? FluxerColors.blurple
                      : FluxerColors.interactiveMuted,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  PhosphorIcon(
                    icon,
                    size: 28,
                    color: isSelected
                        ? FluxerColors.blurple
                        : FluxerColors.interactiveNormal,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? FluxerColors.textNormal
                          : FluxerColors.interactiveNormal,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildDisplayOption(
    String label,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? FluxerColors.backgroundModifierSelected
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                _buildRadioCircle(isSelected),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? FluxerColors.textNormal
                            : FluxerColors.interactiveNormal,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: FluxerColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildRadioCircle(bool isSelected) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? FluxerColors.blurple
                : FluxerColors.interactiveMuted,
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: FluxerColors.blurple,
                  ),
                ),
              )
            : null,
      );
}
