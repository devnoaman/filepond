// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:filepond/filepond.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;

/// Default tile for non-image files: name, status (progress / error + retry),
/// and upload / remove actions.
class FileItemWidget extends StatelessWidget {
  const FileItemWidget({super.key, required this.file, this.onRemove});

  final FilepondFile? file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final controller = Filepond.controllerOf(context);
    final file = this.file;
    final theme = Theme.of(context);

    if (file == null) return const Card(child: LinearProgressIndicator());

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: switch (file.status) {
            FilepondFileStatus.uploaded => Colors.green,
            FilepondFileStatus.failed => theme.colorScheme.error,
            _ => Colors.transparent,
          },
        ),
      ),
      child: ListTile(
        leading: IconButton(
          tooltip: 'Remove',
          onPressed: onRemove ?? () => controller.removeFile(file),
          icon: const Icon(Icons.close),
        ),
        title: Text(basename(file.fileName ?? ''), maxLines: 1),
        subtitle: file.isUploaded
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilepondFileStatusBar(file: file, controller: controller),
              ),
        trailing: switch (file.status) {
          FilepondFileStatus.uploaded => const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          FilepondFileStatus.pending => IconButton(
            tooltip: 'Upload',
            onPressed: () => controller.uploadFile(file),
            icon: const Icon(Icons.upload),
          ),
          _ => null,
        },
      ),
    );
  }
}
