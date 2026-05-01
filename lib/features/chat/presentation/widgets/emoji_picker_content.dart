import 'dart:async';
import 'dart:math';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/plutonium_upsell_banner.dart';
import 'package:fluxer_app/features/chat/providers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/chat/utils/emoji_picker_rendering_policy.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/utils/emoji_registry.dart';
import 'package:fluxer_app/shared/utils/emoji_sprite_sheet.dart';
import 'package:fluxer_app/shared/utils/emoji_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kGridColumns = 9;
const _kMobileGridColumns = 8;
const _kEmojiSize = 40.0;
const _kCellSize = 48.0;
const _kCustomEmojiRequestSize = 48;

const Map<String, IconData> _kCategoryIcons = {
  'people': PhosphorIconsFill.smiley,
  'nature': PhosphorIconsFill.leaf,
  'food': PhosphorIconsFill.bowlFood,
  'activity': PhosphorIconsFill.gameController,
  'travel': PhosphorIconsFill.bicycle,
  'objects': PhosphorIconsFill.magnet,
  'symbols': PhosphorIconsFill.heart,
  'flags': PhosphorIconsFill.flag,
};

String _categoryLabel(String category, FluxerLocalizations l10n) =>
    switch (category) {
      'people' => l10n.emojiCategoryPeople,
      'nature' => l10n.emojiCategoryNature,
      'food' => l10n.emojiCategoryFood,
      'activity' => l10n.emojiCategoryActivity,
      'travel' => l10n.emojiCategoryTravel,
      'objects' => l10n.emojiCategoryObjects,
      'symbols' => l10n.emojiCategorySymbols,
      'flags' => l10n.emojiCategoryFlags,
      _ => category,
    };

typedef OnEmojiSelect = void Function(String name, String surrogates);

class EmojiPickerContent extends ConsumerStatefulWidget {
  const EmojiPickerContent({
    this.onSelect,
    this.onHoveredEmojiChanged,
    this.searchQuery = '',
    this.skinTone = '',
    this.isMobile = false,
    super.key,
  });

  final OnEmojiSelect? onSelect;
  final ValueChanged<String?>? onHoveredEmojiChanged;
  final String searchQuery;
  final String skinTone;
  final bool isMobile;

  @override
  ConsumerState<EmojiPickerContent> createState() => _EmojiPickerContentState();
}

class _EmojiPickerData {
  const _EmojiPickerData({
    required this.guilds,
    required this.activeGuildId,
    required this.isPremium,
    required this.allGuildEmojis,
    required this.frecent,
    required this.guildEmojisByGuild,
  });

  final List<Guild> guilds;
  final String? activeGuildId;
  final bool isPremium;
  final List<GuildEmojiEntry> allGuildEmojis;
  final List<EmojiEntry> frecent;
  final Map<Guild, List<GuildEmojiEntry>> guildEmojisByGuild;
}

class _EmojiPickerContentState extends ConsumerState<EmojiPickerContent> {
  final _scrollController = ScrollController();
  String? _hoveredEmojiName;
  final _collapsedCategories = <String>{};

  GuildEmojiEntry? _hoveredCustomEmoji;
  var _isFirstFrameSettled = false;

  late final int _upsellPreviewSeed;

