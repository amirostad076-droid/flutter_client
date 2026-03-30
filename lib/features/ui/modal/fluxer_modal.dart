import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ---------------------------------------------------------------------------
// FluxerModal
// ---------------------------------------------------------------------------

/// Builder that receives the dialog's [BuildContext] and a [close] callback.
typedef FluxerModalBuilder =
    Widget Function(BuildContext context, VoidCallback close);

/// A styled dialog modal.
///
/// Uses [showDialog] with a blurred backdrop matching the web app's
/// centered-modal styling. Inherits background color and shadow from
/// the app's [DialogTheme], overriding only the border radius for
/// mobile layout.
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
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        void close() => Navigator.of(dialogContext).pop();

        final colors = dialogContext.colors;
        final textStyles = dialogContext.textStyles;
        final layout = dialogContext.layout;
        final dialogTheme = DialogTheme.of(dialogContext);

        // Use the theme's shape but swap the radius for mobile (16px).
        final themeShape = dialogTheme.shape as RoundedRectangleBorder?;

        return Stack(
          children: [
            // Backdrop with blur
            Positioned.fill(
              child: GestureDetector(
                onTap: close,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),

            // Dialog
            Center(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: layout.radiusXxl,
                  side: themeShape?.side ?? BorderSide.none,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                                  fontSize: 18,
                                  color: colors.textPrimary,
                                  height: 20 / 18,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: 0.5,
                              child: FluxerButton.ghost(
                                onPressed: close,
                                icon: PhosphorIconsBold.x,
                                isSquare: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            layout.s4,
                            0,
                            layout.s4,
                            layout.s4,
                          ),
                          child: SingleChildScrollView(
                            child: builder(dialogContext, close),
                          ),
                        ),
                      ),

                      // Actions
                      if (actions != null && actions.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(layout.s4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: actions,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    bool isDanger = false,
  }) {
    return FluxerModal.show<bool>(
      context,
      title: title,
      builder: (dialogContext, close) {
        final textStyles = dialogContext.textStyles;

        return Text(
          description,
          style: textStyles.bodySmall.copyWith(height: 1.4),
        );
      },
      actions: [
        if (isDanger)
          FluxerButton.dangerPrimary(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true);
            },
            label: confirmLabel,
          )
        else
          FluxerButton.primary(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true);
            },
            label: confirmLabel,
          ),
        const SizedBox(height: 8),
        FluxerButton.secondary(
          onPressed: () => Navigator.of(context).pop(false),
          label: 'Cancel',
        ),
      ],
    );
  }
}
