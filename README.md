> [!CAUTION]
> The Fluxer Flutter mobile client is still in beta so features will be missing or broken. Currently the only way to report issues is on the Fluxer Mobile community (Plutonium members only), this will change in the future.
>
> Note there is currently no set release date for the app.

<p align="center">
  <img src="./docs/media/logo-graphic.png" alt="Fluxer graphic logo" width="400">
</p>

<p align="center">
  <a href="https://fluxer.app/donate">
    <img src="https://img.shields.io/badge/Donate-fluxer.app%2Fdonate-brightgreen" alt="Donate" /></a>
  <a href="https://docs.fluxer.app">
    <img src="https://img.shields.io/badge/Docs-docs.fluxer.app-blue" alt="Documentation" /></a>
  <a href="./LICENSE">
    <img src="https://img.shields.io/badge/License-AGPLv3-purple" alt="AGPLv3 License" /></a>
  <a href="https://github.com/fluxerapp/flutter_client/actions/workflows/dart-analyze.yml">
    <img src="https://github.com/fluxerapp/flutter_client/actions/workflows/dart-analyze.yml/badge.svg" alt="Dart analyze" /></a>
</p>

# Fluxer Flutter Client

This is the repo for the offical Fluxer mobile app powered by Flutter (desktop is in the works also but mobile is the main focus currently).

You can follow more about the V1 development in and what features are planned/implemented in this [Roadmap issue](https://github.com/fluxerapp/flutter_client/issues/184).

# Community

> [!NOTE]
> Currently the community is locked to Fluxer Plutonium members only. This limit will be lifted after the beta period (the link below will not work yet).

For updates, support, and discussion, [join the Fluxer Mobile community on Fluxer](https://fluxer.gg/fluxer-mobile).

## Download

**Apple App Store**: Coming when V1 is finished.

**Google Play Store**: Coming when V1 is finished.

**Fdroid**: Coming when V1 is finished.

**Android APK (FCM)**: You can find both stable and beta builds in [Github releases](https://github.com/fluxerapp/flutter_client/releases), and you can use [Obtainium](http://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/fluxerapp/flutter_client) for auto updates. Requires Google Play Services (Firebase Messaging for Notifications).

**Android APK OSS**: You can find both stable and beta builds in [Github releases](https://github.com/fluxerapp/flutter_client/releases), and you can use [Obtainium](http://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/fluxerapp/flutter_client) for auto updates. Requires a [UnifiedPush](https://unifiedpush.org) provider for push notifications.

Stable, beta, and canary Android release builds on Github are signed with this SHA-256 certificate fingerprint:
`91:E4:98:E1:B8:A6:C8:BA:99:41:5E:DB:29:78:29:6B:6C:58:BA:A5:E2:D2:A6:49:CE:C6:2D:A7:A8:29:C7:BC`

## Bug reporting

> [!WARNING]
> During the beta period the only place to report bugs will be in the Fluxer Mobile community (they are mirrored to Github still). Once the beta period finishes you will be able to report issues on Github and the community.

## Contributing

During the current beta, we are only accepting contributions for bug fixes. To submit a PR, it must be for a linked reported issue.

After the beta period, we will be updating these guidlines.

Pull requests should target the `canary` branch. For local testing, use the `canary` build flavor so your build matches that branch (see Mobile builds below).

### Translating

We welcome contributions for app translations. Translations are managed through our own Weblate instance. More information about that will be linked here soon.

### Tech stack

- **Flutter / Dart** — cross platform UI (mobile today, desktop in progress)
- **Riverpod** — state management (with code generation)
- **go_router** — navigation and deep links
- **Drift** — local SQLite database
- **Dio** — HTTP client
- **[fluxer_dart](https://github.com/fluxerapp/dart_sdk)** — Fluxer API client (OpenAPI generated)
- **WebSockets** — real time gateway events
- **LiveKit / WebRTC** — voice and video calls
- **FCM / UnifiedPush / APNs** — push notifications (platform dependent)

### Build generated files

Riverpod generated files are not committed, so you need to generate them before running the project.

```text
dart run build_runner build --delete-conflicting-outputs
```

### Mobile builds

**Environments** are `canary`, `beta`, and `stable`. Pass compile-time defines with `--dart-define-from-file=tool/dart_defines/<environment>.json` (each file sets `APP_ENVIRONMENT`) plus `--dart-define=PUSH_PROVIDER=...` as needed.

**Application ID / bundle ID:** `beta` and `stable` use `com.fluxer`. `canary` uses `com.fluxer.canary`

**Android** uses two Gradle flavor dimensions: environment plus push (`fcm` or `unifiedpush`). The variant name combines both in camelCase (for example `stableFcm`, `betaUnifiedpush`). `PUSH_PROVIDER` must match the push dimension: `fcm` for Firebase Cloud Messaging (adds deps via `pubspec.firebase.deps.yaml`) or `unifiedpush` for UnifiedPush.

**iOS** uses schemes with the same environment names (`canary`, `beta`, `stable`). There is no push flavor dimension; push is always Apple Push Notification service, so use `PUSH_PROVIDER=apns`.

Example (Android, stable with FCM):

```text
flutter run --flavor stableFcm --dart-define-from-file=tool/dart_defines/stable.json --dart-define=PUSH_PROVIDER=fcm
```

For the same environment on iOS, swap the flavor for the scheme and set `PUSH_PROVIDER=apns`, for example `--flavor stable`, `--dart-define-from-file=tool/dart_defines/stable.json`, and `--dart-define=PUSH_PROVIDER=apns`.

```text
flutter build ios --flavor canary --dart-define-from-file=tool/dart_defines/canary.json --dart-define=PUSH_PROVIDER=apns
```

### Desktop builds

Coming soon!

### API

The Flutter client uses the [dart_sdk](https://github.com/fluxerapp/dart_sdk) to send requests to the Fluxer API which is generated from the OpenApi spec.
