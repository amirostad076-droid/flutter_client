import 'package:dio/dio.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/chat/data/attachment_upload_client.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachment_upload_client_provider.g.dart';

@Riverpod(keepAlive: true)
AttachmentUploadClient attachmentUploadClient(Ref ref) {
  final dio = ref.watch(fluxerDioProvider);
  return AttachmentUploadClient(
    channelsApi: ChannelsApi(dio),
    uploadDio: ref.watch(attachmentUploadDioProvider),
  );
}

/// Plain [Dio] for presigned PUT URLs (no auth headers, long timeouts).
@Riverpod(keepAlive: true)
Dio attachmentUploadDio(Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(minutes: 10),
      validateStatus: (int? status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}
