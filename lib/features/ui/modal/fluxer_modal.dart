import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/ui/button/fluxer_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ---------------------------------------------------------------------------
// FluxerModal
// ---------------------------------------------------------------------------

/// Builder that receives the dialog's [BuildContext] and a [close] callback.
typedef FluxerModalBuilder =
    Widget Function(BuildContext context, VoidCallback close);

/// A styled dialog modal.
///
/// Uses [showDialog] and the app's [DialogTheme] for surface styling.
/// The [builder] receives a `close` callback so children can dismiss the
/// dialog without their own `Navigator.pop` call.
class FluxerModal {
  FluxerModal._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required FluxerModalBuilder builder,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) {
        void close() => Navigator.of(dialogContext).pop();

        final colors = dialogContext.colors;
        final textStyles = dialogContext.textStyles;
        final layout = dialogContext.layout;

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(layout.s4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: textStyles.heading.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      FluxerButton.ghost(
                        onPressed: close,
                        icon: PhosphorIconsBold.x,
                        isSquare: true,
                      ),
                    ],
                  ),
                ),

                // Header divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.backgroundModifierAccent,
                ),

                // Body
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.all(layout.s4),
                    child: SingleChildScrollView(
                      child: builder(dialogContext, close),
                    ),
                  ),
                ),

                // Actions
                if (actions != null && actions.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.backgroundModifierAccent,
                  ),
                  Padding(
                    padding: EdgeInsets.all(layout.s4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// FluxerConfirmModal
// ---------------------------------------------------------------------------

/// A confirmation dialog with Cancel / Confirm buttons.
class FluxerConfirmModal {
  FluxerConfirmModal._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    String confirmLabel = 'Confirm',
    bool isDanger = false,
    required VoidCallback onConfirm,
  }) {
    return FluxerModal.show<bool>(
      context,
      title: title,
      builder: (dialogContext, close) {
        final colors = dialogContext.colors;
        final textStyles = dialogContext.textStyles;

        return Text(
          description,
          style: textStyles.username.copyWith(color: colors.textPrimary),
        );
      },
      actions: [
        FluxerButton.secondary(
          onPressed: () => Navigator.of(context).pop(false),
          label: 'Cancel',
          fitContent: true,
        ),
        const SizedBox(width: 8),
        if (isDanger)
          FluxerButton.dangerPrimary(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true);
            },
            label: confirmLabel,
            fitContent: true,
          )
        else
          FluxerButton.primary(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true);
            },
            label: confirmLabel,
            fitContent: true,
          ),
      ],
    );
  }
}
