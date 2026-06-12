import 'dart:convert';
import 'dart:typed_data';

import 'package:fluxer_app/core/synced_preferences/favorites_state_codec.dart';
import 'package:fluxer_app/core/synced_preferences/generated/favorites.pb.dart'
    as pb;

/// Field number for [pb.SyncedPreferences.favorites] in the full schema.
const int kSyncedPreferencesFavoritesFieldNumber = 40;

class SyncedPreferencesWireCodec {
  const SyncedPreferencesWireCodec._();

  static String encodeFavoritesIntoWire({
    required String? currentWire,
    required FavoritesLocalState local,
  }) {
    final normalized = FavoritesStateCodec.normalizeForSync(local);
    final favoritesOnlyWire = pb.SyncedPreferences(
      favorites: FavoritesStateCodec.toProto(normalized),
    ).writeToBuffer();
    final favoritesFieldChunks = _extractFieldChunks(
      favoritesOnlyWire,
      kSyncedPreferencesFavoritesFieldNumber,
    );
    if (currentWire == null || currentWire.isEmpty) {
      return base64Encode(_concatChunks(favoritesFieldChunks));
    }
    try {
      final currentBytes = base64Decode(currentWire);
      final updated = _replaceField(
        target: currentBytes,
        fieldNumber: kSyncedPreferencesFavoritesFieldNumber,
        sourceFieldChunks: favoritesFieldChunks,
      );
      return base64Encode(updated);
    } on Object {
      return base64Encode(favoritesOnlyWire);
    }
  }

  static Uint8List _replaceField({
    required Uint8List target,
    required int fieldNumber,
    required List<Uint8List> sourceFieldChunks,
  }) {
    final targetChunks = _parseTopLevelFieldChunks(target);
    final pieces = <Uint8List>[];
    var inserted = false;
    for (final chunk in targetChunks) {
      if (chunk.field == fieldNumber) {
        if (!inserted) {
          pieces.addAll(sourceFieldChunks);
          inserted = true;
        }
        continue;
      }
      pieces.add(chunk.bytes);
    }
    if (!inserted) {
      pieces.addAll(sourceFieldChunks);
    }
    return _concatChunks(pieces);
  }

  static List<Uint8List> _extractFieldChunks(
    Uint8List bytes,
    int fieldNumber,
  ) {
    return _parseTopLevelFieldChunks(bytes)
        .where((chunk) => chunk.field == fieldNumber)
        .map((chunk) => chunk.bytes)
        .toList();
  }

  static List<_TopLevelFieldChunk> _parseTopLevelFieldChunks(Uint8List bytes) {
    final chunks = <_TopLevelFieldChunk>[];
    var offset = 0;
    while (offset < bytes.length) {
      final start = offset;
      final key = _readVarint(bytes, offset);
      if (key == null) {
        break;
      }
      offset = key.nextOffset;
      final field = key.value >> 3;
      final nextOffset = _skipWireValue(bytes, offset, key.value & 7);
      if (nextOffset == null) {
        break;
      }
      offset = nextOffset;
      chunks.add(
        _TopLevelFieldChunk(field: field, bytes: bytes.sublist(start, offset)),
      );
    }
    return chunks;
  }

  static _VarintRead? _readVarint(Uint8List bytes, int offset) {
    var value = 0;
    var shift = 0;
    while (offset < bytes.length) {
      final byte = bytes[offset++];
      value |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return _VarintRead(value: value, nextOffset: offset);
      }
      shift += 7;
    }
    return null;
  }

  static int? _skipWireValue(Uint8List bytes, int offset, int wireType) {
    if (wireType == 0) {
      return _readVarint(bytes, offset)?.nextOffset;
    }
    if (wireType == 1) {
      final nextOffset = offset + 8;
      return nextOffset <= bytes.length ? nextOffset : null;
    }
    if (wireType == 2) {
      final length = _readVarint(bytes, offset);
      if (length == null) {
        return null;
      }
      final nextOffset = length.nextOffset + length.value;
      return nextOffset <= bytes.length ? nextOffset : null;
    }
    if (wireType == 5) {
      final nextOffset = offset + 4;
      return nextOffset <= bytes.length ? nextOffset : null;
    }
    return null;
  }

  static Uint8List _concatChunks(List<Uint8List> chunks) {
    var total = 0;
    for (final chunk in chunks) {
      total += chunk.length;
    }
    final out = Uint8List(total);
    var offset = 0;
    for (final chunk in chunks) {
      out.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return out;
  }
}

class _TopLevelFieldChunk {
  const _TopLevelFieldChunk({required this.field, required this.bytes});

  final int field;
  final Uint8List bytes;
}

class _VarintRead {
  const _VarintRead({required this.value, required this.nextOffset});

  final int value;
  final int nextOffset;
}
