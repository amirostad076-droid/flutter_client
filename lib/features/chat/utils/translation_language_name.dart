import 'package:flutter/widgets.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

String translationLanguageDisplayName(String languageCode) {
  final String normalized = languageCode.trim();
  if (normalized.isEmpty) {
    return languageCode;
  }
  final List<String> parts = normalized.split(RegExp('[-_]'));
  final String language = parts.first.toLowerCase();
  final String? country = parts.length > 1 ? parts[1].toUpperCase() : null;
  final Locale withCountry = Locale.fromSubtags(
    languageCode: language,
    countryCode: country,
  );
  if (FluxerLocalizations.delegate.isSupported(withCountry)) {
    return lookupFluxerLocalizations(withCountry).localeName;
  }
  final Locale languageOnly = Locale.fromSubtags(languageCode: language);
  if (FluxerLocalizations.delegate.isSupported(languageOnly)) {
    return lookupFluxerLocalizations(languageOnly).localeName;
  }
  return languageCode;
}
