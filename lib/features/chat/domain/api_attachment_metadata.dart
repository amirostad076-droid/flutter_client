class ApiAttachmentMetadata {
  const ApiAttachmentMetadata({
    required this.id,
    required this.filename,
    required this.title,
    this.uploadFilename,
    this.fileSize,
    this.contentType,
    this.description,
    this.flags,
    this.duration,
    this.waveform,
  });

  final String id;
  final String filename;
  final String title;
  final String? uploadFilename;
  final int? fileSize;
  final String? contentType;
  final String? description;
  final int? flags;
  final int? duration;
  final String? waveform;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'filename': filename,
      'title': title,
    };
    if (uploadFilename != null) {
      map['upload_filename'] = uploadFilename;
    }
    if (fileSize != null) {
      map['file_size'] = fileSize;
    }
    if (contentType != null) {
      map['content_type'] = contentType;
    }
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (flags != null && flags != 0) {
      map['flags'] = flags;
    }
    if (duration != null) {
      map['duration'] = duration;
    }
    if (waveform != null) {
      map['waveform'] = waveform;
    }
    return map;
  }
}
