import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'filepond_platform_interface.dart';

/// An implementation of [FilepondPlatform] that uses method channels.
class MethodChannelFilepond extends FilepondPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('filepond');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
