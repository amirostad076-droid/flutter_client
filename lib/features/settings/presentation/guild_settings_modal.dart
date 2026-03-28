import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild_overview.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild_roles.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/settings_sidebar.dart';
import 'package:fluxer_app/features/settings/providers/guild_settings_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuildSettingsModal extends ConsumerStatefulWidget {
  final String serverId;
  final int initialTab;

  const GuildSettingsModal({
    required this.serverId,
    this.initialTab = 0,
    super.key,
  });

  @override
  ConsumerState<GuildSettingsModal> createState() => _GuildSettingsModalState();
}

class _GuildSettingsModalState extends ConsumerState<GuildSettingsModal> {
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

  late int _selectedIndex = widget.initialTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(guildSettingsViewModelProvider.notifier)
          .loadServer(widget.serverId)
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guildSettingsViewModelProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: ColoredBox(
              color: context.colors.backgroundSecondary,
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
                    child: _buildCloseButton(context),
                  ),
                ),
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GuildSettingsViewState state) {
    final guild = state.guild;
    if (guild == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return GuildOverview(guild: guild);
      case 1:
        return GuildRoles(roles: state.roles);
      default:
        return Center(
          child: Text(
            _items[_selectedIndex].label,
            style: TextStyle(
              color: context.colors.textPrimaryMuted,
              fontSize: 24,
            ),
          ),
        );
    }
  }

  Widget _buildCloseButton(BuildContext context) => InkWell(
    onTap: () => context.pop(),
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.interactiveMuted, width: 2),
      ),
      child: PhosphorIcon(
        PhosphorIconsFill.x,
        size: 18,
        color: context.colors.interactiveNormal,
      ),
    ),
  );
}
