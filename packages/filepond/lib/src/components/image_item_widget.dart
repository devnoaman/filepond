// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';

// import 'package:filepond/filepond.dart';
import 'package:filepond/src/components/image_editor.dart';
// import 'package:filepond/src/models/filepond_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' show basename;
import 'package:square_progress_indicator/square_progress_indicator.dart';

import '../../filepond.dart';

class ImageItemWidget extends StatelessWidget {
  const ImageItemWidget({
    super.key,
    required this.file,
    this.width = double.infinity,
    this.widgetHeight = 200.0,
    required this.theme,
    this.onRemove,
    // required this.controller,
  });

  final FilepondFile? file;
  final double width;
  final double widgetHeight;
  final ThemeData theme;
  final void Function()? onRemove;
  // final FilepondController controller;

  @override
  Widget build(BuildContext context) {
    var controller = Filepond.controllerOf(context);
    // controller.uploadAll();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: switch (file?.status) {
          FilepondFileStatus.uploaded => Colors.green,
          FilepondFileStatus.failed => theme.colorScheme.error,
          _ => null,
        },

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // if (file?.filepond == null)
            // SquareProgressIndicator(width: width, height: widgetHeight),
            Image.memory(
              file!.file,
              width: width,
              height: widgetHeight,
              fit: BoxFit.cover,
            ),
            Container(
              height: widgetHeight,
              width: width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // stops: [.6, 0, .5],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,

                  stops: [
                    0.0,
                    0.8,
                    1.0,
                  ], // shadow starts strong at top, fades downward
                  colors: [
                    theme.primaryColor.withOpacity(0.8), // shadow color at top
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  // colors: [
                  //   theme.primaryColor.withValues(alpha: .8),
                  //   // Colors.grey,
                  //   Colors.transparent,
                  //   // Colors.grey,
                  //   theme.primaryColor.withValues(alpha: .8),
                  // ],
                ),
              ),
            ),
            ListTile(
              // tileColor:
              iconColor: Colors.white,
              title: file == null
                  ? LinearProgressIndicator()
                  : Text(
                      basename(file!.fileName!),
                      maxLines: 2,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(color: Colors.white),
                    ),
              leading: IconButton(
                onPressed: () {
                  if (onRemove != null) {
                    onRemove!.call();
                  } else if (file != null) {
                    controller.removeFile(file!);
                  }
                },
                icon: Icon(Icons.close),
              ),
              trailing: file?.isPending ?? false
                  ? IconButton(
                      tooltip: 'Upload',
                      onPressed: () {
                        controller.uploadFile(file!);
                      },
                      icon: Icon(Icons.upload),
                    )
                  : null,
            ),
            if (controller.allowEdit)
              PositionedDirectional(
                // Sits above the status overlay while the file isn't uploaded.
                bottom: file != null && !file!.isUploaded ? 72 : 16,
                start: 16,
                child: IconButton.filled(
                  onPressed: () async {
                    if (file != null && context.mounted) {
                      var newFile = await Navigator.of(context).push<File?>(
                        MaterialPageRoute(
                          builder: (context) => ImageEditor(
                            file: File(XFile.fromData(file!.file).path),
                          ),
                        ),
                      );
                      if (newFile != null) {
                        controller.updateFile(
                          file!,
                          FilepondFile(
                            id: newFile.path,
                            file: newFile.readAsBytesSync(),
                            fileName: basename(newFile.path),
                          ),
                          // index,
                          // file!.copyWith(filepond: null, file: newFile),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.edit),
                ),
              ),
            // CircularProgressIndicator(),
            if (file?.isUploading ?? false)
              IgnorePointer(
                child: SquareProgressIndicator(
                  width: width,
                  color: Theme.of(context).primaryColor,
                  height: widgetHeight,
                  strokeCap: StrokeCap.round,
                ),
              ),
            if (file != null && !file!.isUploaded)
              PositionedDirectional(
                start: 8,
                end: 8,
                bottom: 8,
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: FilepondFileStatusBar(
                      file: file!,
                      controller: controller,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
