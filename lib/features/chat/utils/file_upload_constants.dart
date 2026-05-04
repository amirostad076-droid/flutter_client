const int kMaxAttachmentsPerMessage = 10;
const int kDefaultMaxAttachmentBytes = 25 * 1024 * 1024;
const int kMultipartUploadConcurrency = 4;
const int kMultipartRequestFixedOverheadBytes = 16 * 1024;
const int kMultipartRequestFileOverheadBytes = 4 * 1024;
const int kForcedMultipartMessageMaxRequestBytes = kDefaultMaxAttachmentBytes;
