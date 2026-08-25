import 'package:filepond/src/components/filepond_widget.dart';
import 'package:flutter/widgets.dart';

import '../controller/controller.dart';

class Filepond extends InheritedWidget {
  Filepond({
    super.key,
    required this.controller,
    this.title,
    this.subTitle,
    this.builder,
    this.itemBuilder,
    this.subTitleBuilder,
  }) : super(
         child: FilepondWidget(
           title: title,
           subTitle: subTitle,
           builder: builder,
           itemBuilder: itemBuilder,
           subTitleBuilder: subTitleBuilder,
         ),
       );

  final String? title;
  final String? subTitle;
  final FilepondController controller;
  final FilepondBuilder? builder;
  final FilepondItemBuilder? itemBuilder;
  final SubTitleBuilder? subTitleBuilder;
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
