// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'dart:io';

import 'package:filepond/filepond.dart';
import 'package:filepond/src/components/file_item.dart';
import 'package:filepond/src/controller/filepond_operation.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:flutter/material.dart';

class FilepondWidget extends StatefulWidget {
  const FilepondWidget({
    super.key,

    // required this.controller
  });
  // final FilepondController controller;

  @override
  State<FilepondWidget> createState() => _FilepondWidgetState();
}

class _FilepondWidgetState extends State<FilepondWidget> {
  // var filesList = <File>[];
  late List<FilepondFile> filesList;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((s) {
      var controller = Filepond.controllerOf(context);
      filesList = List.from(controller.files);

      controller.operationsStream.listen((operation) {
        switch (operation.type) {
          case UploadOperationType.insert:
            _listKey.currentState!.insertItem(operation.index ?? 0);
            filesList = List.from(controller.files);

            print(operation.type);
          // TODO: Handle this case.
          //   throw UnimplementedError();
          case UploadOperationType.uploaded:
            print(operation.type);
            print(operation.index);
          // TODO: Handle this case.
          //   throw UnimplementedError();
          // case UploadOperationType.update:
          //   // TODO: Handle this case.
          //   throw UnimplementedError();
          // case UploadOperationType.failed:
          //   // TODO: Handle this case.
          //   throw UnimplementedError();
          // case UploadOperationType.remove:
          //   // TODO: Handle this case.
          //   throw UnimplementedError();
          default:
            print(operation.type);
        }
      });
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // @override
  // void didUpdateWidget(covariant FilepondWidget oldWidget) {
  //   var controller = Filepond.controllerOf(context);

  //   log('depend change');
  //   log(filesList.length.toString());
  //   super.didUpdateWidget(oldWidget);
  //   if (controller.files.isEmpty) {
  //     filesList = [];
  //     setState(() {});
  //   }
  //   filesList = List.from(controller.files);
  // }

  @override
  Widget build(BuildContext context) {
    var controller = Filepond.controllerOf(context);
    return RawMaterialButton(
      fillColor: Colors.grey.shade300,
      elevation: 0,
      shape: RoundedRectangleBorder(
        //  color: ,
        borderRadius: BorderRadius.circular(12),
      ),

      onPressed: () async {
        controller.attachFile();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 45,
              child: Center(child: Text('Drag & Drop or Browse')),
            ),
            // if (filesList.isNotEmpty)
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: AnimatedList(
                initialItemCount: controller.files.length,
                shrinkWrap: true,
                key: _listKey,
                itemBuilder: (
                  BuildContext context,
                  int index,
                  Animation<double> animation,
                ) {
                  return FileItem(index: index, animation: animation);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
