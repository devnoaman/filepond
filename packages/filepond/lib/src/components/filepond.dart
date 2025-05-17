import 'package:filepond/src/components/filepond_widget.dart';
import 'package:filepond/src/controller/controller.dart';
import 'package:flutter/widgets.dart';

class Filepond extends InheritedWidget {
  Filepond({super.key, required this.controller})
    : super(child: FilepondWidget());
  // static FilepondController _initController(FilepondController? cnt) {
  //   return cnt ?? FilepondController(baseUrl: 'localhost:3000');
  // }

  /// a Url wich will used to upload files to it
  // final String baseUrl;
  final FilepondController controller;
  static Filepond? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Filepond>();
  }

  static Filepond of(BuildContext context) {
    final Filepond? result = maybeOf(context);
    assert(result != null, 'No Filepond found in context');
    return result!;
  }

  /// access controller in the sub tree
  static FilepondController controllerOf(BuildContext context) {
    final Filepond? result = maybeOf(context);
    assert(result != null, 'No Filepond found in context');
    return result!.controller;
  }

  @override
  bool updateShouldNotify(covariant Filepond oldWidget) {
    return true;
  }
}
