import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const List<String> kQuickReactionDefaultEmojis = [
  '\u{1F44D}', // thumbsup
  '\u{1F44C}', // ok_hand
  '\u{1F389}', // tada
  '\u{2764}\u{FE0F}', // heart
];

class QuickReactionRow extends StatelessWidget {
  final List<String> emojis;
  final ValueChanged<String> onReaction;
  final VoidCallback? onAddMore;

  const QuickReactionRow({
    required this.onReaction,
    this.emojis = kQuickReactionDefaultEmojis,
    this.onAddMore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    return Padding(
      padding: EdgeInsets.only(
        left: layout.s1_5,
        right: layout.s1_5,
        top: layout.s1,
        bottom: layout.s1_5,
      ),
      child: Row(
        spacing: layout.s1,
        children: [
          for (final emoji in emojis)
            Expanded(
              child: _QuickReactionButton(
                onTap: () => onReaction(emoji),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
          if (onAddMore != null)
            Expanded(
              child: _QuickReactionButton(
                onTap: onAddMore!,
                child: PhosphorIcon(
                  PhosphorIconsBold.plus,
                  size: 22,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickReactionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _QuickReactionButton({required this.child, required this.onTap});

  @override
  State<_QuickReactionButton> createState() => _QuickReactionButtonState();
}

class _QuickReactionButtonState extends State<_QuickReactionButton> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _isHovered
                  ? context.colors.backgroundModifierSelected
                  : context.colors.backgroundModifierHover,
              borderRadius: context.layout.radiusLg,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
