// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:filepond/src/controller/controller.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;

class FileItemWidget extends StatelessWidget {
  const FileItemWidget({
    super.key,
    required this.file,
    required this.controller,
  });

  final FilepondFile? file;
  final FilepondController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        tileColor: file?.filepond != null ? Colors.green : null,

        title:
            file == null
                ? LinearProgressIndicator()
                : Text(basename(file!.file.path)),
        leading: IconButton(
          onPressed: () {
            controller.removeFile(file!);
          },
          icon: Icon(Icons.close),
        ),
        trailing:
            file?.filepond != null
                ? null
                : IconButton(
                  onPressed: () {
                    controller.uploadFile(file!);
                  },
                  icon: Icon(Icons.upload),
                ),
      ),
    );
  }
}
