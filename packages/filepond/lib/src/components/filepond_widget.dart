// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';
import 'dart:developer';

import 'package:filepond/filepond.dart';
import 'package:filepond/src/attaching_notifier.dart';
import 'package:filepond/src/components/dashed_container.dart';
import 'package:filepond/src/components/file_item.dart';
import 'package:filepond/src/utils/listener.dart';
import 'package:filepond/src/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';

import '../controller/controller.dart';

class FilepondWidget extends StatefulWidget {
  const FilepondWidget({
    super.key,
    this.title,

    // required this.controller
  });
  final String? title;

  @override
  State<FilepondWidget> createState() => _FilepondWidgetState();
}

class _FilepondWidgetState extends State<FilepondWidget> {
  // late List<FilepondFile> filesList;
  List<FilepondFile> _filesList =
      []; // Changed to private _filesList for clarity
  //
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

  // / Declare variables to hold the controller and stream subscription
  late FilepondController _controller;
  StreamSubscription<FilepondOperation>? _operationSubscription;
  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('FilepondWidgetState: initState called');
    // final newController = Filepond.controllerOf(context);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final controller = Filepond.controllerOf(context);
      _controller = controller;

      if (kDebugMode) {
        print(
          'FilepondWidgetState: Initial _filesList count: ${_filesList.length}',
        );
      }

