// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';

class ImageEditor extends StatelessWidget {
  const ImageEditor({super.key, required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
    return ProImageEditor.file(
      file,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (bytes) async {
          // final editedFile = await file.writeAsBytes(bytes);
          // Get a temp directory
          final tempDir = await getTemporaryDirectory();
          final newPath =
              '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_edited.png';
          final editedFile = await File(newPath).writeAsBytes(bytes);

          if (context.mounted) Navigator.of(context).pop(editedFile);
        },
      ),
    );
  }
}
