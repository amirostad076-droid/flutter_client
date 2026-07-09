import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/utils/clipboard_attachment_reader.dart';
import 'package:fluxer_app/features/chat/utils/composer_clipboard_paste.dart';
import 'package:fluxer_app/features/chat/utils/file_upload_validator.dart';
import 'package:fluxer_app/features/ui/input/inline_token_clipboard.dart';
import 'package:fluxer_app/features/ui/input/inline_token_text_editing_controller.dart';

class ComposerPasteScope extends ConsumerStatefulWidget {
  const ComposerPasteScope({
    required this.channelId,
    required this.controller,
    required this.focusNode,
    required this.isAttachEnabled,
    required this.onValidationResult,
    required this.builder,
    super.key,
  });

  final String channelId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAttachEnabled;
  final void Function(FileUploadValidationResult result) onValidationResult;
  final Widget Function(BuildContext context, ComposerPasteScopeState state)
  builder;

  @override
  ConsumerState<ComposerPasteScope> createState() => ComposerPasteScopeState();
}

class ComposerPasteScopeState extends ConsumerState<ComposerPasteScope>
    with WidgetsBindingObserver {
  bool _hasPasteableAttachments = false;

  bool get _supportsTouchAttachmentPasteFallback {
    if (kIsWeb) {
      return false;
    }
    return Platform.isIOS || Platform.isAndroid;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.focusNode.addListener(_handleFocusChanged);
    unawaited(refreshClipboardPasteAvailability());
  }

  @override
  void didUpdateWidget(ComposerPasteScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
    if (oldWidget.isAttachEnabled != widget.isAttachEnabled) {
      unawaited(refreshClipboardPasteAvailability());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshClipboardPasteAvailability());
    }
  }

  void _handleFocusChanged() {
    if (widget.focusNode.hasFocus) {
      unawaited(refreshClipboardPasteAvailability());
    }
  }

  Future<void> refreshClipboardPasteAvailability() async {
    if (!widget.isAttachEnabled) {
      if (_hasPasteableAttachments && mounted) {
        setState(() => _hasPasteableAttachments = false);
      }
      return;
    }
    final bool hasAttachments = await clipboardHasPasteableAttachments();
    if (!mounted || hasAttachments == _hasPasteableAttachments) {
      return;
    }
    setState(() => _hasPasteableAttachments = hasAttachments);
  }

  Future<void> handleCopy() {
    return copyInlineTokenSelection(widget.controller);
  }

  Future<void> handleCut() {
    return cutInlineTokenSelection(widget.controller);
  }

  Future<void> handlePaste() {
    return handleComposerPaste(
      ref: ref,
      channelId: widget.channelId,
      controller: widget.controller,
      isAttachEnabled: widget.isAttachEnabled,
      onValidationResult: widget.onValidationResult,
    );
  }

  List<ContextMenuButtonItem> _composeContextMenuItems(
    EditableTextState editableTextState,
  ) {
    final bool isInlineToken =
        widget.controller is InlineTokenTextEditingController;
    final List<ContextMenuButtonItem> buttonItems = editableTextState
        .contextMenuButtonItems
        .map((ContextMenuButtonItem item) {
          if (isInlineToken &&
              (item.type == ContextMenuButtonType.copy ||
                  item.type == ContextMenuButtonType.cut)) {
            return item.copyWith(
              onPressed: () {
                ContextMenuController.removeAny();
                if (item.type == ContextMenuButtonType.copy) {
                  unawaited(handleCopy());
                } else {
                  unawaited(handleCut());
                }
              },
            );
          }
          if (item.type != ContextMenuButtonType.paste) {
            return item;
          }
          return item.copyWith(
            onPressed: () {
              ContextMenuController.removeAny();
              unawaited(handlePaste());
            },
          );
        })
        .toList();
    final bool hasPasteButton = buttonItems.any(
      (ContextMenuButtonItem item) => item.type == ContextMenuButtonType.paste,
    );
    final bool shouldInjectPaste =
        widget.isAttachEnabled &&
        !hasPasteButton &&
        (_hasPasteableAttachments || _supportsTouchAttachmentPasteFallback);
    if (!shouldInjectPaste) {
      return buttonItems;
    }
    return <ContextMenuButtonItem>[
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          ContextMenuController.removeAny();
          unawaited(handlePaste());
        },
      ),
      ...buttonItems,
    ];
  }

  Widget buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: _composeContextMenuItems(editableTextState),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this);
  }
}
