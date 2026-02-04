// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:filepond/src/components/file_item_widget.dart';
import 'package:filepond/src/components/image_item_widget.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:filepond/src/utils/file_utils.dart';
import 'package:flutter/material.dart';
// import 'package:path/path.dart' show basename, extension;

class FileItem extends StatefulWidget {
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
  final void Function()? onRemove;
  @override
  State<FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<FileItem> {
  StreamSubscription? _subscription;
  FilepondWidgetType? type;
  @override
  void initState() {
    type = FileUtils.getFileType(widget.file.fileName!);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FileItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('updated');
    // This method is called whenever the widget configuration changes.
    // If the 'file' property (the FilepondFile object itself) changes
    // (which it does when you do .copyWith in the controller),
    // this will be triggered, and a rebuild will naturally follow.
    // print('FileItem didUpdateWidget: ${widget.file.fileName} - ${widget.file.uploading}');
  }

  // FilepondFile? file;
  // FilepondWidgetType? type;
  // @override
  // void initState() {
  //   WidgetsBinding.instance.addPostFrameCallback((callback) {
  //     if (mounted) {
  //       var controller = Filepond.controllerOf(context);
  //       if (controller.files.isEmpty) return;
  //       file = controller.files[widget.index];
  //       //
  //       // attach uploaded file
  //       if (mounted) setState(() {});
  //       //

  //       type = FileUtils.getFileType(file!.fileName!);
  //       print(type);
  //       _subscription = controller.operationsStream.listen((operation) {
  //         print(operation.type);
  //         switch (operation.type) {
  //           case UploadOperationType.uploaded:
  //             if (operation.file != null && operation.file!.id == file!.id) {
  //               file = operation.file!;
  //               if (mounted) setState(() {});
  //             }
  //             break;
  //           case UploadOperationType.uploading:
  //             if (operation.file != null && operation.file!.id == file!.id) {
  //               file = operation.file!;
  //               if (mounted) setState(() {});
  //             }
  //             break;
  //           case UploadOperationType.update:
  //             if (operation.file != null && operation.file!.id == file!.id) {
  //               file = operation.file!;
  //               log(file.toString());
  //               if (mounted) setState(() {});
  //             }
  //             break;
  //           default:
  //         }
  //       });
  //     }
  //   });
  //   super.initState();
  // }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var baseUrl = Filepond.of(context).baseUrl;
    var size = MediaQuery.sizeOf(context);
    var theme = Theme.of(context);
    print('rebuilded'); // controller.operationsStream.lis

    switch (type) {
      case FilepondWidgetType.file:
        return ScaleTransition(
          scale: widget.animation,

          child: FileItemWidget(file: widget.file, onRemove: widget.onRemove),
        );
      case FilepondWidgetType.image:
        var widgetHeight = 200.0;
        return ScaleTransition(
          scale: widget.animation,
          child: ImageItemWidget(
            file: widget.file,
            width: size.width,
            onRemove: widget.onRemove,
            widgetHeight: widgetHeight,
            theme: theme,
            // controller: controller,
          ),
        );
      default:
        return Text('no type');
    }
  }
}
