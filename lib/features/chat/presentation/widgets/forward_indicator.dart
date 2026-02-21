import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';

/// A label shown on forwarded messages.
class ForwardIndicator extends StatelessWidget {
  final String source;

  const ForwardIndicator({required this.source, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 56, bottom: 4),
    child: Row(
      children: [
        const PhosphorIcon(
          PhosphorIconsFill.shareFat,
          size: 14,
          color: FluxerColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          'Forwarded from $source',
          style: const TextStyle(
            color: FluxerColors.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}
