// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

class Logger {
  final String? logPrefix;
  Logger({this.logPrefix});
  factory Logger.warn({required String message}) {
    final logger = Logger(logPrefix: '⚠️ Ponding warning');
    logger.emmit(message);
    return logger;
  }
  void emmit(String message, [StackTrace? stackTrace]) {
    log('''
$logPrefix 
''');
    log('''
$message 
''');
    log('''
$stackTrace 
''');
  }
}
