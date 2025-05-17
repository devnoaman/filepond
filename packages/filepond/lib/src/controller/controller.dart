// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filepond/src/controller/filepond_operation.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:filepond/src/upload_file_mixin.dart';
import 'package:path/path.dart';

// mixin UploadProgressMixin {
//   void onUploadProgress(int sentBytes, int totalBytes) {
//     final percent = (sentBytes / totalBytes * 100).toStringAsFixed(2);
//     print('Upload progress: $sentBytes / $totalBytes ($percent%)');
//     // You could also use a callback or stream here to report progress to UI
//   }
// }

class FilepondController with UploadProgressMixin {
  var files = <FilepondFile>[];
  final String baseUrl;
  FilepondController({required this.baseUrl});
  final _operationsController = StreamController<FilepondOperation>.broadcast();
  Stream<FilepondOperation> get operationsStream =>
      _operationsController.stream;

  attachFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      // filesList.add(file);

      // filesList.indexOf(file);
      // filesList.insert(index, _nextItem);
      var filepondFile = FilepondFile(id: file.path, file: file);
      files.add(filepondFile);

      final int index = files.indexOf(filepondFile);

      // _listKey.currentState!.insertItem(index);
      // setState(() {});
      print(file.path);
      _operationsController.add(FilepondOperation.insert(filepondFile, index));
    } else {
      // User canceled the picker
    }
  }

  uploadFile(FilepondFile file) async {
    Dio dio = Dio()..interceptors.addAll([AwesomeDioInterceptor()]);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.file.path,
        filename: basename(file.file.path),
      ),
    });
    final id = file.file.path; // or UUID if preferred
    final int index = files.indexOf(file);

    var res = await dio.post(
      baseUrl,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) {
          updateUploadProgress(id, sent / total);
        }
      },
    );
    if (res.statusCode == 200) {
      _operationsController.add(FilepondOperation.uploaded(file, index));

      files =
          files
              .map(
                (e) =>
                    e.id == file.id
                        ? e.copyWith(filepond: res.data['filepond'])
                        : e,
              )
              .toList();
    }
  }
}
