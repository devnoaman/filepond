import 'package:path/path.dart' as p;

enum FilepondWidgetType { file, image, undefined }

class FileUtils {
  FileUtils._();
  static FilepondWidgetType getFileType(String path) {
    final extension = p.extension(path);
    switch (extension) {
      case '.pdf':
        print('pdf file');
        return FilepondWidgetType.file;

      case '.png':
      case '.jpg':
      case '.jpeg':
        return FilepondWidgetType.image;
      default:
        return FilepondWidgetType.undefined;
    }
  }
}
