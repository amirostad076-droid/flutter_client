import 'dart:async';

import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toast_provider.g.dart';

class ToastEntry {
  const ToastEntry({
    required this.toast,
    required this.id,
    required this.isVisible,
  });

  final FluxerToast toast;
  final int id;
  final bool isVisible;

  ToastEntry copyWith({FluxerToast? toast, int? id, bool? isVisible}) {
    return ToastEntry(
      toast: toast ?? this.toast,
      id: id ?? this.id,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

@Riverpod(keepAlive: true)
class Toast extends _$Toast {
  int _nextId = 0;

  @override
  List<ToastEntry> build() => [];

  void show(FluxerToast toast) {
    final ToastEntry entry = ToastEntry(
      toast: toast,
      id: _nextId++,
      isVisible: true,
    );
    state = [...state, entry];
    Timer(toast.duration, () => dismiss(entry.id));
  }

  void dismiss(int id) {
    final int entryIndex = state.indexWhere(
      (ToastEntry entry) => entry.id == id && entry.isVisible,
    );
    if (entryIndex == -1) {
      return;
    }
    final List<ToastEntry> updatedState = [...state];
    updatedState[entryIndex] = updatedState[entryIndex].copyWith(
      isVisible: false,
    );
    state = updatedState;
    Timer(fluxerToastAnimationDuration, () => _remove(id));
  }

  void _remove(int id) {
    state = state.where((ToastEntry entry) => entry.id != id).toList();
  }
}