      // _operationSubscription = _controller.operationsStream.listen;
    });

    // WidgetsBinding.instance.addPostFrameCallback((s) async {
    //   var controller = Filepond.controllerOf(context);
    //   // filesList = List.from(controller.files);
    //   _filesList.addAll(controller.files);

    //   // fileIcon = await loadSvgAndChangeColor();
    // });
  }

  void _onRemoveFile(FilepondFile fileToRemove) {
    if (kDebugMode) {
      print(
        '_FilepondWidgetState: _onRemoveFile called for ${fileToRemove.fileName}',
      );
    }
    var controller = Filepond.controllerOf(context);

    controller.removeFile(fileToRemove); // Make sure this line is reached
    if (kDebugMode) {
      print('_FilepondWidgetState: _controller.removeFile invoked.');
    }
  }

  @override
  void didUpdateWidget(covariant FilepondWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kDebugMode) print('FilepondWidgetState: didUpdateWidget called');
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    final controller = Filepond.controllerOf(context);
    _filesList.addAll(controller.files);
    controller.operationsStream.listen((operation) {
      if (kDebugMode) {
        print('FilepondWidgetState: Operation received: ${operation.type}');
      }

      log(operation.type.toString());

      switch (operation.type) {
        case UploadOperationType.insert:

          // filesList = List.from(controller.files);
          // _listKey.currentState?.insertItem(operation.index ?? 0);
          if (operation.file != null && operation.index != null) {
            if (kDebugMode) {
              print(
                'FilepondWidgetState: Attempting insert at index ${operation.index}',
              );
            }

            if (!_filesList.contains(operation.file)) {
              // 1. Update the local data source FIRST
              _filesList.insert(operation.index!, operation.file!);
              // 2. Tell AnimatedList to animate the insertion
              _listKey.currentState?.insertItem(operation.index!);
            }
          }

          if (mounted) setState(() {});
        // case UploadOperationType.uploading:
        //   filesList = List.from(controller.files);
        // // _listKey.currentState?.insertItem(operation.index ?? 0);

        case UploadOperationType.remove:
          // if (kDebugMode)
          //   print(
          //     'FilepondWidgetState: Attempting remove at index ${operation.index}',
          //   );

          // // Crucial: check bounds before accessing to prevent errors
          // if (operation.index != null &&
          //     operation.index! < _filesList.length) {
          //   if (kDebugMode)
          //     print(
          //       'FilepondWidgetState: _filesList count after data removal: ${_filesList.length}',
          //     );

          // // 1. Get the item to be removed BEFORE it's removed from the list.
          // // This item is needed for the removeItem animation builder.
          // final FilepondFile removedFile = _filesList[operation.index!];

          // // 2. Remove the item from your local data source list
          // _filesList.removeAt(operation.index!);
          // log(_listKey.currentState.toString());
          // // 3. Tell AnimatedList to animate the removal
          // _listKey.currentState?.removeItem(
          //   operation.index!, // Pass the original index to removeItem
          //   (context, animation) => SlideTransition(
          //     position:
          //         Tween<Offset>(
          //           begin: const Offset(
          //             0,
          //             0,
          //           ), // Start from its current position
          //           end: const Offset(
          //             -1,
          //             0,
          //           ), // Animate to the left (off-screen)
          //         ).animate(
          //           CurvedAnimation(
          //             parent: animation,
          //             curve: Curves.easeInOut,
          //           ),
          //         ),
          //     // This child is the widget that will animate out.
          //     // It must be built using the data of the item being removed.
          //     child: FileItem(
          //       file: removedFile,
          //       animation: animation,
          //       index: operation.index!,
          //     ),
          //   ),
          //   duration: const Duration(
          //     milliseconds: 300,
          //   ), // Optional: specify animation duration
          // );

          if (kDebugMode) {
            print(
              'FilepondWidgetState: Attempting remove at index ${operation.index}',
            );
          }
          if (operation.index != null && operation.index! < _filesList.length) {
            final FilepondFile removedFile = _filesList[operation.index!];
            _filesList.removeAt(operation.index!);
            if (kDebugMode) {
              print(
                'FilepondWidgetState: _filesList count after data removal: ${_filesList.length}',
              );
            }

            if (_listKey.currentState == null) {
              if (kDebugMode) {
                print(
                  'ERROR: AnimatedListState is NULL during remove operation!',
                );
              }
            } else {
              _listKey.currentState?.removeItem(
                operation.index!,
                (context, animation) {
                  if (kDebugMode) {
                    print(
                      'FilepondWidgetState: removeItem builder called for index ${operation.index}',
                    );
                  }
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0),
                          end: const Offset(-1, 0),
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                    child: FileItem(
                      key: ObjectKey(removedFile),
                      file: removedFile,
                      animation: animation,
                      index: operation.index!,
                    ),
                  );
                },
                duration: const Duration(
                  milliseconds: 300,
                ), // Keep a visible duration for testing
              );
              if (kDebugMode) {
                print(
                  'FilepondWidgetState: removeItem called on AnimatedListState for index ${operation.index}',
                );
              }
            }
          } else {
            if (kDebugMode) {
              print(
                'FilepondWidgetState: Invalid index or file already removed for operation.index=${operation.index}',
              );
            }
          }
          if (mounted) setState(() {});

          // }
          // if (operation.index != null) {
          //   final removedFile = filesList.removeAt(operation.index!);
          //   _listKey.currentState?.removeItem(
          //     operation.index!,
          //     (context, animation) => SlideTransition(
          //       position:
          //           Tween<Offset>(
          //             begin: Offset(0, 0),
          //             end: Offset(-1, 0), // Slide to the left when removed
          //           ).animate(
          //             CurvedAnimation(
          //               parent: animation,
          //               curve: Curves.easeInOut,
          //             ),
          //           ),
          //       child: ListTile(title: Text('...')),
          //     ),
          //   );
          //   filesList = List.from(controller.files);
          // }
          break;
        // case UploadOperationType.uploading:
        case UploadOperationType.uploaded:
          // filesList = List.from(controller.files);
          // setState(() {});
          if (kDebugMode) {
            print(
              'FilepondWidgetState: Attempting update for index ${operation.index}',
            );
          }

          if (operation.index != null &&
              operation.file != null &&
              operation.index! < _filesList.length) {
            // Update the item in place in your local list
            _filesList[operation.index!] = operation.file!;
            // The `setState` wrapping this `switch` block will cause the `AnimatedList`
            // to rebuild, which in turn will call `itemBuilder` for visible items.
            // If `FileItem` is built with `_filesList[index]`, it will automatically
            // reflect the updated `file` data.
            // setState(() {});
          }
          if (mounted) setState(() {});

          break;

        case UploadOperationType.dublicate:
          break;
        case UploadOperationType.failed:
          log('upload failed ');
          log((controller.files?.length ?? 0).toString());
          log(operation.message?.toString() ?? '');

          // _filesList = controller.files;
          break;
        default:
          if (kDebugMode) {
            print(
              'FilepondWidgetState: Unhandled operation type: ${operation.type}',
            );
          }
          break;
      }

      if (kDebugMode) {
        print('FilepondWidgetState: setState finished for operation.');
      }
      // controller.uploadAll();
    });
  }

  @override
  void dispose() {
    if (kDebugMode) print('FilepondWidgetState: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var controller = Filepond.controllerOf(context);
    var theme = Theme.of(context);
    AttachingNotifier notifier = controller.notifier;
    return SizedBox(
      // fillColor: Colors.grey.shade300,
      // elevation: 0,
      // shape: RoundedRectangleBorder(
      //   //  color: ,
      //   borderRadius: BorderRadius.circular(12),
      // ),

      // onPressed: () async {
      //   controller.attachFile();
      // },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: notifier.isAttaching,
            builder: (context, v, c) {
              Logger.warn(message: 'attaching state $v');
              return RawMaterialButton(
                // fillColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  //  color: ,
                  borderRadius: BorderRadius.circular(12),
                ),

                onPressed: v == true
                    ? null
                    : (controller.maxLength != null &&
                          controller.files.length >= controller.maxLength!)
                    ? null
                    : () async {
                        await controller.attachFile().then((_) {
                          Logger.warn(message: 'files attached');
                        });
                      },
                child: switch (controller.sourceType) {
                  // null => throw UnimplementedError(),

                  // SourceType.files => throw UnimplementedError(),
                  SourceType.gallery => DashedContainer(
                    width: double.infinity,
                    height: 200,
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.gallery,
                            size: 40,
                            color: theme.primaryColor,
                          ),
                          Container(
                            height: 45,
                            child: Center(
                              child: Text(
                                widget.title ?? 'Select image',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                          if (controller.maxLength != null)
                            Container(
                              height: 45,
                              child: Center(
                                child: Text(
                                  'Select only ${controller.maxLength}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // TODO: Handle this case.
                  SourceType.camera => DashedContainer(
                    width: double.infinity,
                    height: 200,
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          v
                              ? Center(
                                  child: CircularProgressIndicator.adaptive(),
                                )
                              : Icon(
                                  Iconsax.camera,
                                  size: 40,
                                  color: theme.primaryColor,
                                ),
                          Container(
                            height: 45,
                            child: Center(
                              child: Text(
                                v == true
                                    ? 'processing image, please wait ..'
                                    : widget.title ?? 'Open camera',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                          if (controller.maxLength != null)
                            Container(
                              height: 45,
                              child: Center(
                                child: Text(
                                  'Select only ${controller.maxLength}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // TODO: Handle this case.
                  // SourceType.ask => throw UnimplementedError(),
                  _ => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DashedContainer(
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
                                builder: (context, snapshot) => snapshot.hasData
                                    ? SvgPicture.string(snapshot.data!)
                                    : SizedBox(),
                              ),
                              Container(
                                height: 45,
                                child: Center(
                                  child: Text(widget.title ?? 'Browse files'),
                                ),
                              ),
                              if (controller.maxLength != null)
                                Container(
                                  height: 45,
                                  child: Center(
                                    child: Text(
                                      'Select only ${controller.maxLength}',
                                    ),
                                  ),
                                ),
                            ],
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
                      ],
                    ),
                  ),
                },
              );
            },
          ),
          // controller.sourceType == SourceType.camera
          //     ? DashedContainer(
          //         width: double.infinity,
          //         height: 200,
          //         child: Container(
          //           child: Column(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               Icon(Icons.camera_alt_outlined, size: 40),
          //               Container(
          //                 height: 45,
          //                 child: Center(
          //                   child: Text(
          //                     'Open camera',
          //                     style: Theme.of(context).textTheme.bodyLarge,
          //                   ),
          //                 ),
          //               ),
          //               if (controller.maxLength != null)
          //                 Container(
          //                   height: 45,
          //                   child: Center(
          //                     child: Text(
          //                       'Select only ${controller.maxLength}',
          //                     ),
          //                   ),
          //                 ),
          //             ],
          //           ),
          //         ),
          //       )
          //     : Padding(
          //         padding: const EdgeInsets.all(16.0),
          //         child: Column(
          //           children: [
          //             Padding(
          //               padding: const EdgeInsets.all(8.0),
          //               child: DashedContainer(
          //                 width: double.infinity,
          //                 height: 200,
          //                 child: Column(
          //                   mainAxisAlignment: MainAxisAlignment.center,
          //                   children: [
          //                     FutureBuilder(
          //                       future: loadSvgAndChangeColor(
          //                         color:
          //                             '#${Theme.of(context).primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
          //                       ),
          //                       builder: (context, snapshot) => snapshot.hasData
          //                           ? SvgPicture.string(snapshot.data!)
          //                           : SizedBox(),
          //                     ),
          //                     Container(
          //                       height: 45,
          //                       child: Center(
          //                         child: Text('Drag & Drop or Browse'),
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),

          //             // FutureBuilder(
          //             //   builder:
          //             //       (context, snapshot) =>
          //             //           snapshot.hasData
          //             //               ? SvgPicture.string(
          //             //                 // snapshot.data!,
          //             //                 'packages/filepond/lib/src/assets/svg/folder-open-svgrepo-com.svg',
          //             //                 // fileIcon!,
          //             //               )
          //             //               : SizedBox(),
          //             //   future: loadSvgAndChangeColor(),
          //             // ),

          //             // if (filesList.isNotEmpty)
          //           ],
          //         ),
          //       ),

          // ListView.builder(shrinkWrap: true,
          // itemCount: controller.files.length,
          // itemBuilder: (context, index) =>  FileItem(index: index,),

          // ),
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            removeLeft: true,
            removeRight: true,
            child: AnimatedList(
              initialItemCount: _filesList
                  .length, // <--- IMPORTANT: Use your local list's length
              physics:
                  const NeverScrollableScrollPhysics(), // Keeps it from scrolling independently
              shrinkWrap: true, // Makes it take only necessary vertical space
              key:
                  _listKey, // The GlobalKey is essential for AnimatedListState methods
              itemBuilder: (BuildContext context, int index, Animation<double> animation) {
                // IMPORTANT: Ensure the index is valid before accessing the list.
                // This prevents `RangeError` if the list changes unexpectedly.
                if (index < _filesList.length) {
                  final file = _filesList[index];
                  return FileItem(
                    key: ValueKey(file.id),
                    file: file,
                    index: index,
                    animation: animation,
                    onRemove: () => _onRemoveFile(file),
                    // onRemove: () => _onRemoveFile(file), // Pass the callback to FileItem
                  );
                }
                // If index is out of bounds, return an empty widget to avoid errors.
                return const SizedBox.shrink();
              },
            ),
            // child: AnimatedList(
            //   initialItemCount: controller.files.length,
            //   physics: NeverScrollableScrollPhysics(),
            //   shrinkWrap: true,
            //   key: _listKey,
            //   itemBuilder:
            //       (
            //         BuildContext context,
            //         int index,
            //         Animation<double> animation,
            //       ) {
            //         return FileItem(
            //           index: index,
            //           animation: animation,
            //           file: filesList[index],
            //         );
            //       },
            // ),
          ),
        ],
      ),
    );
  }
}
