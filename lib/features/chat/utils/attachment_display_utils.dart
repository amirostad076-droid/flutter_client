
(String, String) splitAttachmentFilenameStemAndExtension(String filename) {
  final int lastDot = filename.lastIndexOf('.');
  if (lastDot <= 0) {
    return (filename, '');
  }
  return (filename.substring(0, lastDot), filename.substring(lastDot));
}

String? formatAttachmentByteSize(int? bytes) {
  if (bytes == null || bytes <= 0) {
    return null;
  }
  const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
  double value = bytes.toDouble();
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final int precision = unit == 0 || value >= 10 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unit]}';
}

String formatAttachmentDurationMmSs(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String buildAttachmentSizeDurationMetaLine({
  required int? fileSize,
  required Duration duration,
}) {
  final String? sizeLabel = formatAttachmentByteSize(fileSize);
  final String durationLabel = formatAttachmentDurationMmSs(duration);
  if (sizeLabel == null) {
    if (duration == Duration.zero) {
      return '';
    }
    return durationLabel;
  }
  if (duration == Duration.zero) {
    return sizeLabel;
  }
  return '$sizeLabel · $durationLabel';
}
