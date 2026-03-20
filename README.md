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

### Build generated files

Riverpod generated files are not committed, so you need to generate them before running the project.

```text
dart run build_runner build --delete-conflicting-outputs
```

### Android build flavors

Android uses two flavor dimensions:

- environment: `canary`, `production`
- push: `fcm`, `unifiedpush`

This creates four variants:

- `canaryFcm`
- `canaryUnifiedpush`
- `productionFcm`
- `productionUnifiedpush`

Android FCM builds require Firebase deps from `pubspec.firebase.deps.yaml`.
UnifiedPush builds use `pubspec.yaml` as-is.

Examples:

```text
flutter run --flavor canaryFcm --dart-define=APP_ENVIRONMENT=canary --dart-define=PUSH_PROVIDER=firebase

flutter run --flavor productionUnifiedpush --dart-define=APP_ENVIRONMENT=production --dart-define=PUSH_PROVIDER=unifiedpush

flutter build apk --flavor productionFcm --dart-define=APP_ENVIRONMENT=production --dart-define=PUSH_PROVIDER=firebase
```

### iOS build flavors

iOS uses flavor schemes:

- `canary`
- `production`

iOS is APNs-only and won't work with any other provider.

Examples:

```text
flutter run --flavor canary --dart-define=APP_ENVIRONMENT=canary --dart-define=PUSH_PROVIDER=apple

flutter run --flavor production --dart-define=APP_ENVIRONMENT=production --dart-define=PUSH_PROVIDER=apple

flutter build ipa --flavor production --dart-define=APP_ENVIRONMENT=production --dart-define=PUSH_PROVIDER=apple
```

### API

The Flutter client uses the [dart_sdk](https://github.com/fluxerapp/dart_sdk) to send requests to the Fluxer API which is generated from the OpenApi spec.
