import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluxer_app/core/widgets/fluxer_render_error_placeholder.dart';

void configureFluxerErrorUi() {
  if (kDebugMode) {
    return;
  }
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const FluxerRenderErrorPlaceholder();
  };
}
