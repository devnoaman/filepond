import 'package:filepond/src/components/filepond_widget.dart';
import 'package:flutter/widgets.dart';

import '../controller/controller.dart';

class Filepond extends InheritedWidget {
  Filepond({super.key, required this.controller, this.title})
    : super(child: FilepondWidget(title: title));
  // static FilepondController _initController(FilepondController? cnt) {
  //   return cnt ?? FilepondController(baseUrl: 'localhost:3000');
  // }

  /// a Url wich will used to upload files to it
  final String? title;
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
    return oldWidget.controller != controller;
  }
}
