import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluxer_app/core/platform/fluxer_platform.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/features/settings/domain/default_web_browser.dart';
import 'package:fluxer_app/shared/external_links/platform_browser_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalUrlBrowserStyle {
  const ExternalUrlBrowserStyle({
    required this.toolbarBackground,
    required this.controlTint,
    required this.navigationBar,
    required this.navigationBarDivider,
  });

  factory ExternalUrlBrowserStyle.fromColorTheme(FluxerColorTheme colors) {
    return ExternalUrlBrowserStyle(
      toolbarBackground: colors.backgroundHeaderPrimary,
      controlTint: colors.textPrimary,
      navigationBar: colors.backgroundPrimary,
      navigationBarDivider: colors.borderColor,
    );
  }

  final Color toolbarBackground;
  final Color controlTint;
  final Color navigationBar;
  final Color navigationBarDivider;
}

class FluxerChromeSafariBrowser extends ChromeSafariBrowser {}

final FluxerChromeSafariBrowser _chromeSafariBrowser =
    FluxerChromeSafariBrowser();

bool _inAppBrowserLifecycleObserverRegistered = false;

bool shouldCloseInAppBrowserOnLifecycle(AppLifecycleState state) {
  return state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
}

class _InAppBrowserLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!shouldCloseInAppBrowserOnLifecycle(state)) {
      return;
    }
    if (_chromeSafariBrowser.isOpened()) {
      unawaited(_chromeSafariBrowser.close());
    }
  }
}

void _ensureInAppBrowserLifecycleObserver() {
  if (_inAppBrowserLifecycleObserverRegistered) {
    return;
  }
  _inAppBrowserLifecycleObserverRegistered = true;
  WidgetsBinding.instance.addObserver(_InAppBrowserLifecycleObserver());
}

ChromeSafariBrowserSettings _buildBrowserSettings(
  ExternalUrlBrowserStyle style,
) {
  return ChromeSafariBrowserSettings(
    barCollapsingEnabled: true,
    noHistory: Platform.isAndroid,
    toolbarBackgroundColor: style.toolbarBackground,
    navigationBarColor: style.navigationBar,
    navigationBarDividerColor: style.navigationBarDivider,
    secondaryToolbarColor: style.toolbarBackground,
    preferredBarTintColor: style.toolbarBackground,
    preferredControlTintColor: style.controlTint,
  );
}

bool _isHttpOrHttps(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

Future<bool> _tryLaunchInNativeApp(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
  } on Object {
    return false;
  }
}

Future<bool> _openInAppBrowser(
  Uri uri, {
  ExternalUrlBrowserStyle? style,
}) async {
  _ensureInAppBrowserLifecycleObserver();
  try {
    if (_chromeSafariBrowser.isOpened()) {
      await _chromeSafariBrowser.close();
    }
    await _chromeSafariBrowser.open(
      url: WebUri(uri.toString()),
      settings: style != null
          ? _buildBrowserSettings(style)
          : ChromeSafariBrowserSettings(
              barCollapsingEnabled: true,
              noHistory: Platform.isAndroid,
            ),
    );
    return true;
  } on Object {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<bool> openExternalUrl(
  Uri uri, {
  ExternalUrlBrowserStyle? style,
  DefaultWebBrowser browser = DefaultWebBrowser.inApp,
}) async {
  if (isFluxerNativeMobileOs && _isHttpOrHttps(uri)) {
    if (await _tryLaunchInNativeApp(uri)) {
      return true;
    }
    if (browser == DefaultWebBrowser.inApp) {
      return _openInAppBrowser(uri, style: style);
    }
    return launchInDefaultWebBrowser(uri, browser);
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
