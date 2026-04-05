import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// An item in a [FluxerSelect] dropdown.
class FluxerSelectItem<T> {
  const FluxerSelectItem({
    required this.value,
    required this.label,
    this.icon,
    this.description,
    this.searchText,
    this.enabled = true,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? description;
  final String? searchText;
  final bool enabled;
}

/// A dropdown select that uses a filled input-style trigger and opens
/// options in a [FluxerBottomSheet].
class FluxerSelect<T> extends StatelessWidget {
  FluxerSelect({
    required this.items,
    required ValueChanged<T> onChanged,
    this.value,
    this.label,
    this.hint,
    this.description,
    this.errorText,
    this.searchHint,
    this.emptyLabel,
    this.enableSearch = true,
    this.enabled = true,
    super.key,
  }) : _onChanged = ((value) => onChanged(value as T));

  final List<FluxerSelectItem<T>> items;
  final ValueChanged<Object?> _onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final String? description;
  final String? errorText;
  final String? searchHint;
  final String? emptyLabel;
  final bool enableSearch;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    final selectedItem = value != null
        ? items.cast<FluxerSelectItem<T>?>().firstWhere(
            (item) => item!.value == value,
            orElse: () => null,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.only(bottom: layout.s1_5),
            child: Text(
              label!,
              style: textStyles.label.copyWith(color: colors.textSecondary),
            ),
          ),
        FluxerTappable(
          enabled: enabled,
          onTap: () => _showOptions(context),
          semanticLabel: label ?? hint ?? 'Select',
          builder: (context, states) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              borderRadius: layout.radiusLg,
              border: Border.all(
                color: errorText != null
                    ? colors.statusDanger
                    : colors.backgroundModifierAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItem?.label ?? hint ?? '',
                    style: selectedItem != null
                        ? textStyles.bodySmall.copyWith(
                            color: colors.textPrimary,
                          )
                        : textStyles.bodySmall.copyWith(
                            color: colors.textTertiary,
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: layout.s2),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (description != null)
          Padding(
            padding: EdgeInsets.only(top: layout.s1_5),
            child: Text(
              description!,
              style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: layout.s1_5),
            child: Text(
              errorText!,
              style: textStyles.bodySmall.copyWith(color: colors.statusDanger),
            ),
          ),
      ],
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final result = await FluxerBottomSheet.show<T>(
      context,
      title: label,
      builder: (sheetContext, close) {
        return _FluxerSelectSheet<T>(
          items: items,
          value: value,
          searchHint: searchHint,
          emptyLabel: emptyLabel,
          enableSearch: enableSearch,
          onSelected: (selected) => Navigator.of(sheetContext).pop(selected),
        );
      },
    );

    if (result != null) {
      _onChanged(result);
    }
  }
}

class _FluxerSelectSheet<T> extends StatefulWidget {
  _FluxerSelectSheet({
    required this.items,
    required ValueChanged<T> onSelected,
    super.key,
    this.value,
    this.searchHint,
    this.emptyLabel,
    this.enableSearch = true,
  }) : _onSelected = ((value) => onSelected(value as T));

  final List<FluxerSelectItem<T>> items;
  final T? value;
  final String? searchHint;
  final String? emptyLabel;
  final bool enableSearch;
  final ValueChanged<Object?> _onSelected;

  @override
  State<_FluxerSelectSheet<T>> createState() => _FluxerSelectSheetState<T>();
}

class _FluxerSelectSheetState<T> extends State<_FluxerSelectSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final filteredItems = widget.items.where(_matchesQuery).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.enableSearch)
          FluxerBottomSheetSection(
            child: FluxerInput(
              controller: _searchController,
              hint: widget.searchHint ?? 'Search',
              autofocus: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: PhosphorIcon(
                  PhosphorIconsBold.magnifyingGlass,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        if (widget.enableSearch) SizedBox(height: layout.s3),
        Expanded(
          child: filteredItems.isEmpty
              ? FluxerBottomSheetContent(
                  scrollable: false,
                  child: Center(
                    child: Text(
                      widget.emptyLabel ?? 'No options found',
                      style: context.textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.only(bottom: layout.s4),
                  children: [
                    FluxerBottomSheetSection(
                      child: FluxerMenuGroup(
                        children: [
                          for (final item in filteredItems)
                            FluxerBottomSheetMenuItem(
                              label: item.label,
                              hint: item.description,
                              icon: item.icon,
                              enabled: item.enabled,
                              isSelected: item.value == widget.value,
                              onTap: () => widget._onSelected(item.value),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  bool _matchesQuery(FluxerSelectItem<T> item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final haystacks = [
      item.label,
      if (item.description != null) item.description!,
      if (item.searchText != null) item.searchText!,
    ];

    return haystacks.any((value) => value.toLowerCase().contains(query));
  }
}

@FluxerWidgetPreview(name: 'Closed', group: 'FluxerSelect')
Widget fluxerSelectPreview() {
  return FluxerSelect<String>(
    label: 'Theme accent',
    hint: 'Choose a preset',
    enableSearch: false,
    items: const [
      FluxerSelectItem(value: 'a', label: 'Blurple'),
      FluxerSelectItem(value: 'b', label: 'Teal'),
      FluxerSelectItem(value: 'c', label: 'Rose'),
    ],
    value: 'b',
    onChanged: (_) {},
  );
}

@FluxerWidgetPreview(name: 'With error', group: 'FluxerSelect')
Widget fluxerSelectErrorPreview() {
  return FluxerSelect<String>(
    hint: 'Select an option',
    errorText: 'This field is required.',
    enableSearch: false,
    items: const [
      FluxerSelectItem(value: 'x', label: 'One'),
      FluxerSelectItem(value: 'y', label: 'Two'),
    ],
    onChanged: (_) {},
  );
}
