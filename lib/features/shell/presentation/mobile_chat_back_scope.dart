import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/shell/providers/reveal_side_provider.dart';

class MobileChatBackScope extends ConsumerWidget {
  final Widget child;

  const MobileChatBackScope({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isMobileLayout(context)) {
      return child;
    }

    final revealSide = ref.watch(currentRevealSideProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || revealSide != RevealSide.main) {
          return;
        }
        ref.read(currentRevealSideProvider.notifier).set(RevealSide.left);
      },
      child: child,
    );
  }
}
