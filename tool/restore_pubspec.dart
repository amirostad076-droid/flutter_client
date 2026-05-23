// Tool script: intentional stdout and no public API docs.
// ignore_for_file: avoid_print, document_ignores

import 'dart:io';

const String _markerStart = '# BEGIN firebase optional deps';
const String _markerEnd = '# END firebase optional deps';

const String _servicePath =
    'lib/core/push/services/firebase_messaging_push_service.dart';
const String _serviceStub =
    'lib/core/push/services/firebase_messaging_push_service.stub.dart';
const String _entrypointPath = 'lib/core/push/fcm/fcm_entrypoint.dart';
const String _entrypointStub = 'lib/core/push/fcm/fcm_entrypoint_stub.dart';

Future<void> main(List<String> args) async {
  final Directory root = _findProjectRoot(Directory.current);
  await _restorePubspec(root);
  await _copyTemplate(
    root,
    sourceRelative: _serviceStub,
    targetRelative: _servicePath,
  );
  await _copyTemplate(
    root,
    sourceRelative: _entrypointStub,
    targetRelative: _entrypointPath,
  );
  print('Restored OSS pubspec and FCM stubs. Run: flutter pub get');
}

Future<void> _restorePubspec(Directory root) async {
  final File pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw StateError('pubspec.yaml not found under ${root.path}');
  }
  String content = pubspec.readAsStringSync();
  final int start = content.indexOf(_markerStart);
  if (start < 0) {
    print('No Firebase deps block in pubspec.yaml');
    return;
  }
  final int end = content.indexOf(_markerEnd, start);
  if (end < 0) {
    throw StateError('Missing $_markerEnd marker in pubspec.yaml');
  }
  final int removeEnd = content.indexOf('\n', end + _markerEnd.length);
  final int rangeEnd = removeEnd >= 0 ? removeEnd + 1 : content.length;
  content = content.replaceRange(start, rangeEnd, '');
  pubspec.writeAsStringSync(content);
}

Future<void> _copyTemplate(
  Directory root, {
  required String sourceRelative,
  required String targetRelative,
}) async {
  final File source = File('${root.path}/$sourceRelative');
  final File target = File('${root.path}/$targetRelative');
  if (!source.existsSync()) {
    throw StateError('Template not found: $sourceRelative');
  }
  target.writeAsStringSync(source.readAsStringSync());
  print('Wrote $targetRelative');
}

Directory _findProjectRoot(Directory start) {
  Directory? current = start;
  while (current != null) {
    if (File('${current.path}/pubspec.yaml').existsSync()) {
      return current;
    }
    current = current.parent;
  }
  throw StateError('Could not find project root (pubspec.yaml)');
}
