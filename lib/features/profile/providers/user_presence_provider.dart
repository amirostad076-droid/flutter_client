import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod/src/providers/stream_provider.dart';

final StreamProviderFamily<User?, String> userPresenceProvider =
    StreamProvider.family<User?, String>((ref, userId) {
      final database = ref.watch(fluxerDatabaseProvider);
      return database.userDao.watchUserById(userId);
    });
