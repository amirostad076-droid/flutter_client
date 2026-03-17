import 'dart:math';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxeron/core/constants/assets.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/providers/unread_provider.dart';
import 'package:fluxeron/features/servers/providers/server_list_view_model.dart';
import 'package:fluxeron/shared/widgets/unread_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ServerSidebar extends ConsumerWidget {
  const ServerSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm =
        ref.watch(serverListViewModelProvider);
    final servers = vm.servers;
    final selectedId = vm.selectedServerId;
    final isDm = vm.isDmActive;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: context
            .colors.serverSidebarBackground,
        border: Border(
          right: BorderSide(
            color: context.colors.borderColor,
          ),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.only(
          top: max(
            MediaQuery.of(context).padding.top,
            12,
          ),
          bottom: 12,
        ),
        children: [
          _ServerIcon(
            label: 'Direct Messages',
            isSelected: isDm,
            svgAsset: Assets.fluxerLogoColor,
            onTap: () {
              ref
                  .read(
                    serverListViewModelProvider
                        .notifier,
                  )
                  .setDmActive();
              context.go('/channels/@me');
            },
          ),
          _ServerIcon(
            label: 'Favorites',
            isSelected: vm.isFavoritesActive,
            icon: PhosphorIconsFill.star,
            onTap: () {
              ref
                  .read(
                    serverListViewModelProvider
                        .notifier,
                  )
                  .setFavoritesActive();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3,
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  color: context
                      .colors.backgroundModifierHover,
                  borderRadius:
                      BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          for (final server in servers)
            Builder(
              builder: (context) {
                final unread = ref
                    .watch(
                      serverUnreadProvider(server.id),
                    )
                    .value;
                return _ServerIcon(
                  label: server.name,
                  isSelected:
                      server.id == selectedId && !isDm,
                  iconUrl: server.iconUrl,
                  hasUnread: unread?.hasUnread ?? false,
                  mentionCount:
                      unread?.mentionCount ?? 0,
                  onTap: () {
                    ref
                        .read(
                          serverListViewModelProvider
                              .notifier,
                        )
                        .selectServer(server.id);
                    context.go('/servers');
                  },
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3,
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  color: context
                      .colors.backgroundModifierHover,
                  borderRadius:
                      BorderRadius.circular(1),
                ),
              ),
            ),
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
  final bool hasUnread;
  final int mentionCount;

  const _ServerIcon({
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.icon,
    this.svgAsset,
    this.iconUrl,
    this.hasUnread = false,
    this.mentionCount = 0,
  });

  @override
  State<_ServerIcon> createState() =>
      _ServerIconState();
}

class _ServerIconState extends State<_ServerIcon> {
  var _isHovered = false;

  Widget _buildBackupIcon(
    BuildContext context, {
    required bool isActive,
  }) {
    final iconColor = isActive
        ? Colors.white
        : context.colors.textPrimary;
    return Center(
      child: widget.svgAsset != null
          ? SvgPicture.asset(
              widget.svgAsset!,
              width: 44,
              height: 44,
            )
          : widget.icon != null
              ? PhosphorIcon(
                  widget.icon!,
                  color: iconColor,
                  size: 32,
                )
              : Text(
                  _abbreviation(widget.label),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        widget.isSelected || _isHovered;
    final borderRadius = isActive ? 13.0 : 22.0;
    final bgColor = isActive
        ? context.colors.brandPrimary
        : context.colors.serverIconBackground;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration:
                const Duration(milliseconds: 70),
            width: 4,
            height: widget.isSelected
                ? 40
                : widget.hasUnread || _isHovered
                    ? 20
                    : 0,
            decoration: BoxDecoration(
              color: context.colors.textPrimary,
              borderRadius:
                  const BorderRadius.only(
                topRight: Radius.circular(999),
                bottomRight: Radius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RightTooltip(
                message: widget.label,
                child: MouseRegion(
                  onEnter: (_) =>
                      setState(() => _isHovered = true),
                  onExit: (_) => setState(
                    () => _isHovered = false,
                  ),
                  child: GestureDetector(
                    onTap: widget.onTap,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 70,
                          ),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius:
                                BorderRadius.circular(
                              borderRadius,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadiusGeometry
                                    .circular(
                              borderRadius,
                            ),
                            child: widget.iconUrl !=
                                    null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        widget
                                            .iconUrl!,
                                    errorWidget: (
                                      context,
                                      url,
                                      error,
                                    ) =>
                                        _buildBackupIcon(
                                      context,
                                      isActive:
                                          isActive,
                                    ),
                                    progressIndicatorBuilder: (
                                      context,
                                      url,
                                      progress,
                                    ) =>
                                        _buildBackupIcon(
                                      context,
                                      isActive:
                                          isActive,
                                    ),
                                  )
                                : _buildBackupIcon(
                                    context,
                                    isActive:
                                        isActive,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!widget.isSelected &&
                  (widget.hasUnread ||
                      widget.mentionCount > 0))
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: UnreadBadge(
                    mentionCount: widget.mentionCount,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _abbreviation(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'
          .toUpperCase();
    }
    return name
        .substring(0, name.length.clamp(0, 2))
        .toUpperCase();
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
  State<_DashedServerIcon> createState() =>
      _DashedServerIconState();
}

class _DashedServerIconState
    extends State<_DashedServerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radiusAnim;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );
    _radiusAnim = Tween<double>(
      begin: 22,
      end: 13,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorAnim = ColorTween(
      begin: context.colors.interactiveMuted,
      end: context.colors.textPrimary,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
    padding: const EdgeInsets.symmetric(
      vertical: 3,
    ),
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
                  child: Center(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: CustomPaint(
                        painter:
                            _DashedBorderPainter(
                          borderRadius:
                              _radiusAnim.value,
                          color:
                              _colorAnim.value ??
                              context.colors
                                  .interactiveMuted,
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            widget.icon,
                            color:
                                _colorAnim.value ??
                                context.colors
                                    .interactiveMuted,
                            size: 24,
                          ),
                        ),
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

  _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
  });

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
        final end = (distance + dashLength)
            .clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(
    _DashedBorderPainter oldDelegate,
  ) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.color != color;
}

class _RightTooltip extends StatefulWidget {
  final String message;
  final Widget child;

  const _RightTooltip({
    required this.message,
    required this.child,
  });

  @override
  State<_RightTooltip> createState() =>
      _RightTooltipState();
}

class _RightTooltipState
    extends State<_RightTooltip> {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;

  void _show() {
    _hide();
    final overlay = Overlay.of(context);
    final bgColor =
        context.colors.backgroundFloating;

    _entry = OverlayEntry(
      builder: (_) => UnconstrainedBox(
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.centerRight,
          followerAnchor:
              Alignment.centerLeft,
          offset: const Offset(4, 0),
          showWhenUnlinked: false,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(5, 10),
                    painter:
                        _TooltipArrowPainter(
                      color: bgColor,
                    ),
                  ),
                  Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 190,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: context
                            .colors.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
  Widget build(BuildContext context) =>
      CompositedTransformTarget(
    link: _layerLink,
    child: MouseRegion(
      onEnter: (_) => _show(),
      onExit: (_) => _hide(),
      child: widget.child,
    ),
  );
}

class _TooltipArrowPainter
    extends CustomPainter {
  final Color color;

  _TooltipArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    _TooltipArrowPainter old,
  ) =>
      old.color != color;
}
