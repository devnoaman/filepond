import 'dart:async';

/// A mixin to track upload progress for one or more files.
mixin UploadProgressMixin {
  final Map<String, StreamController<double>> _progressControllers = {};

  /// Subscribe to a file's upload progress using its [id].
  Stream<double> getUploadProgress(String id) {
    if (_progressControllers.containsKey(id)) {
      return _progressControllers[id]!.stream;
    }

    final controller = StreamController<double>.broadcast();
    controller.add(0.0);
    _progressControllers[id] = controller;
    return controller.stream;
  }

  /// Update the progress (value between 0.0 and 1.0) for a specific file ID.
  void updateUploadProgress(String id, double progress) {
    final controller = _progressControllers[id];
    if (controller == null || controller.isClosed) return;

    final clamped = progress.clamp(0.0, 1.0);
    final rounded =
        clamped < 0.01
            ? (clamped * 100).ceil() / 100
            : clamped > 0.99
            ? 1.0
            : (clamped * 100).round() / 100;

    controller.add(rounded);

    if (rounded == 1.0) {
      clearUploadProgress(id);
    }
  }

  /// Close and remove the stream controller for a specific file ID.
  void clearUploadProgress(String id) {
    final controller = _progressControllers[id];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _progressControllers.remove(id);
  }

  /// Dispose all upload progress streams. Call in `dispose()` if needed.
  void disposeUploadProgress() {
    for (var controller in _progressControllers.values) {
      if (!controller.isClosed) controller.close();
    }
    _progressControllers.clear();
  }
}
