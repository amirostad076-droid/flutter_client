import 'package:fluxer_app/core/router/route_names.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pre_reconnecting_location_provider.g.dart';

const Set<String> _nonRestorableLocations = {
  '/login',
  '/loading',
  '/reconnecting',
};

String _locationFromPathAndQuery(String path, String query) {
  if (query.isEmpty) {
    return path;
  }
  return '$path?$query';
}

bool isRestorableAppLocation(String location) {
  if (location.isEmpty || _nonRestorableLocations.contains(location)) {
    return false;
  }
  return true;
}

@Riverpod(keepAlive: true)
class PreReconnectingLocation extends _$PreReconnectingLocation {
  @override
  String? build() => null;

  void clear() {
    state = null;
  }

  void remember({required String path, required String query}) {
    final String location = _locationFromPathAndQuery(path, query);
    if (!isRestorableAppLocation(location)) {
      return;
    }
    state = location;
  }

  String takeOrDefault() {
    final String? saved = state;
    state = null;
    if (saved != null && isRestorableAppLocation(saved)) {
      return saved;
    }
    return RoutePaths.me;
  }
}
