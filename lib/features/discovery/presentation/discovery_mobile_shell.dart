import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/discovery/presentation/discovery_page.dart';

class DiscoveryMobileShell extends StatelessWidget {
  const DiscoveryMobileShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: const DiscoveryPage(showBackButton: true),
    );
  }
}
