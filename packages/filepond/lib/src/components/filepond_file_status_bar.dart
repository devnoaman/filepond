import 'package:filepond/src/components/filepond.dart';
import 'package:filepond/src/controller/controller.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:filepond/src/models/filepond_file_status.dart';
import 'package:flutter/material.dart';

/// Compact per-file upload status, ready to drop into an item builder.
///
/// | Status      | Shows                                |
/// |-------------|--------------------------------------|
/// | `pending`   | progress bar at 0                    |
/// | `uploading` | live progress bar (0..1)             |
/// | `uploaded`  | nothing                              |
/// | `failed`    | error text + retry button            |
///
/// Uses [controller] when given, otherwise `Filepond.controllerOf(context)`.
class FilepondFileStatusBar extends StatelessWidget {
  const FilepondFileStatusBar({
    super.key,
    required this.file,
    this.controller,
    this.failedText = 'Upload failed',
    this.retryText = 'Retry',
    this.showErrorDetails = true,
  });

  final FilepondFile file;
  final FilepondController? controller;

  /// Headline shown for a failed file.
  final String failedText;

  /// Label of the retry button.
  final String retryText;

  /// Whether to show [FilepondFile.error] below [failedText].
  final bool showErrorDetails;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? Filepond.controllerOf(context);
    final theme = Theme.of(context);

    switch (file.status) {
      case FilepondFileStatus.uploaded:
        return const SizedBox.shrink();
      case FilepondFileStatus.pending:
        return const _Bar(key: ValueKey('filepond-progress'), value: 0);
      case FilepondFileStatus.uploading:
        return StreamBuilder<double>(
          stream: controller.getUploadProgress(file.id),
          initialData: controller.getLatestProgress(file.id),
          builder: (context, snapshot) => _Bar(
            key: const ValueKey('filepond-progress'),
            value: snapshot.data ?? 0,
          ),
        );
      case FilepondFileStatus.failed:
        final color = theme.colorScheme.error;
        return Row(
          key: const ValueKey('filepond-failed'),
          children: [
            Icon(Icons.error_outline, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    failedText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showErrorDetails && (file.error?.isNotEmpty ?? false))
                    Text(
                      file.error!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                ],
              ),
            ),
            TextButton.icon(
              key: const ValueKey('filepond-retry'),
              onPressed: () => controller.retryUpload(file),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(retryText),
            ),
          ],
        );
    }
  }
}

class _Bar extends StatelessWidget {
  const _Bar({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: const Duration(milliseconds: 200),
        builder: (context, v, _) =>
            LinearProgressIndicator(value: v, minHeight: 4),
      ),
    );
  }
}
