import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/widgets/fluxer_widget_preview.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_size.dart';

class FluxerSaveBar extends StatelessWidget {
  const FluxerSaveBar({
    required this.visible,
    required this.onReset,
    required this.onSave,
    this.isSaving = false,
    this.label,
    super.key,
  });

  final bool visible;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final bool isSaving;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final motion = context.motion;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return AnimatedSlide(
      duration: motion.normal,
      curve: motion.curve,
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: motion.normal,
        curve: motion.curve,
        opacity: visible ? 1.0 : 0.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.backgroundSecondaryAlt,
            border: Border(top: BorderSide(color: colors.borderColor)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: layout.s4,
              right: layout.s4,
              top: layout.s3,
              bottom: bottomPadding > 0 ? bottomPadding : layout.s3,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? 'Unsaved changes',
                    style: context.textStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: layout.s2),
                FluxerButton.secondary(
                  onPressed: isSaving ? null : onReset,
                  label: 'Reset',
                  size: FluxerButtonSize.small,
                  fitContent: true,
                ),
                SizedBox(width: layout.s2),
                FluxerButton.primary(
                  onPressed: isSaving ? null : onSave,
                  label: 'Save',
                  size: FluxerButtonSize.small,
                  isLoading: isSaving,
                  fitContent: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@FluxerWidgetPreview(name: 'Visible', group: 'FluxerSaveBar')
Widget fluxerSaveBarVisiblePreview() {
  return FluxerSaveBar(visible: true, onReset: () {}, onSave: () {});
}

@FluxerWidgetPreview(name: 'Hidden', group: 'FluxerSaveBar')
Widget fluxerSaveBarHiddenPreview() {
  return FluxerSaveBar(visible: false, onReset: () {}, onSave: () {});
}
