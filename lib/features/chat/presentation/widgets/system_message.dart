import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Renders a system message as a single row with an icon,
/// bold author name, descriptive text, and timestamp.
class SystemMessage extends StatelessWidget {
  final Message message;

  const SystemMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, text) = _iconAndText();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        children: [
          Opacity(
            opacity: 0.6,
            child: PhosphorIcon(
              icon,
              size: 18,
              color: context.colors.textTertiaryMuted,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: message.authorName,
                    style: TextStyle(
                      color: context.colors.textChat,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: ' $text',
                    style: TextStyle(
                      color: context.colors.textTertiaryMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(message.timestamp),
            style: TextStyle(
              color: context.colors.textTertiaryMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String) _iconAndText() {
    switch (message.type) {
      case 7:
        return (PhosphorIconsFill.arrowRight, 'joined the server.');
      case 19:
        return (PhosphorIconsFill.pushPin, 'pinned a message.');
      case 2:
        return (PhosphorIconsFill.info, message.content);
      case 3:
        return (PhosphorIconsFill.phone, 'started a call.');
      case 4:
        return (
          PhosphorIconsFill.textAa,
          'changed the channel name.',
        );
      case 5:
        return (
          PhosphorIconsFill.image,
          'changed the channel icon.',
        );
      case 6:
        return (PhosphorIconsFill.pushPin, 'pinned a message.');
      default:
        return (PhosphorIconsFill.info, message.content);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (isToday) {
      return 'Today at $h:$m';
    }
    return '${dt.month}/${dt.day}/${dt.year} $h:$m';
  }
}
