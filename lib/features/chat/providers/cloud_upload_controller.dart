import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/chat/data/attachment_upload_client.dart';
import 'package:fluxer_app/features/chat/data/prepared_attachments.dart';
import 'package:fluxer_app/features/chat/domain/api_attachment_metadata.dart';
import 'package:fluxer_app/features/chat/domain/cloud_composer_attachments.dart';
import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';
import 'package:fluxer_app/features/chat/providers/attachment_upload_client_provider.dart';
import 'package:fluxer_app/features/chat/utils/file_upload_constants.dart';
import 'package:fluxer_app/features/chat/utils/file_upload_validator.dart'
    show
        FileUploadValidationError,
        FileUploadValidationResult,
        FileUploadValidator;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_upload_controller.g.dart';

@Riverpod(keepAlive: true)
class CloudUploadController extends _$CloudUploadController {
  int _nextAttachmentId = 1;
  final Map<int, CancelToken> _activeUploadControllers =
      <int, CancelToken>{};
  String _channelId = '';

  @override
  CloudComposerAttachments build(String channelId) {
    _channelId = channelId;
    ref.onDispose(() {
      for (final CancelToken c in _activeUploadControllers.values) {
        c.cancel();
      }
      _activeUploadControllers.clear();
    });
    return CloudComposerAttachments.empty;
  }

  Future<FileUploadValidationResult> addFiles(List<XFile> files) async {
    if (files.isEmpty) {
      return const FileUploadValidationResult.failure(
        FileUploadValidationError.noFiles,
      );
    }
    const FileUploadValidator validator = FileUploadValidator(
      maxAttachments: kMaxAttachmentsPerMessage,
      maxFileBytes: kDefaultMaxAttachmentBytes,
    );
    final FileUploadValidationResult validation =
        await validator.validateAddFiles(
      currentCount: state.items.length,
      newFiles: files,
      multipartPayloadPreview: const <String, dynamic>{'content': ''},
    );
    if (!validation.isValid) {
      return validation;
    }
    final List<PendingAttachment> created = <PendingAttachment>[];
    for (final XFile file in files) {
      final XFile resolved = await _ensureResolvableFile(file);
      final int length = await resolved.length();
      final String contentType =
          FileUploadValidator.guessContentTypeFromName(resolved.name);
      created.add(
        PendingAttachment(
          id: _nextAttachmentId++,
          channelId: _channelId,
          file: resolved,
          filename: resolved.name,
          size: length,
          contentType: contentType,
          status: PendingAttachmentStatus.pending,
          uploadProgress: 0,
        ),
      );
    }
    state = CloudComposerAttachments(<PendingAttachment>[
      ...state.items,
      ...created,
    ]);
    return const FileUploadValidationResult.success();
  }

  Future<XFile> _ensureResolvableFile(XFile file) async {
    final String path = file.path;
    if (path.isNotEmpty && File(path).existsSync()) {
      return file;
    }
    final Uint8List bytes = await file.readAsBytes();
    final Directory dir = await getTemporaryDirectory();
    final String name = file.name.isNotEmpty ? file.name : 'attachment.bin';
    final File temp = File(
      '${dir.path}/fluxer_upload_${DateTime.now().microsecondsSinceEpoch}_$name',
    );
    await temp.writeAsBytes(bytes, flush: true);
    return XFile(temp.path, name: name, mimeType: file.mimeType);
  }

  Future<void> _ensureAttachmentUploaded(int attachmentId) async {
    final int index = state.items.indexWhere(
      (PendingAttachment e) => e.id == attachmentId,
    );
    if (index == -1) {
      return;
    }
    final PendingAttachment attachment = state.items[index];
    if (attachment.status == PendingAttachmentStatus.sending &&
        attachment.uploadFilename != null &&
        attachment.multipartUploadId == null) {
      return;
    }
    final CancelToken? existing = _activeUploadControllers[attachmentId];
    existing?.cancel();
    final CancelToken token = CancelToken();
    _activeUploadControllers[attachmentId] = token;
    _patchAttachment(
      attachmentId,
      (PendingAttachment a) => a.copyWith(
        status: PendingAttachmentStatus.uploading,
        uploadProgress: 0,
      ),
    );
    try {
      final AttachmentUploadClient client =
          ref.read(attachmentUploadClientProvider);
      final AttachmentUploadPlan plan =
          await client.requestAttachmentUploadPlan(
        channelId: _channelId,
        attachmentId: attachment.id,
        filename: attachment.filename,
        fileSize: attachment.size,
        contentType: attachment.contentType,
        cancelToken: token,
      );
      await client.uploadAttachmentPlan(
        UploadAttachmentPlanParams(
          channelId: _channelId,
          file: attachment.file,
          plan: plan,
          cancelToken: token,
          onPlanReady: ({
            required String uploadFilename,
            required int fileSize,
            required String contentType,
            String? uploadId,
          }) {
            _patchAttachment(
              attachmentId,
              (PendingAttachment a) => a.copyWith(
                uploadFilename: uploadFilename,
                fileSizePlan: fileSize,
                contentTypePlan: contentType,
                multipartUploadId: uploadId,
              ),
            );
          },
          onProgress: (int uploadedBytes, int totalBytes) {
            final double p = totalBytes > 0 ? uploadedBytes / totalBytes : 0;
            _patchAttachment(
              attachmentId,
              (PendingAttachment a) => a.copyWith(
                status: PendingAttachmentStatus.uploading,
                uploadProgress: p,
              ),
            );
          },
        ),
      );
      _patchAttachment(
        attachmentId,
        (PendingAttachment a) => a.copyWith(
          status: PendingAttachmentStatus.sending,
          uploadProgress: 1,
          multipartUploadId: null,
        ),
      );
    } on Object catch (e, st) {
      talker.warning('[CloudUpload] upload failed: $e\n$st');
      _patchAttachment(
        attachmentId,
        (PendingAttachment a) => a.copyWith(
          status: PendingAttachmentStatus.failed,
          uploadProgress: 0,
        ),
      );
    } finally {
      _activeUploadControllers.remove(attachmentId);
    }
  }

