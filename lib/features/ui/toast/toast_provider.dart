import 'dart:async';

import 'package:fluxeron/features/ui/toast/fluxer_toast.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toast_provider.g.dart';

class ToastEntry {
  ToastEntry({required this.toast, required this.id});

  final FluxerToast toast;
  final int id;
}

@Riverpod(keepAlive: true)
class Toast extends _$Toast {
  var _nextId = 0;

  @override
  List<ToastEntry> build() => [];

  void show(FluxerToast toast) {
    final entry = ToastEntry(toast: toast, id: _nextId++);
    state = [...state, entry];
    Timer(toast.duration, () => dismiss(entry.id));
  }

  void dismiss(int id) {
    state = state.where((e) => e.id != id).toList();
  }
}
