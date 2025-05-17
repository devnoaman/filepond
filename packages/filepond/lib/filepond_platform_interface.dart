import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'filepond_method_channel.dart';

abstract class FilepondPlatform extends PlatformInterface {
  /// Constructs a FilepondPlatform.
  FilepondPlatform() : super(token: _token);

  static final Object _token = Object();

  static FilepondPlatform _instance = MethodChannelFilepond();

  /// The default instance of [FilepondPlatform] to use.
  ///
  /// Defaults to [MethodChannelFilepond].
  static FilepondPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FilepondPlatform] when
  /// they register themselves.
  static set instance(FilepondPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