  @override
  void initState() {
    super.initState();
    _upsellPreviewSeed = Random().nextInt(0x7fffffff);
    _preloadSkinToneSpriteSheet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isFirstFrameSettled = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant EmojiPickerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skinTone != widget.skinTone) {
      _preloadSkinToneSpriteSheet();
    }
  }

  void _preloadSkinToneSpriteSheet() {
    unawaited(EmojiSpriteSheet.preload());
    if (widget.skinTone.isNotEmpty) {
      unawaited(EmojiSpriteSheet.preload(skinTone: widget.skinTone));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _columns => widget.isMobile ? _kMobileGridColumns : _kGridColumns;

  void _setHoveredEmoji(String? name, {GuildEmojiEntry? customEmoji}) {
    setState(() {
      _hoveredEmojiName = name;
      _hoveredCustomEmoji = customEmoji;
    });
    widget.onHoveredEmojiChanged?.call(name);
  }

  void _onEmojiSelected(EmojiEntry emoji) {
    final hasTone = widget.skinTone.isNotEmpty && emoji.hasDiversity;
    final surrogates = hasTone
        ? emoji.surrogates + widget.skinTone
        : emoji.surrogates;
    unawaited(
      ref
          .read(fluxerDatabaseProvider)
          .emojiUsageDao
          .trackUsage('unicode:${emoji.primaryName}'),
    );
    ref.invalidate(frecentEmojisProvider);
    widget.onSelect?.call(emoji.primaryName, surrogates);
  }

  void _onCustomEmojiSelected(GuildEmojiEntry emoji) {
    unawaited(
      ref
          .read(fluxerDatabaseProvider)
          .emojiUsageDao
          .trackUsage('custom:${emoji.guildId}:${emoji.id}'),
    );
    ref.invalidate(frecentEmojisProvider);
    widget.onSelect?.call(emoji.name, emoji.markdown);
  }

  _EmojiPickerData _watchPickerData() {
    final guilds = ref.watch(guildListViewModelProvider).guilds;
    final activeGuildId = ref.watch(activeGuildIdProvider);
    final isPremium = ref.watch(currentUserPremiumTypeProvider) > 0;
    final allGuildEmojis =
        ref.watch(allGuildEmojisForPickerProvider).value ?? const [];
    final frecent = ref.watch(frecentEmojisProvider).value ?? const [];
    final guildEmojisByGuild = guildEmojiEntriesForPicker(
      guilds: guilds,
      emojis: allGuildEmojis,
      activeGuildId: activeGuildId,
      isPremium: isPremium,
    );

    return _EmojiPickerData(
      guilds: guilds,
      activeGuildId: activeGuildId,
      isPremium: isPremium,
      allGuildEmojis: allGuildEmojis,
      frecent: frecent,
      guildEmojisByGuild: guildEmojisByGuild,
    );
  }

  Map<Guild, List<GuildEmojiEntry>> _readGuildEmojisByGuild() {
    final guilds = ref.read(guildListViewModelProvider).guilds;
    final activeGuildId = ref.read(activeGuildIdProvider);
    final isPremium = ref.read(currentUserPremiumTypeProvider) > 0;

    final emojis = ref.read(allGuildEmojisForPickerProvider).value ?? const [];
    return guildEmojiEntriesForPicker(
      guilds: guilds,
      emojis: emojis,
      activeGuildId: activeGuildId,
      isPremium: isPremium,
    );
  }

  void _scrollToCategory(String category) {
    final categories = EmojiRegistry.categories;
    final frecent = ref.read(frecentEmojisProvider).value ?? [];
    final guildEmojisByGuild = _readGuildEmojisByGuild();

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

    double offset = 0;

    if (frecent.isNotEmpty) {
      offset += 26;
      if (!_collapsedCategories.contains('frequently-used')) {
        offset += (frecent.length / _columns).ceil() * _kCellSize;
      }
      offset += 12;
    }

    for (final entry in guildEmojisByGuild.entries) {
      final guildKey = 'guild-${entry.key.id}';
      if (category == guildKey) {
        unawaited(
          _scrollController.animateTo(
            offset.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        );
        return;
      }
      offset += 12 + 26;
      if (!_collapsedCategories.contains(guildKey)) {
        offset += (entry.value.length / _columns).ceil() * _kCellSize;
      }
    }

    for (final cat in kEmojiCategoryOrder) {
      if (cat == category) {
        break;
      }
      final emojis = categories[cat];
      if (emojis == null || emojis.isEmpty) {
        continue;
      }
      offset += 12 + 26;
      if (!_collapsedCategories.contains(cat)) {
        offset += (emojis.length / _columns).ceil() * _kCellSize;
      }
    }

    unawaited(
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final data = _watchPickerData();

    if (widget.isMobile) {
      return Column(
        children: [
          Expanded(child: _buildEmojiGrid(context, colors, data)),
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
              Expanded(child: _buildEmojiGrid(context, colors, data)),
              _buildInspector(context, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpsellBanner(BuildContext context, _EmojiPickerData data) {
    final lockedGuilds = data.guilds
        .where((guild) => guild.id != data.activeGuildId)
        .toList();
    if (lockedGuilds.isEmpty) {
      return const SizedBox.shrink();
    }
    final allLockedEmojis = lockedGuildEmojiEntriesForUpsell(
      guilds: data.guilds,
      emojis: data.allGuildEmojis,
      activeGuildId: data.activeGuildId,
      isPremium: data.isPremium,
    );
    if (allLockedEmojis.isEmpty) {
      return const SizedBox.shrink();
    }
    final previewEmojis = pickRandomItems<GuildEmojiEntry>(
      allLockedEmojis,
      4,
      _upsellPreviewSeed,
    );
    return PlutoniumUpsellBanner(
      lockedEmojiCount: allLockedEmojis.length,
      lockedGuilds: lockedGuilds,
      previewEmojis: previewEmojis,
    );
  }

  Widget _buildEmojiGrid(
    BuildContext context,
    FluxerColorTheme colors,
    _EmojiPickerData data,
  ) {
    if (widget.searchQuery.isNotEmpty) {
      return _buildSearchResults(context, colors, data);
    }
    return _buildCategoryGrid(context, colors, data);
  }

  Widget _buildSearchResults(
    BuildContext context,
    FluxerColorTheme colors,
    _EmojiPickerData data,
  ) {
    final unicodeResults = EmojiRegistry.search(widget.searchQuery);
    final guildEmojis = data.guildEmojisByGuild.values.expand((e) => e);
    final query = widget.searchQuery.toLowerCase();
    final customResults = guildEmojis
        .where((e) => e.name.toLowerCase().contains(query))
        .toList();

    if (unicodeResults.isEmpty && customResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsDuotone.smileySad,
              size: 42,
              color: colors.textPrimaryMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              FluxerLocalizations.of(context).emojiSearchEmpty,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimaryMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    final totalCount = customResults.length + unicodeResults.length;
    return GridView.builder(
      controller: _scrollController,
      cacheExtent: emojiPickerCacheExtent(rowHeight: _kCellSize),
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisExtent: _kCellSize,
      ),
      itemCount: totalCount,
      itemBuilder: (context, i) {
        if (i < customResults.length) {
          return _buildCustomEmojiCell(customResults[i], colors);
        }
        return _buildEmojiCell(
          unicodeResults[i - customResults.length],
          colors,
        );
      },
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    FluxerColorTheme colors,
    _EmojiPickerData data,
  ) {
    final categories = EmojiRegistry.categories;
    final hasFrecent = data.frecent.isNotEmpty;
    final guildEntries = data.guildEmojisByGuild.entries.toList();
    final shouldBuildUpsell = emojiPickerShouldBuildUpsell(
      isPremium: data.isPremium,
      hasSearchQuery: widget.searchQuery.isNotEmpty,
      isFirstFrameSettled: _isFirstFrameSettled,
    );

    return CustomScrollView(
      controller: _scrollController,
      cacheExtent: emojiPickerCacheExtent(rowHeight: _kCellSize),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        if (shouldBuildUpsell)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverToBoxAdapter(
              child: _buildUpsellBanner(context, data),
            ),
          ),
        if (hasFrecent) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverToBoxAdapter(
              child: _buildCategoryHeader('frequently-used', colors),
            ),
          ),
          if (!_collapsedCategories.contains('frequently-used'))
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: _buildUnicodeEmojiGridSliver(data.frecent, colors),
            ),
        ],
        for (final entry in guildEntries) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverToBoxAdapter(
              child: _buildCategoryHeader(
                'guild-${entry.key.id}',
                colors,
                labelOverride: entry.key.name,
              ),
            ),
          ),
          if (!_collapsedCategories.contains('guild-${entry.key.id}'))
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: _buildCustomEmojiGridSliver(entry.value, colors),
            ),
        ],
        for (final category in kEmojiCategoryOrder)
          if (categories[category]?.isNotEmpty ?? false) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverToBoxAdapter(
                child: _buildCategoryHeader(category, colors),
              ),
            ),
            if (!_collapsedCategories.contains(category))
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: _buildUnicodeEmojiGridSliver(
                  categories[category]!,
                  colors,
                ),
              ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
      ],
    );
  }

  SliverGrid _buildUnicodeEmojiGridSliver(
    List<EmojiEntry> emojis,
    FluxerColorTheme colors,
  ) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisExtent: _kCellSize,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildEmojiCell(emojis[index], colors),
        childCount: emojis.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  SliverGrid _buildCustomEmojiGridSliver(
    List<GuildEmojiEntry> emojis,
    FluxerColorTheme colors,
  ) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisExtent: _kCellSize,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildCustomEmojiCell(emojis[index], colors),
        childCount: emojis.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget _buildCategoryHeader(
    String category,
    FluxerColorTheme colors, {
    String? labelOverride,
  }) {
    final l10n = FluxerLocalizations.of(context);
    final isCollapsed = _collapsedCategories.contains(category);
    final label =
        labelOverride ??
        (category == 'frequently-used'
            ? l10n.emojiFrequentlyUsed
            : _categoryLabel(category, l10n));

    return GestureDetector(
      onTap: () => setState(() {
        if (isCollapsed) {
          _collapsedCategories.remove(category);
        } else {
          _collapsedCategories.add(category);
        }
      }),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
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

  Widget _buildEmojiCell(EmojiEntry emoji, FluxerColorTheme colors) {
    final hasTone = widget.skinTone.isNotEmpty && emoji.hasDiversity;
    final usesHover = emojiPickerUsesHoverTracking(isMobile: widget.isMobile);
    final content = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            usesHover &&
                _hoveredEmojiName == emoji.primaryName &&
                _hoveredCustomEmoji == null
            ? colors.backgroundModifierSelected
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: hasTone
          ? SpriteEmoji(
              index: emoji.spriteIndex,
              diversityIndex: emoji.diversityIndex,
              size: _kEmojiSize,
              skinTone: widget.skinTone,
            )
          : SpriteEmoji(index: emoji.spriteIndex, size: _kEmojiSize),
    );

    return GestureDetector(
      onTap: () => _onEmojiSelected(emoji),
      child: usesHover
          ? MouseRegion(
              onEnter: (_) => _setHoveredEmoji(emoji.primaryName),
              onExit: (_) => _setHoveredEmoji(null),
              child: content,
            )
          : content,
    );
  }

  Widget _buildCustomEmojiCell(GuildEmojiEntry emoji, FluxerColorTheme colors) {
    final usesHover = emojiPickerUsesHoverTracking(isMobile: widget.isMobile);
    final content = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: usesHover && _hoveredCustomEmoji?.id == emoji.id
            ? colors.backgroundModifierSelected
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _RetryEmojiImage(
        key: ValueKey(emoji.id),
        emojiId: emoji.id,
        animated: emoji.animated,
        baseRequestSize: _kCustomEmojiRequestSize,
        size: _kEmojiSize,
      ),
    );

    return GestureDetector(
      onTap: () => _onCustomEmojiSelected(emoji),
      child: usesHover
          ? MouseRegion(
              onEnter: (_) => _setHoveredEmoji(emoji.name, customEmoji: emoji),
              onExit: (_) => _setHoveredEmoji(null),
              child: content,
            )
          : content,
    );
  }

  Widget _buildDesktopCategorySidebar(
    BuildContext context,
    FluxerColorTheme colors,
    _EmojiPickerData data,
  ) {
    final l10n = FluxerLocalizations.of(context);

    return Container(
      width: 46,
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        border: Border(
          right: BorderSide(color: colors.backgroundModifierAccent),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (data.frecent.isNotEmpty)
            _CategoryButton(
              icon: PhosphorIconsFill.clock,
              tooltip: l10n.emojiFrequentlyUsed,
              onTap: () => _scrollToCategory('frequently-used'),
            ),
          ...data.guildEmojisByGuild.keys.map(
            (guild) => _GuildCategoryButton(
              guild: guild,
              onTap: () => _scrollToCategory('guild-${guild.id}'),
            ),
          ),
          ...kEmojiCategoryOrder.map((cat) {
            final icon = _kCategoryIcons[cat];
            if (icon == null) {
              return const SizedBox.shrink();
            }
            return _CategoryButton(
              icon: icon,
              tooltip: _categoryLabel(cat, l10n),
              onTap: () => _scrollToCategory(cat),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCategoryBar(
    BuildContext context,
    FluxerColorTheme colors,
    _EmojiPickerData data,
  ) {
    final l10n = FluxerLocalizations.of(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.backgroundModifierAccent)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          if (data.frecent.isNotEmpty)
            _CategoryButton(
              icon: PhosphorIconsFill.clock,
              tooltip: l10n.emojiFrequentlyUsed,
              onTap: () => _scrollToCategory('frequently-used'),
            ),
          ...data.guildEmojisByGuild.keys.map(
            (guild) => _GuildCategoryButton(
              guild: guild,
              onTap: () => _scrollToCategory('guild-${guild.id}'),
            ),
          ),
          ...kEmojiCategoryOrder.map((cat) {
            final icon = _kCategoryIcons[cat];
            if (icon == null) {
              return const SizedBox.shrink();
            }
            return _CategoryButton(
              icon: icon,
              tooltip: _categoryLabel(cat, l10n),
              onTap: () => _scrollToCategory(cat),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInspector(BuildContext context, FluxerColorTheme colors) {
    final customEmoji = _hoveredCustomEmoji;
    final name = _hoveredEmojiName;

    // Custom emoji hovered
    if (customEmoji != null) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          border: Border(
            top: BorderSide(color: colors.backgroundModifierAccent),
          ),
        ),
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: customEmoji.urlForSize(_kCustomEmojiRequestSize),
              cacheKey: customEmoji.cacheKeyForSize(_kCustomEmojiRequestSize),
              width: 32,
              height: 32,
              memCacheWidth: 32,
              memCacheHeight: 32,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              fit: BoxFit.contain,
              placeholder: (_, _) => const SizedBox(width: 32, height: 32),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ':${customEmoji.name}:',
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Unicode emoji hovered
    final emoji = name != null
        ? EmojiRegistry.allEmojis
              .where((e) => e.primaryName == name)
              .firstOrNull
        : null;
    final hasTone =
        widget.skinTone.isNotEmpty && (emoji?.hasDiversity ?? false);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        border: Border(top: BorderSide(color: colors.backgroundModifierAccent)),
      ),
      child: Row(
        children: [
          if (emoji != null) ...[
            if (hasTone)
              SpriteEmoji(
                index: emoji.spriteIndex,
                diversityIndex: emoji.diversityIndex,
                size: 32,
                skinTone: widget.skinTone,
              )
            else
              SpriteEmoji(index: emoji.spriteIndex, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ':${emoji.primaryName}:',
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

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
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

class _GuildCategoryButton extends StatelessWidget {
  const _GuildCategoryButton({required this.guild, required this.onTap});

  final Guild guild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconUrl = guild.iconUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: iconUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: iconUrl,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _GuildInitial(name: guild.name, colors: colors),
                  ),
                )
              : _GuildInitial(name: guild.name, colors: colors),
        ),
      ),
    );
  }
}

class _GuildInitial extends StatelessWidget {
  const _GuildInitial({required this.name, required this.colors});

  final String name;
  final FluxerColorTheme colors;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: colors.backgroundSecondary,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.textPrimaryMuted,
      ),
    ),
  );
}

class _RetryEmojiImage extends StatefulWidget {
  const _RetryEmojiImage({
    required this.emojiId,
    required this.animated,
    required this.baseRequestSize,
    required this.size,
    super.key,
  });

  final String emojiId;
  final bool animated;
  final int baseRequestSize;
  final double size;

  @override
  State<_RetryEmojiImage> createState() => _RetryEmojiImageState();
}

class _RetryEmojiImageState extends State<_RetryEmojiImage> {
  static const _kMaxRetries = 3;
  static const _kBaseDelay = Duration(milliseconds: 500);

  int _attempt = 0;
  int _cacheBuster = 0;
  Timer? _retryTimer;
  bool _retryScheduled = false;

  @override
  void didUpdateWidget(covariant _RetryEmojiImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emojiId != widget.emojiId ||
        oldWidget.animated != widget.animated ||
        oldWidget.baseRequestSize != widget.baseRequestSize) {
      _resetRetryState();
    }
  }

  void _onError() {
    if (_attempt >= _kMaxRetries || !mounted || _retryScheduled) {
      return;
    }
    _retryScheduled = true;
    unawaited(
      CachedNetworkImage.evictFromCache(_imageUrl, cacheKey: _cacheKey),
    );
    final delay = _kBaseDelay * (1 << _attempt);
    _retryTimer = Timer(delay, () {
      _retryScheduled = false;
      if (!mounted) {
        return;
      }
      setState(() {
        _attempt++;
        _cacheBuster++;
      });
    });
  }

  void _resetRetryState() {
    _retryTimer?.cancel();
    _retryScheduled = false;
    _attempt = 0;
    _cacheBuster = 0;
  }

  int get _currentRequestSize => _attempt == 0 ? widget.baseRequestSize : 96;

  String get _baseCacheKey =>
      'emoji_${widget.emojiId}_${widget.animated ? 'a' : 's'}_'
      '$_currentRequestSize';

  String get _cacheKey =>
      '$_baseCacheKey${_cacheBuster > 0 ? '_r$_cacheBuster' : ''}';

  String get _imageUrl {
    final baseUrl = getCustomEmojiUrl(
      id: widget.emojiId,
      animated: widget.animated,
      size: _currentRequestSize,
    );
    if (_cacheBuster == 0) {
      return baseUrl;
    }

    final separator = baseUrl.contains('?') ? '&' : '?';
    return '$baseUrl${separator}retry=$_cacheBuster';
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: _imageUrl,
    cacheKey: _cacheKey,
    width: widget.size,
    height: widget.size,
    memCacheWidth: widget.size.toInt(),
    memCacheHeight: widget.size.toInt(),
    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,
    fit: BoxFit.contain,
    placeholder: (_, _) => SizedBox(width: widget.size, height: widget.size),
    errorBuilder: (_, _, _) {
      _onError();
      return SizedBox(width: widget.size, height: widget.size);
    },
  );
}
