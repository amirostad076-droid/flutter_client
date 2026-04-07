import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/providers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/ui/input/emoji_text_editing_controller.dart';
import 'package:fluxer_app/shared/utils/emoji_registry.dart';

const int _kMaxResults = 7;
const int _kMinQueryLength = 2;
const double _kEmojiSize = 24;
const double _kRowPaddingH = 6;
const double _kRowInnerPadding = 8;
const double _kRowRadius = 8;

class EmojiAutocompleteOverlay extends StatefulWidget {
  const EmojiAutocompleteOverlay({
    required this.controller,
    required this.child,
    this.maxActualLength,
    this.customEmojis = const [],
    this.onEmojiInserted,
    super.key,
  });

  final EmojiTextEditingController controller;
  final Widget child;
  final int? maxActualLength;
  final VoidCallback? onEmojiInserted;
  final List<GuildEmojiEntry> customEmojis;

  @override
  State<EmojiAutocompleteOverlay> createState() =>
      _EmojiAutocompleteOverlayState();
}

class _EmojiAutocompleteOverlayState extends State<EmojiAutocompleteOverlay>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final GlobalKey _targetKey = GlobalKey();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  List<_Suggestion> _results = const [];
  String _lastQuery = '';
  int? _triggerStart;
  int? _cursorAtTrigger;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(EmojiAutocompleteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final sel = widget.controller.selection;

    if (!sel.isValid) {
      return;
    }
    if (!sel.isCollapsed) {
      _hide();
      return;
    }

    final cursor = sel.baseOffset;
    final trigger = _detectTrigger(text, cursor);
    if (trigger == null) {
      _hide();
      return;
    }

    final (query, start) = trigger;
    final results = _search(query);
    if (results.isEmpty) {
      _hide();
      return;
    }

    _triggerStart = start;
    _cursorAtTrigger = cursor;
    _lastQuery = query;
    setState(() => _results = results);
    if (!_overlayController.isShowing) {
      _overlayController.show();
      unawaited(_animationController.forward());
    }
  }

  List<_Suggestion> _search(String query) {
    final q = query.toLowerCase();
    final suggestions = <_Suggestion>[];

    for (final entry in EmojiRegistry.allEmojis) {
      if (entry.names.any((n) => n.contains(q))) {
        suggestions.add(
          _Suggestion(
            name: entry.primaryName,
            insertValue: entry.surrogates,
            displayEmoji: entry.surrogates,
          ),
        );
        if (suggestions.length >= _kMaxResults) {
          return suggestions;
        }
      }
    }

    for (final entry in widget.customEmojis) {
      if (entry.name.toLowerCase().contains(q)) {
        suggestions.add(
          _Suggestion(
            name: entry.name,
            insertValue: entry.markdown,
            imageUrl: entry.urlForSize(48),
          ),
        );
        if (suggestions.length >= _kMaxResults) {
          return suggestions;
        }
      }
    }

    return suggestions;
  }

  (String query, int start)? _detectTrigger(String text, int cursor) {
    for (var i = cursor - 1; i >= 0; i--) {
      final char = text[i];
      if (char == ':') {
        if (i > 0 && !_isDelimiter(text[i - 1])) {
          return null;
        }
        final query = text.substring(i + 1, cursor);
        if (query.length < _kMinQueryLength) {
          return null;
        }
        return (query, i);
      }
      if (_isDelimiter(char)) {
        return null;
      }
    }
    return null;
  }

  static bool _isDelimiter(String char) {
    if (char == ' ' || char == '\n' || char == '\t' || char == ':') {
      return true;
    }
    final code = char.codeUnitAt(0);
    return code >= 0xD800 && code <= 0xF8FF;
  }

  void _hide() {
    if (!_overlayController.isShowing) {
      return;
    }
    unawaited(
      _animationController.reverse().then((_) {
        if (mounted && _overlayController.isShowing) {
          _overlayController.hide();
        }
      }),
    );
    _triggerStart = null;
    _cursorAtTrigger = null;
    _results = const [];
  }

  void _selectSuggestion(
    _Suggestion suggestion,
    int triggerStart,
    int cursor,
  ) {
    widget.controller.replaceRangeWithEmoji(
      triggerStart,
      cursor,
      suggestion.name,
      suggestion.insertValue,
      maxActualLength: widget.maxActualLength,
    );
    widget.onEmojiInserted?.call();
    _hide();
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = context.colors;
    final renderBox =
        _targetKey.currentContext?.findRenderObject() as RenderBox?;
    final targetWidth = (renderBox?.hasSize ?? false)
        ? renderBox!.size.width
        : double.infinity;
    final triggerStart = _triggerStart;
    final cursor = _cursorAtTrigger;
    if (triggerStart == null || cursor == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _hide,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: CompositedTransformFollower(
            link: _layerLink,
            followerAnchor: Alignment.bottomLeft,
            child: TextFieldTapRegion(
              child: SizedBox(
                width: targetWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.backgroundPrimary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.24),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionHeader(query: _lastQuery),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final suggestion in _results)
                                _SuggestionItem(
                                  suggestion: suggestion,
                                  onTap: () => _selectSuggestion(
                                    suggestion,
                                    triggerStart,
                                    cursor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: KeyedSubtree(key: _targetKey, child: widget.child),
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.name,
    required this.insertValue,
    this.displayEmoji,
    this.imageUrl,
  });

  final String name;
  final String insertValue;
  final String? displayEmoji;
  final String? imageUrl;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        'EMOJI MATCHING :$query:',
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.025 * 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kRowPaddingH),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kRowRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_kRowInnerPadding),
            child: Row(
              children: [
                SizedBox(
                  width: _kEmojiSize,
                  height: _kEmojiSize,
                  child: switch (suggestion) {
                    _Suggestion(displayEmoji: final emoji?) => Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    _Suggestion(imageUrl: final url?) => CachedNetworkImage(
                        imageUrl: url,
                        width: _kEmojiSize,
                        height: _kEmojiSize,
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ':${suggestion.name}:',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
