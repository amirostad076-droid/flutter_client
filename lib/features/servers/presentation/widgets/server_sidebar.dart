import 'dart:async';
import 'dart:math';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxeron/core/constants/assets.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/providers/unread_provider.dart';
import 'package:fluxeron/features/servers/domain/server.dart';
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
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(scrollbars: false),
        child: ListView(
          physics:
              const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
          top: max(
            MediaQuery.of(context).padding.top,
            4,
          ),
          bottom: 8,
        ),
        children: [
          _ServerIcon(
            label: 'Direct Messages',
            isSelected: isDm,
            svgAsset: Assets.fluxerSymbol,
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
          _SidebarDivider(
            color:
                context.colors.backgroundModifierHover,
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
                  server: server,
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
          _SidebarDivider(
            color:
                context.colors.backgroundModifierHover,
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
      ),
    );
  }
}

class _ServerIcon extends StatefulWidget {
  final String label;
  final Server? server;
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
    this.server,
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
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(
                iconColor,
                BlendMode.srcIn,
              ),
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
    final hasImage = widget.iconUrl != null;
    final bgColor = hasImage
        ? Colors.transparent
        : isActive
            ? context.colors.brandPrimary
            : context.colors.serverIconBackground;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration:
                const Duration(milliseconds: 200),
            curve:
                const Cubic(0.25, 0.1, 0.25, 1),
            width: 6,
            height: widget.isSelected
                ? 40
                : _isHovered
                    ? 20
                    : widget.hasUnread
                        ? 8
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
          const SizedBox(width: 6),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RightTooltip(
                content: widget.server != null
                    ? _GuildTooltipContent(
                        server: widget.server!,
                      )
                    : _TooltipLabel(
                        label: widget.label,
                      ),
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
                          curve: Curves.easeOut,
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
          content: _TooltipLabel(
            label: widget.label,
          ),
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
                            size: 20,
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
      ..strokeWidth = 2
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
  final Widget content;
  final Widget child;

  const _RightTooltip({
    required this.content,
    required this.child,
  });

  @override
  State<_RightTooltip> createState() =>
      _RightTooltipState();
}

class _RightTooltipState
    extends State<_RightTooltip>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 100),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(
      begin: 0.98,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _show() {
    if (_entry != null) {
      return;
    }
    final overlay = Overlay.of(context);
    final bgColor =
        context.colors.backgroundPrimary;
    final borderColor =
        context.colors.backgroundHeaderSecondary;

    _entry = OverlayEntry(
      builder: (_) => UnconstrainedBox(
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.centerRight,
          followerAnchor:
              Alignment.centerLeft,
          offset: const Offset(8, 0),
          showWhenUnlinked: false,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment:
                    Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth:
                          350 + _kArrowWidth,
                    ),
                    child: CustomPaint(
                      painter:
                          _TooltipShapePainter(
                        fillColor: bgColor,
                        borderColor:
                            borderColor,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(
                          left:
                              _kArrowWidth + 16,
                          right: 16,
                          top: 12,
                          bottom: 12,
                        ),
                        child: widget.content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    unawaited(_animController.forward());
  }

  void _hide() {
    if (_entry == null) {
      return;
    }
    unawaited(
      _animController.reverse().then((_) {
        _entry?.remove();
        _entry = null;
      }),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _entry?.remove();
    _entry = null;
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

class _SidebarDivider extends StatelessWidget {
  final Color color;

  const _SidebarDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

class _TooltipLabel extends StatelessWidget {
  final String label;

  const _TooltipLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GuildTooltipContent extends StatelessWidget {
  final Server server;

  const _GuildTooltipContent({
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (server.isPartnered ||
              server.isVerified) ...[
            _GuildBadge(
              isPartnered: server.isPartnered,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              server.name,
              style: TextStyle(
                color:
                    context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuildBadge extends StatelessWidget {
  final bool isPartnered;

  const _GuildBadge({
    required this.isPartnered,
  });

  @override
  Widget build(BuildContext context) {
    if (isPartnered) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: context.colors.brandPrimary,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: PhosphorIcon(
            PhosphorIconsBold.infinity,
            color: Colors.white,
            size: 10,
          ),
        ),
      );
    }
    return PhosphorIcon(
      PhosphorIconsFill.sealCheck,
      color: context.colors.textPrimary,
      size: 16,
    );
  }
}

const double _kArrowWidth = 5;
const double _kArrowHeight = 10;
const double _kBorderRadius = 8;

class _TooltipShapePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _TooltipShapePainter({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const r = _kBorderRadius;
    const left = _kArrowWidth;
    final centerY = size.height / 2;
    final arrowTop = centerY - _kArrowHeight / 2;
    final arrowBottom =
        centerY + _kArrowHeight / 2;

    final path = Path()
      // Top-left corner
      ..moveTo(left + r, 0)
      // Top edge → top-right corner
      ..lineTo(size.width - r, 0)
      ..arcToPoint(
        Offset(size.width, r),
        radius: const Radius.circular(r),
      )
      // Right edge → bottom-right corner
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: const Radius.circular(r),
      )
      // Bottom edge → bottom-left corner
      ..lineTo(left + r, size.height)
      ..arcToPoint(
        Offset(left, size.height - r),
        radius: const Radius.circular(r),
      )
      // Left edge down to arrow
      ..lineTo(left, arrowBottom)
      // Arrow pointing left
      ..lineTo(0, centerY)
      ..lineTo(left, arrowTop)
      // Left edge up to top-left corner
      ..lineTo(left, r)
      ..arcToPoint(
        const Offset(left + r, 0),
        radius: const Radius.circular(r),
      )
      ..close();

    canvas
      ..drawPath(
        path,
        Paint()..color = fillColor,
      )
      ..drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(
    _TooltipShapePainter old,
  ) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor;
}
