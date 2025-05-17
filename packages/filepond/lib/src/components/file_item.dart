// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'package:filepond/src/components/filepond.dart';
import 'package:filepond/src/controller/filepond_operation.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;

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
  @override
  void initState() {
    WidgetsBinding.instance.addPersistentFrameCallback((callback) {
      var controller = Filepond.controllerOf(context);
      file = controller.files[widget.index];
      //
      // attach uploaded file
      setState(() {});
      //
      controller.operationsStream.listen((operation) {
        if (operation.type == UploadOperationType.uploaded) {
          //
          if (operation.file != null && operation.file!.id == file!.id) {
            file = operation.file!;
            setState(() {});
          }
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // var baseUrl = Filepond.of(context).baseUrl;
    var controller = Filepond.controllerOf(context);

    // controller.operationsStream.lis

    return ScaleTransition(
      scale: widget.animation,
      child: Card(
        child: ListTile(
          tileColor: file?.filepond != null ? Colors.green : null,
          
          title:
              file == null
                  ? LinearProgressIndicator()
                  : Text(basename(file!.file.path)),
          leading: IconButton(onPressed: () {}, icon: Icon(Icons.close)),
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
      ),
    );
  }
}
