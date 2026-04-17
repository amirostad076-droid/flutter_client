import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

class UserProfileCustomStatus extends StatelessWidget {
  const UserProfileCustomStatus({required this.text, super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final value = text;
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      value,
      style: context.textStyles.bodySmall.copyWith(
        color: context.colors.textSecondary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
