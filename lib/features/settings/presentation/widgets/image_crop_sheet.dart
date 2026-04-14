import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

enum CropMaskShape { circle, rectangle }

Future<Uint8List?> showImageCropSheet(
  BuildContext context, {
  required Uint8List imageBytes,
  required double aspectRatio,
  required String title,
  CropMaskShape maskShape = CropMaskShape.rectangle,
}) {
  return FluxerBottomSheet.show<Uint8List?>(
    context,
    title: title,
    builder: (sheetContext, _) => _ImageCropContent(
      imageBytes: imageBytes,
      aspectRatio: aspectRatio,
      maskShape: maskShape,
    ),
  );
}

class _ImageCropContent extends StatefulWidget {
  final Uint8List imageBytes;
  final double aspectRatio;
  final CropMaskShape maskShape;

  const _ImageCropContent({
    required this.imageBytes,
    required this.aspectRatio,
    required this.maskShape,
  });

  @override
  State<_ImageCropContent> createState() => _ImageCropContentState();
}

class _ImageCropContentState extends State<_ImageCropContent> {
  final _cropController = CropController();
  var _isCropping = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Crop(
            controller: _cropController,
            image: widget.imageBytes,
            aspectRatio: widget.aspectRatio,
            withCircleUi: widget.maskShape == CropMaskShape.circle,
            baseColor: colors.backgroundPrimary,
            maskColor: colors.backgroundPrimary.withValues(alpha: 0.7),
            onCropped: (result) {
              if (result case CropSuccess(:final croppedImage)) {
                Navigator.of(context).pop(croppedImage);
              } else {
                setState(() => _isCropping = false);
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            layout.s4,
            layout.s4,
            layout.s4,
            layout.s2,
          ),
          child: Row(
            children: [
              Expanded(
                child: FluxerButton.secondary(
                  onPressed: _isCropping
                      ? null
                      : () => Navigator.of(context).pop(widget.imageBytes),
                  label: FluxerLocalizations.of(context).skip,
                ),
              ),
              SizedBox(width: layout.s3),
              Expanded(
                child: FluxerButton.primary(
                  onPressed: _isCropping
                      ? null
                      : () {
                          setState(() => _isCropping = true);
                          _cropController.crop();
                        },
                  label: FluxerLocalizations.of(context).crop,
                  isLoading: _isCropping,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
