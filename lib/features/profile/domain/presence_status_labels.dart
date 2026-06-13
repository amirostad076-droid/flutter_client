import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

String presenceStatusLabel(String status, FluxerLocalizations l10n) {
  return switch (status) {
    'online' => l10n.statusOnline,
    'idle' => l10n.statusIdle,
    'dnd' => l10n.statusDnd,
    'invisible' => l10n.statusInvisible,
    'offline' => l10n.statusOffline,
    _ => status,
  };
}

String? presenceStatusDescription(String status, FluxerLocalizations l10n) {
  return switch (status) {
    'dnd' => l10n.statusDndDescription,
    'invisible' => l10n.statusInvisibleDescription,
    _ => null,
  };
}
