import 'dart:ui' show Locale;

import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

/// Picks the closest [FluxerLocalizations.supportedLocales] entry for [locale].
Locale resolveSupportedFluxerLocale(Locale locale) {
  for (final Locale supported in FluxerLocalizations.supportedLocales) {
    if (supported.languageCode == locale.languageCode) {
      return supported;
    }
  }
  return FluxerLocalizations.supportedLocales.first;
}

/// Like [lookupFluxerLocalizations], but never throws for unsupported locales.
FluxerLocalizations lookupFluxerLocalizationsWithFallback(Locale locale) {
  return lookupFluxerLocalizations(resolveSupportedFluxerLocale(locale));
}
