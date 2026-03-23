enum FluxerButtonSize {
  regular(height: 44, fontSize: 14, iconSize: 20, padding: 16),
  small(height: 40, fontSize: 14, iconSize: 18, padding: 14),
  compact(height: 32, fontSize: 13, iconSize: 16, padding: 12),
  superCompact(height: 24, fontSize: 12, iconSize: 14, padding: 8);

  const FluxerButtonSize({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.padding,
  });

  final double height;
  final double fontSize;
  final double iconSize;
  final double padding;
}
