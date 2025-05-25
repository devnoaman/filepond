// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:developer';

import 'package:filepond/src/components/file_item_widget.dart';
import 'package:filepond/src/components/filepond.dart';
import 'package:filepond/src/components/image_item_widget.dart';
import 'package:filepond/src/controller/filepond_operation.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:filepond/src/utils/file_utils.dart';
import 'package:flutter/material.dart';
// import 'package:path/path.dart' show basename, extension;

class FileItem extends StatefulWidget {
  const FileItem({super.key, required this.index, required this.animation});
  // final FilepondFile file;
  final int index;
  final Animation<double> animation;

  @override
  State<FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<FileItem> {
  FilepondFile? file;
  FilepondWidgetType? type;
  @override
  void initState() {
    WidgetsBinding.instance.addPersistentFrameCallback((callback) {
      if (mounted) {
        var controller = Filepond.controllerOf(context);
        file = controller.files[widget.index];
        //
        // attach uploaded file
        setState(() {});
        //

        type = FileUtils.getFileType(file!.file.path);
        controller.operationsStream.listen((operation) {
          print(operation.type);
          switch (operation.type) {
            case UploadOperationType.uploaded:
              if (operation.file != null && operation.file!.id == file!.id) {
                file = operation.file!;
                setState(() {});
              }
              break;
            case UploadOperationType.update:
              if (operation.file != null && operation.file!.id == file!.id) {
                file = operation.file!;
                log(file.toString());
                setState(() {});
              }
              break;
            default:
          }
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // var baseUrl = Filepond.of(context).baseUrl;
    var size = MediaQuery.sizeOf(context);
    var theme = Theme.of(context);
    var controller = Filepond.controllerOf(context);
    print('rebuilded'); // controller.operationsStream.lis

    switch (type) {
      case FilepondWidgetType.file:
        return ScaleTransition(
          scale: widget.animation,
          child: FileItemWidget(file: file, controller: controller),
        );
      case FilepondWidgetType.image:
        var widgetHeight = 200.0;
        return ScaleTransition(
          scale: widget.animation,
          child: ImageItemWidget(
            file: file,
            width: size.width,
            widgetHeight: widgetHeight,
            theme: theme,
            controller: controller,
          ),
        );
      default:
        return Text('no type');
    }
  }
}