  void _patchAttachment(
    int attachmentId,
    PendingAttachment Function(PendingAttachment) updater,
  ) {
    state = CloudComposerAttachments(
      state.items
          .map(
            (PendingAttachment e) =>
                e.id == attachmentId ? updater(e) : e,
          )
          .toList(),
    );
  }

  Future<void> removeAttachment(int attachmentId) async {
    PendingAttachment? att;
    for (final PendingAttachment e in state.items) {
      if (e.id == attachmentId) {
        att = e;
        break;
      }
    }
    if (att == null) {
      return;
    }
    final CancelToken? c = _activeUploadControllers.remove(attachmentId);
    c?.cancel();
    state = CloudComposerAttachments(
      state.items
          .where((PendingAttachment e) => e.id != attachmentId)
          .toList(),
    );
  }

  void updateAttachment(
    int attachmentId, {
    required String filename,
    required String? description,
    required int flags,
  }) {
    _patchAttachment(attachmentId, (PendingAttachment a) {
      return a.copyWith(
        filename: filename,
        description: description == null || description.isEmpty
            ? null
            : description,
        flags: flags,
      );
    });
  }

  void reorderAttachments(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.items.length ||
        newIndex < 0 ||
        newIndex > state.items.length) {
      return;
    }
    var adjustedNewIndex = newIndex;
    if (oldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }
    final List<PendingAttachment> next =
        List<PendingAttachment>.from(state.items);
    final PendingAttachment item = next.removeAt(oldIndex);
    next.insert(adjustedNewIndex, item);
    state = CloudComposerAttachments(next);
  }

  Future<PreparedAttachments> prepareForSend({
    required bool favoriteMemePayload,
  }) async {
    if (state.items.isEmpty) {
      return PreparedAttachments.empty;
    }
    if (favoriteMemePayload) {
      return PreparedAttachments(
        attachmentMetadata: _mapApi(state.items),
        attachmentFiles:
            state.items.map((PendingAttachment e) => e.file).toList(),
      );
    }
    try {
      for (final PendingAttachment a in state.items) {
        await _ensureAttachmentUploadedForce(a.id);
      }
      final bool anyFailed = state.items.any(
        (PendingAttachment e) => e.status == PendingAttachmentStatus.failed,
      );
      if (anyFailed) {
        _fallbackResetComposerUploadsForMultipartSend();
        return PreparedAttachments(
          attachmentMetadata: _mapApi(state.items),
          attachmentFiles:
              state.items.map((PendingAttachment e) => e.file).toList(),
        );
      }
      return PreparedAttachments(
        attachmentMetadata: _mapApi(state.items),
      );
    } on Object catch (e, st) {
      talker.warning('[CloudUpload] prepareForSend presigned error: $e\n$st');
      _fallbackResetComposerUploadsForMultipartSend();
      return PreparedAttachments(
        attachmentMetadata: _mapApi(state.items),
        attachmentFiles:
            state.items.map((PendingAttachment e) => e.file).toList(),
      );
    }
  }

  Future<void> _ensureAttachmentUploadedForce(int attachmentId) async {
    PendingAttachment? att;
    for (final PendingAttachment e in state.items) {
      if (e.id == attachmentId) {
        att = e;
        break;
      }
    }
    if (att == null) {
      return;
    }
    if (att.status == PendingAttachmentStatus.sending &&
        att.uploadFilename != null) {
      return;
    }
    await _ensureAttachmentUploaded(attachmentId);
  }

  void _fallbackResetComposerUploadsForMultipartSend() {
    state = CloudComposerAttachments(
      state.items
          .map(
            (PendingAttachment a) => a.copyWith(
              status: PendingAttachmentStatus.pending,
              uploadProgress: 0,
              uploadFilename: null,
              multipartUploadId: null,
              fileSizePlan: null,
              contentTypePlan: null,
            ),
          )
          .toList(),
    );
  }

  List<ApiAttachmentMetadata> _mapApi(List<PendingAttachment> list) {
    return List<ApiAttachmentMetadata>.generate(list.length, (int i) {
      final PendingAttachment a = list[i];
      final int flagsOut = a.flags;
      return ApiAttachmentMetadata(
        id: '$i',
        filename: a.filename,
        title: a.filename,
        uploadFilename: a.uploadFilename,
        fileSize: a.fileSizePlan ?? a.size,
        contentType: a.contentTypePlan ?? a.contentType,
        description: a.description,
        flags: flagsOut != 0 ? flagsOut : null,
      );
    });
  }

  void clearComposerAttachments() {
    for (final CancelToken c in _activeUploadControllers.values) {
      c.cancel();
    }
    _activeUploadControllers.clear();
    state = CloudComposerAttachments.empty;
  }
}
