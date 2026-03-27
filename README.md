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
  <a href="https://pub.dev/packages/fluxer_dart">
    <img src="https://img.shields.io/badge/pub.dev-fluxer__dart-blue" alt="pub.dev package" /></a>
</p>

# Fluxer Flutter Client

This is the repo for the offical Fluxer mobile app powered by Flutter (desktop is in the works also but mobile is the main focus currently).

You can follow more about the V1 development in [this issue.](https://github.com/fluxerapp/flutter_client/issues/1)

## Contributing

We welcome contributions from the community. Please check out the V1 umbrella issue to see how you can help.

Pull requests should target the `canary` branch. For local testing, use the `canary` build flavor so your build matches that branch (see Mobile builds below).

### Build generated files

Riverpod generated files are not committed, so you need to generate them before running the project.

```text
dart run build_runner build --delete-conflicting-outputs
```

### Mobile builds

**Environments** are `canary`, `beta`, and `production`. Set `APP_ENVIRONMENT` to match.

**Application ID / bundle ID:** `beta` and `production` use `app.fluxer`. `canary` uses `app.fluxer.canary`

**Android** uses two Gradle flavor dimensions: environment plus push (`fcm` or `unifiedpush`). The variant name combines both in camelCase (for example `productionFcm`, `betaUnifiedpush`). `PUSH_PROVIDER` must match the push dimension: `fcm` for Firebase Cloud Messaging (adds deps via `pubspec.firebase.deps.yaml`) or `unifiedpush` for UnifiedPush.

**iOS** uses schemes with the same environment names (`canary`, `beta`, `production`). There is no push flavor dimension; push is always Apple Push Notification service, so use `PUSH_PROVIDER=apns`.

Example (Android, production with FCM):

```text
flutter run --flavor productionFcm --dart-define=APP_ENVIRONMENT=production --dart-define=PUSH_PROVIDER=fcm
```

For the same environment on iOS, swap the flavor for the scheme and set `PUSH_PROVIDER=apns`, for example `--flavor production` and `--dart-define=PUSH_PROVIDER=apns`.

### Desktop builds

Coming soon!

### API

The Flutter client uses the [dart_sdk](https://github.com/fluxerapp/dart_sdk) to send requests to the Fluxer API which is generated from the OpenApi spec.
