import 'package:flutter/material.dart';

class FluxerScroller extends StatefulWidget {
  const FluxerScroller({required this.child, this.controller, super.key});

  final Widget child;
  final ScrollController? controller;

  @override
  State<FluxerScroller> createState() => _FluxerScrollerState();
}

class _FluxerScrollerState extends State<FluxerScroller> {
  ScrollController? _internalController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_internalController ??= ScrollController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(controller: _effectiveController, child: widget.child);
  }
}
