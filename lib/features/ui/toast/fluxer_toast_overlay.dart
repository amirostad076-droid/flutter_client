import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/ui/toast/fluxer_toast.dart';
import 'package:fluxeron/features/ui/toast/toast_provider.dart';

class FluxerToastOverlay extends ConsumerWidget {
  const FluxerToastOverlay({required this.child, super.key});

  final Widget child;

  Color _variantColor(BuildContext context, FluxerToastVariant variant) {
    final colors = context.colors;
    return switch (variant) {
      FluxerToastVariant.info => colors.accentInfo,
      FluxerToastVariant.success => colors.accentSuccess,
      FluxerToastVariant.warning => colors.accentWarning,
      FluxerToastVariant.danger => colors.accentDanger,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(toastProvider);
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;
    final motion = context.motion;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: layout.s4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: EdgeInsets.only(top: layout.s2),
                      child: Dismissible(
                        key: ValueKey(entry.id),
                        onDismissed: (_) =>
                            ref.read(toastProvider.notifier).dismiss(entry.id),
                        child: AnimatedSize(
                          duration: motion.normal,
                          curve: motion.curve,
                          child: Material(
                            color: colors.backgroundFloating,
                            borderRadius: layout.radiusLg,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: layout.radiusLg,
                                border: Border.all(
                                  color: _variantColor(
                                    context,
                                    entry.toast.variant,
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: layout.s4,
                                vertical: layout.s3,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.toast.message,
                                      style: textStyles.bodyMedium,
                                    ),
                                  ),
                                  if (entry.toast.action case final action?)
                                    Padding(
                                      padding: EdgeInsets.only(left: layout.s2),
                                      child: GestureDetector(
                                        onTap: action.onPressed,
                                        child: Text(
                                          action.label,
                                          style: textStyles.bodyMedium.copyWith(
                                            color: colors.textLink,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
