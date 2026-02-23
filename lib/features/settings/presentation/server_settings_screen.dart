import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/settings/presentation/widgets/server_overview.dart';
import 'package:fluxeron/features/settings/presentation/widgets/server_roles.dart';
import 'package:fluxeron/features/settings/presentation/widgets/settings_sidebar.dart';
import 'package:fluxeron/features/settings/providers/server_settings_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ServerSettingsScreen extends ConsumerStatefulWidget {
  final String serverId;

  const ServerSettingsScreen({required this.serverId, super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() =>
      _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends ConsumerState<ServerSettingsScreen> {
  static const _items = [
    SettingsSidebarItem('Overview'),
    SettingsSidebarItem('Roles'),
    SettingsSidebarItem.separator(),
    SettingsSidebarItem('Emoji'),
    SettingsSidebarItem('Stickers'),
    SettingsSidebarItem.separator('MODERATION'),
    SettingsSidebarItem('Members'),
    SettingsSidebarItem('Channels'),
    SettingsSidebarItem('Bans'),
  ];

  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(serverSettingsViewModelProvider.notifier)
          .loadServer(widget.serverId)
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serverSettingsViewModelProvider);

    return Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: ColoredBox(
              color: FluxerColors.backgroundSecondary,
              child: SettingsSidebar(
                items: _items,
                selectedIndex: _selectedIndex,
                onSelected: (i) => setState(() => _selectedIndex = i),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildCloseButton(),
                  ),
                ),
                Expanded(child: _buildContent(state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ServerSettingsViewState state) {
    final server = state.server;
    if (server == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return ServerOverview(server: server);
      case 1:
        return ServerRoles(roles: state.roles);
      default:
        return Center(
          child: Text(
            _items[_selectedIndex].label,
            style: const TextStyle(color: FluxerColors.textMuted, fontSize: 24),
          ),
        );
    }
  }

  Widget _buildCloseButton() => InkWell(
    onTap: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/servers');
      }
    },
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: FluxerColors.interactiveMuted, width: 2),
      ),
      child: const PhosphorIcon(
        PhosphorIconsFill.x,
        size: 18,
        color: FluxerColors.interactiveNormal,
      ),
    ),
  );
}
