import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/picker_search_input.dart';
import 'package:fluxer_app/features/chat/providers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kDesktopStickerColumns = 4;
const _kMobileStickerColumns = 5;
const _kDesktopStickerCellHeight = 92.0;
const _kMobileStickerCellHeight = 72.0;
const _kDesktopStickerImageSize = 76.0;
const _kMobileStickerImageSize = 64.0;
const _kStickerGridGap = 8.0;
const _kCategoryHeaderHeight = 32.0;
const _kCategoryGap = 8.0;
const _kStickerRequestSize = 160;

typedef OnStickerSelect = void Function(StickerEntry sticker);

class StickerPickerContent extends ConsumerStatefulWidget {
  const StickerPickerContent({
    this.onSelect,
    this.isMobile = false,
    this.searchHorizontalPadding,
    this.searchTopPadding,
    this.searchBottomPadding,
    super.key,
  });

  final OnStickerSelect? onSelect;
  final bool isMobile;
  final double? searchHorizontalPadding;
  final double? searchTopPadding;
  final double? searchBottomPadding;

  @override
  ConsumerState<StickerPickerContent> createState() =>
      _StickerPickerContentState();
}

class _StickerPickerData {
  const _StickerPickerData({
    required this.allStickers,
    required this.frecent,
    required this.stickersByGuild,
  });

  final List<StickerEntry> allStickers;
  final List<StickerEntry> frecent;
  final Map<Guild, List<StickerEntry>> stickersByGuild;
}

