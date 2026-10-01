import 'dart:async';

/// A mixin to track upload progress for one or more files.
///
/// Each file id gets one broadcast stream that stays open across retries, so
/// a widget subscribed once keeps receiving values when the file is
/// re-uploaded. Streams are closed by [clearUploadProgress] (when the file is
/// removed) or [disposeUploadProgress].
mixin UploadProgressMixin {
  final Map<String, StreamController<double>> _progressControllers = {};
  final Map<String, double> _latestProgress = {};

  /// Get the current/latest progress value (between 0.0 and 1.0) for a specific file [id].
  double getLatestProgress(String id) => _latestProgress[id] ?? 0.0;

  /// Subscribe to a file's upload progress using its [id].
  Stream<double> getUploadProgress(String id) {
    final existing = _progressControllers[id];
    if (existing != null && !existing.isClosed) return existing.stream;

    final controller = StreamController<double>.broadcast();
    _progressControllers[id] = controller;
    return controller.stream;
  }

  /// Update the progress (value between 0.0 and 1.0) for a specific file ID.
  void updateUploadProgress(String id, double progress) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final rounded = clamped == 0.0
        ? 0.0
        : clamped < 0.01
        ? 0.01
        : clamped > 0.99
        ? 1.0
        : (clamped * 100).round() / 100;

    _latestProgress[id] = rounded;

    final controller = _progressControllers[id];
    if (controller != null && !controller.isClosed) {
      controller.add(rounded);
    }
  }

  /// Resets the progress of [id] to 0 (e.g. when a retry starts), so the UI
  /// doesn't show the previous attempt's last value.
  void resetUploadProgress(String id) => updateUploadProgress(id, 0);

  /// Close and remove the stream controller for a specific file ID.
  void clearUploadProgress(String id) {
    final controller = _progressControllers.remove(id);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _latestProgress.remove(id);
  }

  /// Dispose all upload progress streams. Call in `dispose()` if needed.
  void disposeUploadProgress() {
    for (final controller in _progressControllers.values) {
      if (!controller.isClosed) controller.close();
    }
    _progressControllers.clear();
    _latestProgress.clear();
  }
}
