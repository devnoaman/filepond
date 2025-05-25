// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:filepond/filepond.dart';
import 'package:filepond/src/components/dashed_container.dart';
import 'package:filepond/src/components/file_item.dart';
import 'package:filepond/src/controller/filepond_operation.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FilepondWidget extends StatefulWidget {
  const FilepondWidget({
    super.key,

    // required this.controller
  });

  @override
  State<FilepondWidget> createState() => _FilepondWidgetState();
}

class _FilepondWidgetState extends State<FilepondWidget> {
  late List<FilepondFile> filesList;
  String? fileIcon;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  Future<String> loadSvgAndChangeColor({String color = "#2196F3"}) async {
    // Load SVG as string from assets
    String svgString = await rootBundle.loadString(
      'packages/filepond/lib/src/assets/svg/folder-open-svgrepo-com.svg',
    );
    // Replace any hex color in the SVG with the desired color
    // This regex matches hex colors like #FFF, #FFFFFF, #ffffffff
    final hexColorRegExp = RegExp(r'#[0-9a-fA-F]{3,8}');
    svgString = svgString.replaceAll(hexColorRegExp, color);
    return svgString;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((s) async {
      var controller = Filepond.controllerOf(context);
      filesList = List.from(controller.files);
      // fileIcon = await loadSvgAndChangeColor();
      controller.operationsStream.listen((operation) {
        switch (operation.type) {
          case UploadOperationType.insert:
            filesList = List.from(controller.files);
            _listKey.currentState!.insertItem(operation.index ?? 0);

          case UploadOperationType.remove:
            if (operation.index != null) {
              _listKey.currentState!.removeItem(
                operation.index!,
                (context, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0),
                    end: Offset(-1, 0), // Slide to the left when removed
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: ListTile(title: Text('...')),
                ),
              );
              filesList = List.from(controller.files);
            }
            break;
          case UploadOperationType.uploaded:
            break;
          case UploadOperationType.dublicate:
          default:
        }
      });
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DashedContainer(
                width: double.infinity,
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder(
                      future: loadSvgAndChangeColor(
                        color:
                            '#${Theme.of(context).primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                      ),
                      builder:
                          (context, snapshot) =>
                              snapshot.hasData
                                  ? SvgPicture.string(snapshot.data!)
                                  : SizedBox(),
                    ),
                    Container(
                      height: 45,
                      child: Center(child: Text('Drag & Drop or Browse')),
                    ),
                  ],
                ),
              ),
            ),

            // FutureBuilder(
            //   builder:
            //       (context, snapshot) =>
            //           snapshot.hasData
            //               ? SvgPicture.string(
            //                 // snapshot.data!,
            //                 'packages/filepond/lib/src/assets/svg/folder-open-svgrepo-com.svg',
            //                 // fileIcon!,
            //               )
            //               : SizedBox(),
            //   future: loadSvgAndChangeColor(),
            // ),

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
