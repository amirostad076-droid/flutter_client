import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/discovery/presentation/discovery_page.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';

class DiscoveryLayout extends StatelessWidget {
  const DiscoveryLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget page = const DiscoveryPage();
    if (!isMobileLayout(context)) {
      return page;
    }
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: page,
    );
  }
}
