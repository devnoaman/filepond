// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:filepond/src/components/file_item_widget.dart';
import 'package:filepond/src/components/image_item_widget.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:filepond/src/utils/file_utils.dart';
import 'package:flutter/material.dart';

/// Default item used by `FilepondWidget`: an image preview for images and a
/// tile for every other file type. Both show the file's upload status.
class FileItem extends StatelessWidget {
  const FileItem({
    required this.file,
    super.key,
    required this.index,
    required this.animation,
    this.onRemove,
  });
  final FilepondFile file;
  final int index;
  final Animation<double> animation;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final type = FileUtils.getFileType(file.fileName ?? file.id);

    return ScaleTransition(
      scale: animation,
      child: switch (type) {
        FilepondWidgetType.image => ImageItemWidget(
          file: file,
          width: MediaQuery.sizeOf(context).width,
          onRemove: onRemove,
          widgetHeight: 200,
          theme: Theme.of(context),
        ),
        _ => FileItemWidget(file: file, onRemove: onRemove),
      },
    );
  }
}
