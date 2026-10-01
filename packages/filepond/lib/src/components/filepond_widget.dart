// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:filepond/filepond.dart';
import 'package:filepond/src/components/dashed_container.dart';
import 'package:filepond/src/components/file_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';

typedef FilepondBuilder =
    Widget Function(
      BuildContext context,
      FilepondController controller,
      bool isAttaching,
    );
typedef SubTitleBuilder =
    String Function(BuildContext context, FilepondController controller);
typedef FilepondWidgetBuilder = FilepondBuilder;

typedef FilepondItemBuilder =
    Widget Function(
      BuildContext context,
      FilepondFile file,
      int index,
      Animation<double> animation,
      VoidCallback onRemove,
    );

typedef FilepondFileItemBuilder = FilepondItemBuilder;

class FilepondWidget extends StatefulWidget {
  const FilepondWidget({
    super.key,
    this.title,
    this.subTitle,

    this.builder,
    this.itemBuilder,
    this.subTitleBuilder,
    // required this.controller
  });
  final String? title;
  final String? subTitle;
  final FilepondBuilder? builder;
  final FilepondItemBuilder? itemBuilder;
  final SubTitleBuilder? subTitleBuilder;

  @override
  State<FilepondWidget> createState() => _FilepondWidgetState();
}

class _FilepondWidgetState extends State<FilepondWidget> {
  // late List<FilepondFile> filesList;
  final List<FilepondFile> _filesList =
      []; // Changed to private _filesList for clarity
  //
  String? fileIcon;
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
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

  FilepondController? _controller;
  StreamSubscription<FilepondOperation>? _operationSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Filepond.controllerOf(context);
    if (identical(controller, _controller)) return;

    // Subscribe once per controller; re-subscribing on every dependency
    // change duplicated every event.
    _operationSubscription?.cancel();
    // A new controller means a new list: rebuild the AnimatedList from scratch.
    if (_controller != null) _listKey = GlobalKey<AnimatedListState>();
    _controller = controller;
    _filesList
      ..clear()
      ..addAll(controller.files);
    _operationSubscription = controller.operationsStream.listen(_onOperation);
  }

  @override
  void dispose() {
    _operationSubscription?.cancel();
    super.dispose();
  }

  void _onRemoveFile(FilepondFile fileToRemove) {
    _controller?.removeFile(fileToRemove);
  }

  /// Replaces the local copy of a file (matched by id) after a status change.
  void _replaceById(String id, FilepondFile file) {
    final i = _filesList.indexWhere((f) => f.id == id);
    if (i != -1) _filesList[i] = file;
  }

  void _onOperation(FilepondOperation operation) {
    if (!mounted) return;
    final file = operation.file;

    switch (operation.type) {
      case UploadOperationType.insert:
        final index = operation.index;
        if (file != null &&
            index != null &&
            !_filesList.any((f) => f.id == file.id)) {
          final at = index < 0
              ? 0
              : (index > _filesList.length ? _filesList.length : index);
          _filesList.insert(at, file);
          _listKey.currentState?.insertItem(at);
        }
      case UploadOperationType.remove:
        final index = file == null
            ? -1
            : _filesList.indexWhere((f) => f.id == file.id);
        if (index != -1) {
          final removedFile = _filesList.removeAt(index);
          _listKey.currentState?.removeItem(
            index,
            (context, animation) =>
                _buildRemovedItem(context, removedFile, index, animation),
            duration: const Duration(milliseconds: 300),
          );
        }
      case UploadOperationType.uploading:
      case UploadOperationType.uploaded:
      case UploadOperationType.failed:
        if (file != null) _replaceById(file.id, file);
      case UploadOperationType.update:
        final oldFile = operation.oldFile;
        if (oldFile != null && file != null) _replaceById(oldFile.id, file);
      case UploadOperationType.dublicate:
        break;
    }

    setState(() {});
  }

  Widget _buildRemovedItem(
    BuildContext context,
    FilepondFile removedFile,
    int index,
    Animation<double> animation,
  ) {
    final child = widget.itemBuilder != null
        ? widget.itemBuilder!(context, removedFile, index, animation, () {})
        : FileItem(
            key: ObjectKey(removedFile),
            file: removedFile,
            animation: animation,
            index: index,
          );
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1, 0),
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }

  String _subTitle(BuildContext context, FilepondController controller) {
    if (widget.subTitleBuilder != null) {
      return widget.subTitleBuilder!(context, controller);
    }
    return widget.subTitle ?? 'Select only ${controller.maxLength}';
  }

  @override
  Widget build(BuildContext context) {
    var controller = Filepond.controllerOf(context);
    var theme = Theme.of(context);
    AttachingNotifier notifier = controller.notifier;
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: notifier.isAttaching,
            builder: (context, v, c) {
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
                        await controller.attachFile();
                      },
                child: widget.builder != null
                    ? widget.builder!(context, controller, v)
                    : switch (controller.sourceType) {
                        // null => throw UnimplementedError(),

                        // SourceType.files => throw UnimplementedError(),
                        SourceType.gallery => DashedContainer(
                          width: double.infinity,
                          height: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.gallery,
                                size: 40,
                                color: theme.primaryColor,
                              ),
                              SizedBox(
                                height: 45,
                                child: Center(
                                  child: Text(
                                    widget.title ?? 'Select image',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                              if (controller.maxLength != null)
                                SizedBox(
                                  height: 45,
                                  child: Center(
                                    child: Text(_subTitle(context, controller)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // TODO: Handle this case.
                        SourceType.camera => DashedContainer(
                          width: double.infinity,
                          height: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              v
                                  ? Center(
                                      child:
                                          CircularProgressIndicator.adaptive(),
                                    )
                                  : Icon(
                                      Iconsax.camera,
                                      size: 40,
                                      color: theme.primaryColor,
                                    ),
                              SizedBox(
                                height: 45,
                                child: Center(
                                  child: Text(
                                    v == true
                                        ? 'processing image, please wait ..'
                                        : widget.title ?? 'Open camera',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                              if (controller.maxLength != null)
                                SizedBox(
                                  height: 45,
                                  child: Center(
                                    child: Text(_subTitle(context, controller)),
                                  ),
                                ),
                            ],
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
                                            '#${Theme.of(context).primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
                                      ),
                                      builder: (context, snapshot) =>
                                          snapshot.hasData
                                          ? SvgPicture.string(snapshot.data!)
                                          : SizedBox(),
                                    ),
                                    SizedBox(
                                      height: 45,
                                      child: Center(
                                        child: Text(
                                          widget.title ?? 'Browse files',
                                        ),
                                      ),
                                    ),
                                    if (controller.maxLength != null)
                                      SizedBox(
                                        height: 45,
                                        child: Center(
                                          child: Text(
                                            _subTitle(context, controller),
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
                  if (widget.itemBuilder != null) {
                    return widget.itemBuilder!(
                      context,
                      file,
                      index,
                      animation,
                      () => _onRemoveFile(file),
                    );
                  }
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
          ),
        ],
      ),
    );
  }
}
