import 'package:fluxer_app/core/instance/instance_endpoints.dart';

export 'package:fluxer_app/core/instance/instance_endpoints.dart'
    show InstanceEndpoints;

/// Media proxy base for avatars, banners, guild icons, emojis, stickers, etc.
String get fluxerMediaCdn => InstanceEndpoints.media;

/// Static CDN base for bundled assets (default avatars, emoji sprites).
String get fluxerStaticCdn => InstanceEndpoints.staticCdn;
