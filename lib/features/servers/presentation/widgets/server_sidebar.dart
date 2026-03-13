import 'dart:math';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ServerSidebar extends ConsumerWidget {
  const ServerSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(serverListViewModelProvider);
    final servers = vm.servers;
    final selectedId = vm.selectedServerId;
    final isDm = vm.isDmActive;

    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: FluxerColors.serverSidebarBackground,
        border: Border(right: BorderSide(color: FluxerColors.separator)),
      ),
      child: ListView(
        padding: EdgeInsets.only(
          top: max(MediaQuery.of(context).padding.top, 12),
          bottom: 12,
        ),
        children: [
          _ServerIcon(
            label: 'DM',
            isSelected: isDm,
            svgAsset: 'assets/images/fluxer-logo-color.svg',
            onTap: () {
              ref.read(serverListViewModelProvider.notifier).setDmActive();
              context.go('/dms');
            },
          ),
          _ServerIcon(
            label: 'Favorites',
            isSelected: vm.isFavoritesActive,
            icon: PhosphorIconsFill.star,
            onTap: () {
              ref
                  .read(serverListViewModelProvider.notifier)
                  .setFavoritesActive();
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Divider(color: FluxerColors.divider, height: 2),
          ),
          for (final server in servers)
            _ServerIcon(
              label: server.name,
              isSelected: server.id == selectedId && !isDm,
              iconUrl: server.iconUrl,
              onTap: () {
                ref
                    .read(serverListViewModelProvider.notifier)
                    .selectServer(server.id);
                context.go('/servers');
              },
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Divider(color: FluxerColors.divider, height: 2),
          ),
          _DashedServerIcon(
            label: 'Add a Server',
            icon: PhosphorIconsRegular.plus,
            onTap: () {},
          ),
          _DashedServerIcon(
            label: 'Help',
            icon: PhosphorIconsRegular.question,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ServerIcon extends StatefulWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onTap;
  final String? iconUrl;

  const _ServerIcon({
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.icon,
    this.svgAsset,
    this.iconUrl,
  });

  @override
  State<_ServerIcon> createState() => _ServerIconState();
}

class _ServerIconState extends State<_ServerIcon> {
  var _isHovered = false;

  Widget _buildBackupIcon() {
    return Center(
      child: widget.svgAsset != null
          ? SvgPicture.asset(widget.svgAsset!, width: 48, height: 48)
          : widget.icon != null
              ? PhosphorIcon(widget.icon!, color: FluxerColors.white, size: 32)
              : Text(
                  _abbreviation(widget.label),
                  style: const TextStyle(
                    color: FluxerColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;
    final borderRadius = isActive ? 16.0 : 24.0;
    final bgColor = isActive
        ? FluxerColors.serverIconActive
        : FluxerColors.serverIconBackground;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 4,
            height: widget.isSelected ? 40 : 0,
            decoration: const BoxDecoration(
              color: FluxerColors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RightTooltip(
            message: widget.label,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(borderRadius),
                    child: widget.iconUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.iconUrl!,
                            errorWidget: (context, url, error) =>
                                _buildBackupIcon(),
                            progressIndicatorBuilder:
                                (context, url, progress) => _buildBackupIcon(),
                          )
                        : _buildBackupIcon(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _abbreviation(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}

class _DashedServerIcon extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DashedServerIcon({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_DashedServerIcon> createState() => _DashedServerIconState();
}

class _DashedServerIconState extends State<_DashedServerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radiusAnim;
  late final Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _radiusAnim = Tween<double>(
      begin: 24,
      end: 16,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _colorAnim = ColorTween(
      begin: FluxerColors.interactiveMuted,
      end: FluxerColors.white,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() => _controller.forward();

  void _onExit() => _controller.reverse();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const SizedBox(width: 12),
        _RightTooltip(
          message: widget.label,
          child: MouseRegion(
            onEnter: (_) => _onEnter(),
            onExit: (_) => _onExit(),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => SizedBox(
                  width: 48,
                  height: 48,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      borderRadius: _radiusAnim.value,
                      color: _colorAnim.value ?? FluxerColors.interactiveMuted,
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        widget.icon,
                        color:
                            _colorAnim.value ?? FluxerColors.interactiveMuted,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;

  _DashedBorderPainter({required this.borderRadius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    const dashLength = 6.0;
    const gapLength = 4.0;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.color != color;
}

class _RightTooltip extends StatefulWidget {
  final String message;
  final Widget child;

  const _RightTooltip({required this.message, required this.child});

  @override
  State<_RightTooltip> createState() => _RightTooltipState();
}

class _RightTooltipState extends State<_RightTooltip> {
  OverlayEntry? _entry;

  void _show() {
    _hide();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final target = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: target.dx + size.width + 8,
        top: target.dy + (size.height - 32) / 2,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: FluxerColors.backgroundFloating,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: FluxerColors.textNormal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _show(),
    onExit: (_) => _hide(),
    child: widget.child,
  );
}
