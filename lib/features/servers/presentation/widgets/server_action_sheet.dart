import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/servers/domain/server.dart';
import 'package:fluxeron/features/servers/presentation/'
    'widgets/server_context_menu.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<ServerAction?> showServerActionSheet(
  BuildContext context, {
  required Server server,
  bool hasUnread = false,
  bool isMuted = false,
}) async {
  final result = await showModalBottomSheet<ServerAction>(
    context: context,
    builder: (context) => _ServerActionSheet(
      server: server,
      hasUnread: hasUnread,
      isMuted: isMuted,
    ),
  );

  if (result == ServerAction.copyServerId) {
    await Clipboard.setData(
      ClipboardData(text: server.id),
    );
  }

  return result;
}

class _ServerActionSheet extends StatelessWidget {
  final Server server;
  final bool hasUnread;
  final bool isMuted;

  const _ServerActionSheet({
    required this.server,
    required this.hasUnread,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colors.backgroundModifierAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Text(
              server.name,
              style: context.textStyles.heading,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          if (hasUnread)
            _SheetItem(
              label: 'Mark as Read',
              icon: PhosphorIconsRegular.envelopeOpen,
              onTap: () => Navigator.of(context)
                  .pop(ServerAction.markAsRead),
            ),
          _SheetItem(
            label: isMuted
                ? 'Unmute Community'
                : 'Mute Community',
            icon: isMuted
                ? PhosphorIconsRegular.bellRinging
                : PhosphorIconsRegular.bellSlash,
            onTap: () => Navigator.of(context)
                .pop(ServerAction.muteToggle),
          ),
          _SheetItem(
            label: 'Copy Community ID',
            icon: PhosphorIconsRegular.hash,
            onTap: () => Navigator.of(context)
                .pop(ServerAction.copyServerId),
          ),
          _SheetItem(
            label: 'Leave Community',
            icon: PhosphorIconsRegular.signOut,
            isDanger: true,
            onTap: () => Navigator.of(context)
                .pop(ServerAction.leaveServer),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDanger;
  final VoidCallback onTap;

  const _SheetItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isDanger ? colors.textDanger : colors.textPrimary;

    return ListTile(
      leading: PhosphorIcon(icon, color: color, size: 22),
      title: Text(
        label,
        style: context.textStyles.label.copyWith(color: color),
      ),
      onTap: onTap,
    );
  }
}
