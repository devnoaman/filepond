import 'package:filepond/src/utils/logger.dart';
import 'package:flutter/widgets.dart';

class AttachingNotifier {
  
  final ValueNotifier<bool> isAttaching = ValueNotifier<bool>(false);

  void attaching() {
    Logger.warn(message: 'calling attaching');
    isAttaching.value = true;
  }

  void attached() {
    isAttaching.value = false;
  }
}
