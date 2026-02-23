import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/providers/app_startup_provider.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kRetryDelay = Duration(seconds: 5);

class ReconnectingScreen extends ConsumerStatefulWidget {
  const ReconnectingScreen({super.key});

  @override
  ConsumerState<ReconnectingScreen> createState() => _ReconnectingScreenState();
}

class _ReconnectingScreenState extends ConsumerState<ReconnectingScreen> {
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _scheduleRetry();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    _retryTimer = Timer(_kRetryDelay, () async {
      await ref.read(appStartupProvider.notifier).retry();
      if (mounted) {
        _scheduleRetry();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.plugsConnected,
              size: 48,
              color: FluxerColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'We fluxed up!',
              style: TextStyle(
                color: FluxerColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Something is wrong with the servers.\n'
              'Should be fixed in a second!',
              textAlign: TextAlign.center,
              style: TextStyle(color: FluxerColors.textMuted, fontSize: 16),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: FluxerColors.blurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
