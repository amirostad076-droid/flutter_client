import 'package:flutter/material.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';

class UserAppearance extends StatelessWidget {
  final bool isDarkTheme;
  final bool isCompact;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleCompact;

  const UserAppearance({
    required this.isDarkTheme,
    required this.isCompact,
    required this.onToggleTheme,
    required this.onToggleCompact,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
        Column(
          children: [
            _buildThemeOption('Dark', isDarkTheme, onToggleTheme),
            const SizedBox(height: 8),
            _buildThemeOption('Light', !isDarkTheme, onToggleTheme),
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
            value: 16,
            min: 12,
            max: 24,
            divisions: 6,
            label: '16px',
            onChanged: (_) {},
          ),
        ),
      ],
    ),
  );

  Widget _buildThemeOption(String label, bool isSelected, VoidCallback onTap) =>
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
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? FluxerColors.textNormal
                        : FluxerColors.interactiveNormal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildDisplayOption(
    String label,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) => Material(
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
