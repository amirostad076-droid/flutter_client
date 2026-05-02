import 'dart:math';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/picker_search_input.dart';
import 'package:fluxer_app/features/chat/providers/favorite_media_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kGridGap = 8.0;
const _kGridHorizontalPadding = 10.0;
const _kMaxColumnWidth = 227.0;
const _kMinTileHeight = 96.0;
const _kMaxTileHeight = 320.0;

typedef OnFavoriteMemeSelect = void Function(FavoriteMemeSelection selection);

class FavoriteMediaPickerContent extends ConsumerStatefulWidget {
  const FavoriteMediaPickerContent({
    this.onSelect,
    this.searchHorizontalPadding,
    this.searchTopPadding,
    this.searchBottomPadding,
    super.key,
  });

  final OnFavoriteMemeSelect? onSelect;
  final double? searchHorizontalPadding;
  final double? searchTopPadding;
  final double? searchBottomPadding;

  @override
  ConsumerState<FavoriteMediaPickerContent> createState() =>
      _FavoriteMediaPickerContentState();
}

class _FavoriteMediaPickerContentState
    extends ConsumerState<FavoriteMediaPickerContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  FavoriteMemeMediaFilter _filter = FavoriteMemeMediaFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(FavoriteMeme meme) {
    final autoSend = !HardwareKeyboard.instance.isShiftPressed;
    widget.onSelect?.call(
      FavoriteMemeSelection(meme: meme, autoSend: autoSend),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memes = ref.watch(favoriteMemesProvider);

    return Column(
      children: [
        PickerSearchInput(
          controller: _searchController,
          hintText: 'Search saved media',
          horizontalPadding: widget.searchHorizontalPadding ?? 12,
          topPadding: widget.searchTopPadding ?? 12,
          bottomPadding: widget.searchBottomPadding ?? 8,
        ),
        _FilterPills(
          selected: _filter,
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        Expanded(
          child: memes.when(
            data: _buildBody,
            loading: () => const _FavoriteMediaSkeleton(),
            error: (_, _) => const _FavoriteMediaEmptyState(
              icon: PhosphorIconsDuotone.smileySad,
              title: 'Saved Media Unavailable',
              description: 'Try again in a moment.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(List<FavoriteMeme> allMemes) {
    if (allMemes.isEmpty) {
      return const _FavoriteMediaEmptyState(
        icon: PhosphorIconsDuotone.smileySad,
        title: 'No Saved Media',
        description: 'Save some media from messages to get started!',
      );
    }

    final filtered = filterFavoriteMemes(
      allMemes,
      query: _searchQuery,
      filter: _filter,
    );
    if (filtered.isEmpty) {
      return const _FavoriteMediaEmptyState(
        icon: PhosphorIconsDuotone.smileySad,
        title: 'No Results',
        description: 'Try a different search term or filter',
      );
    }

    return _FavoriteMediaMasonryGrid(memes: filtered, onTap: _select);
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onSelected});

  final FavoriteMemeMediaFilter selected;
  final ValueChanged<FavoriteMemeMediaFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final options =
        <({FavoriteMemeMediaFilter filter, String label, IconData? icon})>[
          (filter: FavoriteMemeMediaFilter.all, label: 'All', icon: null),
          (
            filter: FavoriteMemeMediaFilter.images,
            label: 'Images',
            icon: PhosphorIconsFill.image,
          ),
          (
            filter: FavoriteMemeMediaFilter.videos,
            label: 'Videos',
            icon: PhosphorIconsFill.videoCamera,
          ),
          (
            filter: FavoriteMemeMediaFilter.audio,
            label: 'Audio',
            icon: PhosphorIconsFill.musicNote,
          ),
          (
            filter: FavoriteMemeMediaFilter.gifs,
            label: 'GIFs',
            icon: PhosphorIconsFill.gif,
          ),
        ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final option = options[index];
          final active = option.filter == selected;
          return _FilterPill(
            label: option.label,
            icon: option.icon,
            active: active,
            onTap: () => onSelected(option.filter),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: options.length,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? colors.backgroundModifierSelected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final iconData?) ...[
              PhosphorIcon(iconData, size: 14, color: colors.textPrimaryMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? colors.textPrimary : colors.textPrimaryMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteMediaMasonryGrid extends StatelessWidget {
  const _FavoriteMediaMasonryGrid({required this.memes, required this.onTap});

  final List<FavoriteMeme> memes;
  final ValueChanged<FavoriteMeme> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width <= 0) {
        return const SizedBox.shrink();
      }

      final columns = _columnsForWidth(width);
      final availableWidth = width - (_kGridHorizontalPadding * 2);
      final columnWidth =
          (availableWidth - (columns - 1) * _kGridGap) / columns;
      final columnItems = List.generate(columns, (_) => <FavoriteMeme>[]);
      final columnHeights = List<double>.filled(columns, 0);

      for (final meme in memes) {
        var shortestColumn = 0;
        for (var i = 1; i < columnHeights.length; i++) {
          if (columnHeights[i] < columnHeights[shortestColumn]) {
            shortestColumn = i;
          }
        }
        columnItems[shortestColumn].add(meme);
        columnHeights[shortestColumn] +=
            _tileHeight(columnWidth, meme) + _kGridGap;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          _kGridHorizontalPadding,
          0,
          _kGridHorizontalPadding,
          _kGridHorizontalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    for (final meme in columnItems[i]) ...[
                      _FavoriteMediaTile(meme: meme, onTap: () => onTap(meme)),
                      const SizedBox(height: _kGridGap),
                    ],
                  ],
                ),
              ),
              if (i != columns - 1) const SizedBox(width: _kGridGap),
            ],
          ],
        ),
      );
    },
  );

  int _columnsForWidth(double width) {
    final availableWidth = width - (_kGridHorizontalPadding * 2);
    return max(2, (availableWidth / _kMaxColumnWidth).floor());
  }
}

