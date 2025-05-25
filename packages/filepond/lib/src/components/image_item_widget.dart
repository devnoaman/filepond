// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';

import 'package:filepond/src/components/image_editor.dart';
import 'package:filepond/src/controller/controller.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;

class ImageItemWidget extends StatelessWidget {
  const ImageItemWidget({
    super.key,
    required this.file,
    this.width = double.infinity,
    this.widgetHeight = 200.0,
    required this.theme,
    required this.controller,
  });

  final FilepondFile? file;
  final double width;
  final double widgetHeight;
  final ThemeData theme;
  final FilepondController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: file?.filepond != null ? Colors.green : null,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Image.file(file!.file, width: width, height: widgetHeight),
            Container(
              height: widgetHeight,
              width: width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // stops: [1, .8, .6, .4, 0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor.withValues(alpha: .8),
                    // Colors.grey,
                    Colors.transparent,
                    // Colors.grey,
                    theme.primaryColor.withValues(alpha: .8),
                  ],
                ),
              ),
            ),
            ListTile(
              // tileColor:
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
            PositionedDirectional(
              bottom: 16,
              start: 16,
              child: IconButton.filled(
                onPressed: () async {
                  if (file != null && context.mounted) {
                    var newFile = await Navigator.of(context).push<File?>(
                      MaterialPageRoute(
                        builder: (context) => ImageEditor(file: file!.file),
                      ),
                    );
                    if (newFile != null) {
                      print(newFile.path);
                      controller.updateFile(
                        file!,
                        FilepondFile(id: newFile.path, file: newFile),
                        // index,
                        // file!.copyWith(filepond: null, file: newFile),
                      );
                    }
                  }
                },
                icon: Icon(Icons.edit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