class _StickerPickerContentState extends ConsumerState<StickerPickerContent> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _collapsedCategories = <String>{};
  String _searchQuery = '';
  StickerEntry? _hoveredSticker;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _columns =>
      widget.isMobile ? _kMobileStickerColumns : _kDesktopStickerColumns;

  double get _cellHeight =>
      widget.isMobile ? _kMobileStickerCellHeight : _kDesktopStickerCellHeight;

  double get _imageSize =>
      widget.isMobile ? _kMobileStickerImageSize : _kDesktopStickerImageSize;

  EdgeInsets get _gridPadding =>
      EdgeInsets.symmetric(horizontal: widget.isMobile ? 12 : 8);

  double _gridHeightForItemCount(int itemCount) {
    if (itemCount == 0) {
      return 0;
    }
    final rows = (itemCount / _columns).ceil();
    return rows * _cellHeight + (rows - 1) * _kStickerGridGap;
  }

  _StickerPickerData _watchPickerData() {
    final guilds = ref.watch(guildListViewModelProvider).guilds;
    final activeGuildId = ref.watch(activeGuildIdProvider);
    final isPremium = ref.watch(currentUserPremiumTypeProvider) > 0;
    final allStickers =
        ref.watch(allGuildStickersForPickerProvider).value ?? const [];
    final frecent = ref.watch(frecentStickersProvider).value ?? const [];
    final stickersByGuild = guildStickerEntriesForPicker(
      guilds: guilds,
      stickers: allStickers,
      activeGuildId: activeGuildId,
      isPremium: isPremium,
    );
    final visibleStickerIds = stickersByGuild.values
        .expand((stickers) => stickers)
        .map((sticker) => sticker.id)
        .toSet();

    return _StickerPickerData(
      allStickers: allStickers,
      frecent: frecent
          .where((sticker) => visibleStickerIds.contains(sticker.id))
          .toList(growable: false),
      stickersByGuild: stickersByGuild,
    );
  }

  Map<Guild, List<StickerEntry>> _readStickersByGuild() {
    final guilds = ref.read(guildListViewModelProvider).guilds;
    final activeGuildId = ref.read(activeGuildIdProvider);
    final isPremium = ref.read(currentUserPremiumTypeProvider) > 0;
    final stickers = ref.read(allGuildStickersForPickerProvider).value ?? [];
    return guildStickerEntriesForPicker(
      guilds: guilds,
      stickers: stickers,
      activeGuildId: activeGuildId,
      isPremium: isPremium,
    );
  }

  void _scrollToCategory(String category) {
    final frecent = ref.read(frecentStickersProvider).value ?? [];
    final stickersByGuild = _readStickersByGuild();

    if (category == 'frequently-used') {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      );
      return;
    }

    var offset = 0.0;
    if (frecent.isNotEmpty) {
      offset += _kCategoryHeaderHeight;
      if (!_collapsedCategories.contains('frequently-used')) {
        offset += _gridHeightForItemCount(frecent.length);
      }
      offset += _kCategoryGap;
    }

    for (final entry in stickersByGuild.entries) {
      final key = 'guild-${entry.key.id}';
      if (key == category) {
        unawaited(
          _scrollController.animateTo(
            offset.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        );
        return;
      }
      offset += _kCategoryGap + _kCategoryHeaderHeight;
      if (!_collapsedCategories.contains(key)) {
        offset += _gridHeightForItemCount(entry.value.length);
      }
    }
  }

  Future<void> _selectSticker(StickerEntry sticker) async {
    await ref
        .read(fluxerDatabaseProvider)
        .emojiUsageDao
        .trackUsage(sticker.frecencyKey);
    ref.invalidate(frecentStickersProvider);
    widget.onSelect?.call(sticker);
  }

  void _setHoveredSticker(StickerEntry? sticker) {
    if (widget.isMobile) {
      return;
    }
    setState(() => _hoveredSticker = sticker);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final data = _watchPickerData();

    return Column(
      children: [
        PickerSearchInput(
          controller: _searchController,
          hintText: _hoveredSticker?.name ?? 'Find the perfect sticker',
          horizontalPadding: widget.searchHorizontalPadding ?? 12,
          topPadding: widget.searchTopPadding ?? (widget.isMobile ? 8 : 12),
          bottomPadding:
              widget.searchBottomPadding ?? (widget.isMobile ? 4 : 12),
        ),
        Expanded(child: _buildBody(context, colors, data)),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    FluxerColorTheme colors,
    _StickerPickerData data,
  ) {
    if (data.allStickers.isEmpty) {
      return const _StickerEmptyState(
        icon: PhosphorIconsDuotone.sticker,
        title: 'No Stickers Available',
        description: 'Join a community with stickers to get started!',
      );
    }

    final visibleStickers = data.stickersByGuild.values.expand((e) => e);
    if (visibleStickers.isEmpty) {
      return const _StickerEmptyState(
        icon: PhosphorIconsDuotone.sticker,
        title: 'No Stickers Available',
        description: 'No stickers are available in this conversation.',
      );
    }
    if (_searchQuery.trim().isNotEmpty) {
      return _buildSearchResults(
        context,
        colors,
        searchStickerEntries(visibleStickers, _searchQuery),
      );
    }

    final content = _buildCategoryGrid(context, colors, data);
    if (widget.isMobile) {
      return Column(
        children: [
          Expanded(child: content),
          _buildMobileCategoryBar(context, colors, data),
        ],
      );
    }

    return Row(
      children: [
        _buildDesktopCategorySidebar(context, colors, data),
        Expanded(
          child: Column(
            children: [
              Expanded(child: content),
              _buildInspector(context, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    FluxerColorTheme colors,
    List<StickerEntry> stickers,
  ) {
    if (stickers.isEmpty) {
      return const _StickerEmptyState(
        icon: PhosphorIconsDuotone.smileySad,
        title: 'No Stickers Found',
        description: 'Try a different search term',
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: _gridPadding.copyWith(top: 0, bottom: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisExtent: _cellHeight,
        crossAxisSpacing: _kStickerGridGap,
        mainAxisSpacing: _kStickerGridGap,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) =>
          _buildStickerCell(stickers[index], colors),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    FluxerColorTheme colors,
    _StickerPickerData data,
  ) {
    final guildEntries = data.stickersByGuild.entries.toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox.shrink()),
        if (data.frecent.isNotEmpty) ...[
          SliverPadding(
            padding: _gridPadding,
            sliver: SliverToBoxAdapter(
              child: _buildCategoryHeader('frequently-used', colors),
            ),
          ),
          if (!_collapsedCategories.contains('frequently-used'))
            SliverPadding(
              padding: _gridPadding,
              sliver: _buildStickerGridSliver(data.frecent, colors),
            ),
        ],
        for (final entry in guildEntries) ...[
          const SliverToBoxAdapter(child: SizedBox(height: _kCategoryGap)),
          SliverPadding(
            padding: _gridPadding,
            sliver: SliverToBoxAdapter(
              child: _buildCategoryHeader(
                'guild-${entry.key.id}',
                colors,
                labelOverride: entry.key.name,
                guild: entry.key,
              ),
            ),
          ),
          if (!_collapsedCategories.contains('guild-${entry.key.id}'))
            SliverPadding(
              padding: _gridPadding,
              sliver: _buildStickerGridSliver(entry.value, colors),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
      ],
    );
  }

  SliverGrid _buildStickerGridSliver(
    List<StickerEntry> stickers,
    FluxerColorTheme colors,
  ) => SliverGrid(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _columns,
      mainAxisExtent: _cellHeight,
      crossAxisSpacing: _kStickerGridGap,
      mainAxisSpacing: _kStickerGridGap,
    ),
    delegate: SliverChildBuilderDelegate(
      (context, index) => _buildStickerCell(stickers[index], colors),
      childCount: stickers.length,
      addAutomaticKeepAlives: false,
    ),
  );

  Widget _buildCategoryHeader(
    String category,
    FluxerColorTheme colors, {
    String? labelOverride,
    Guild? guild,
  }) {
    final isCollapsed = _collapsedCategories.contains(category);
    final label =
        labelOverride ?? FluxerLocalizations.of(context).emojiFrequentlyUsed;
    final leadingIcon = guild != null
        ? _StickerGuildIcon(guild: guild, size: 16)
        : category == 'frequently-used'
        ? PhosphorIcon(
            PhosphorIconsFill.clock,
            size: 16,
            color: colors.textPrimaryMuted,
          )
        : null;

    return GestureDetector(
      onTap: () => setState(() {
        if (isCollapsed) {
          _collapsedCategories.remove(category);
        } else {
          _collapsedCategories.add(category);
        }
      }),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _kCategoryHeaderHeight,
        child: Row(
          children: [
            if (leadingIcon != null) ...[leadingIcon, const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimaryMuted,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: PhosphorIcon(
                PhosphorIconsBold.caretDown,
                size: 12,
                color: colors.textPrimaryMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerCell(StickerEntry sticker, FluxerColorTheme colors) {
    final isHovered = _hoveredSticker?.id == sticker.id;
    final content = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHovered
            ? colors.backgroundModifierSelected
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CachedNetworkImage(
        imageUrl: sticker.urlForSize(_kStickerRequestSize),
        cacheKey: sticker.cacheKeyForSize(_kStickerRequestSize),
        width: _imageSize,
        height: _imageSize,
        memCacheWidth: _imageSize.toInt(),
        memCacheHeight: _imageSize.toInt(),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        fit: BoxFit.contain,
        placeholder: (_, _) => SizedBox(width: _imageSize, height: _imageSize),
        errorBuilder: (_, _, _) => Icon(
          PhosphorIconsDuotone.sticker,
          size: 36,
          color: colors.textTertiaryMuted,
        ),
      ),
    );

    return GestureDetector(
      onTap: () => unawaited(_selectSticker(sticker)),
      child: widget.isMobile
          ? content
          : MouseRegion(
              onEnter: (_) => _setHoveredSticker(sticker),
              onExit: (_) => _setHoveredSticker(null),
              child: content,
            ),
    );
  }

  Widget _buildDesktopCategorySidebar(
    BuildContext context,
    FluxerColorTheme colors,
    _StickerPickerData data,
  ) => Container(
    width: 46,
    decoration: BoxDecoration(
      color: colors.backgroundPrimary,
      border: Border(right: BorderSide(color: colors.backgroundModifierAccent)),
    ),
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (data.frecent.isNotEmpty)
          _StickerCategoryButton(
            icon: PhosphorIconsFill.clock,
            onTap: () => _scrollToCategory('frequently-used'),
          ),
        ...data.stickersByGuild.keys.map(
          (guild) => _StickerGuildCategoryButton(
            guild: guild,
            onTap: () => _scrollToCategory('guild-${guild.id}'),
          ),
        ),
      ],
    ),
  );

  Widget _buildMobileCategoryBar(
    BuildContext context,
    FluxerColorTheme colors,
    _StickerPickerData data,
  ) => Container(
    height: 44,
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: colors.backgroundModifierAccent)),
    ),
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (data.frecent.isNotEmpty)
          _StickerCategoryButton(
            icon: PhosphorIconsFill.clock,
            onTap: () => _scrollToCategory('frequently-used'),
          ),
        ...data.stickersByGuild.keys.map(
          (guild) => _StickerGuildCategoryButton(
            guild: guild,
            onTap: () => _scrollToCategory('guild-${guild.id}'),
          ),
        ),
      ],
    ),
  );

  Widget _buildInspector(BuildContext context, FluxerColorTheme colors) {
    final sticker = _hoveredSticker;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        border: Border(top: BorderSide(color: colors.backgroundModifierAccent)),
      ),
      child: Row(
        children: [
          if (sticker != null) ...[
            CachedNetworkImage(
              imageUrl: sticker.urlForSize(_kStickerRequestSize),
              cacheKey: sticker.cacheKeyForSize(_kStickerRequestSize),
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ':${sticker.name}:',
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StickerCategoryButton extends StatelessWidget {
  const _StickerCategoryButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: PhosphorIcon(
          icon,
          size: 24,
          color: context.colors.textPrimaryMuted,
        ),
      ),
    ),
  );
}

class _StickerGuildCategoryButton extends StatelessWidget {
  const _StickerGuildCategoryButton({required this.guild, required this.onTap});

  final Guild guild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      width: 36,
      height: 36,
      child: Center(child: _StickerGuildIcon(guild: guild, size: 24)),
    ),
  );
}

class _StickerGuildIcon extends StatelessWidget {
  const _StickerGuildIcon({required this.guild, required this.size});

  final Guild guild;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconUrl = guild.iconUrl;

    if (iconUrl == null) {
      return _StickerGuildInitial(name: guild.name, colors: colors, size: size);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: iconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _StickerGuildInitial(name: guild.name, colors: colors, size: size),
      ),
    );
  }
}

class _StickerGuildInitial extends StatelessWidget {
  const _StickerGuildInitial({
    required this.name,
    required this.colors,
    required this.size,
  });

  final String name;
  final FluxerColorTheme colors;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colors.backgroundSecondary,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: size <= 16 ? 8 : 11,
        fontWeight: FontWeight.w600,
        color: colors.textPrimaryMuted,
      ),
    ),
  );
}

class _StickerEmptyState extends StatelessWidget {
  const _StickerEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 42,
              color: colors.textPrimaryMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimaryMuted.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