class _FavoriteMediaTile extends StatelessWidget {
  const _FavoriteMediaTile({required this.meme, required this.onTap});

  final FavoriteMeme meme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.backgroundTertiary),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = _tileHeight(width, meme);
              return SizedBox(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _FavoriteMediaPreview(meme: meme),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.28),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (meme.mediaType == FavoriteMemeMediaType.gif)
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: _MediaBadge(label: 'GIF'),
                      ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Text(
                        meme.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          shadows: [Shadow(blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavoriteMediaPreview extends StatelessWidget {
  const _FavoriteMediaPreview({required this.meme});

  final FavoriteMeme meme;

  @override
  Widget build(BuildContext context) {
    if (!meme.isVideoLike &&
        (meme.mediaType == FavoriteMemeMediaType.image ||
            meme.mediaType == FavoriteMemeMediaType.gif)) {
      return CachedNetworkImage(
        imageUrl: meme.url,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => const _PreviewPlaceholder(),
        errorBuilder: (_, _, _) => const _PreviewPlaceholder(),
      );
    }

    return switch (meme.mediaType) {
      FavoriteMemeMediaType.audio => _AudioPreview(meme: meme),
      FavoriteMemeMediaType.video || FavoriteMemeMediaType.gif => _IconPreview(
        icon: meme.mediaType == FavoriteMemeMediaType.gif
            ? PhosphorIconsFill.gif
            : PhosphorIconsFill.videoCamera,
        label: meme.filename,
      ),
      FavoriteMemeMediaType.image || FavoriteMemeMediaType.unknown =>
        _IconPreview(icon: PhosphorIconsFill.file, label: meme.filename),
    };
  }
}

class _AudioPreview extends StatelessWidget {
  const _AudioPreview({required this.meme});

  final FavoriteMeme meme;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.brandPrimary,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhosphorIcon(
            PhosphorIconsFill.musicNote,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(height: 10),
          if (meme.duration != null)
            Text(
              _formatDuration(meme.duration!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            meme.filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPreview extends StatelessWidget {
  const _IconPreview({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.backgroundModifierSelected,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(icon, color: colors.textPrimaryMuted, size: 44),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimaryMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.backgroundModifierSelected,
    child: Center(
      child: PhosphorIcon(
        PhosphorIconsDuotone.image,
        size: 34,
        color: context.colors.textTertiaryMuted,
      ),
    ),
  );
}

class _FavoriteMediaSkeleton extends StatelessWidget {
  const _FavoriteMediaSkeleton();

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
  );
}

class _FavoriteMediaEmptyState extends StatelessWidget {
  const _FavoriteMediaEmptyState({
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
              style: TextStyle(color: colors.textPrimaryMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

double _tileHeight(double columnWidth, FavoriteMeme meme) =>
    (columnWidth / meme.aspectRatio).clamp(_kMinTileHeight, _kMaxTileHeight);

String _formatDuration(double seconds) {
  final totalSeconds = seconds.round();
  final minutes = totalSeconds ~/ 60;
  final remainder = totalSeconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
