import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:filepond/filepond.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // controller.operationsStream.listen((onData) {});
    return MaterialApp(home: FilePonderScreen());
  }
}

class FilePonderScreen extends StatefulWidget {
  const FilePonderScreen({super.key});

  @override
  State<FilePonderScreen> createState() => _FilePonderScreenState();
}

var token =
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL3VhdC5ndWRlYS5nb3YuaXEvYXBpL3YxL2F1dGgvbG9naW4iLCJpYXQiOjE3NzkwODk0MDAsImV4cCI6MTc3OTA5MzAwMCwibmJmIjoxNzc5MDg5NDAwLCJqdGkiOiJCdWMzR1oyTEFGMTdkVGs3Iiwic3ViIjoiMTUiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3In0.euFQyl6qgZIUsFW8ZsACIExBm3osApOz1gYeoZSvSjA';

class _FilePonderScreenState extends State<FilePonderScreen> {
  Dio dio = Dio()
    ..interceptors.addAll([AwesomeDioInterceptor()])
    ..options.headers = {'Authorization': 'Bearer $token'};
  late FilepondController controller;
  @override
  void initState() {
    controller = FilepondController(
      // baseUrl: 'http://10.10.10.195:3010/upload',
      baseUrl: 'https://uat.gudea.gov.iq/api/v1/inspector/report-file-upload',
      pondLocation: '',
      dioClient: dio,
      uploadName: 'exterior_image_photos[0]',
      uploadDirectly: true,
      maxLength: 3,
      sourceType: SourceType.gallery,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Filepond(
            controller: controller,
            builder: (context, controller, isAttaching) {
              if (isAttaching) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator.adaptive(),
                        SizedBox(height: 12),
                        Text('Attaching files...'),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 44,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Custom Builder: Tap to select images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selected: ${controller.files.length} / ${controller.maxLength ?? '∞'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
            itemBuilder: (context, file, index, animation, onRemove) {
              return SizeTransition(
                sizeFactor: animation,
                child: StreamBuilder<double>(
                  stream: controller.getUploadProgress(file.id),
                  initialData: controller.getLatestProgress(file.id),
                  builder: (context, snapshot) {
                    final progress = snapshot.data ?? 0.0;
                    final isUploaded = file.filepond != null;
                    final isUploading =
                        file.uploading || (progress > 0.0 && progress < 1.0);

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUploaded
                              ? Colors.green.shade300
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  file.file,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.insert_drive_file,
                                          size: 24,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.fileName ?? 'Unknown file',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isUploading
                                          ? 'Ponding upload: ${(progress * 100).toInt()}%'
                                          : (isUploaded
                                                ? 'Uploaded successfully'
                                                : '${(file.file.lengthInBytes / 1024).toStringAsFixed(1)} KB'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isUploading
                                                ? Colors.orange.shade800
                                                : (isUploaded
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade600),
                                            fontWeight:
                                                (isUploading || isUploaded)
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUploading)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator.adaptive(
                                    value: progress > 0 ? progress : null,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              else if (!isUploaded)
                                IconButton(
                                  tooltip: 'Upload',
                                  icon: const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () => controller.uploadFile(file),
                                )
                              else
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: onRemove,
                              ),
                            ],
                          ),
                          if (isUploading) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress > 0 ? progress : null,
                                minHeight: 4,
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
