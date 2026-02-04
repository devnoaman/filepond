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
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL3VhdC5ndWRlYS5nb3YuaXEvYXBpL3YxL2F1dGgvcmVmcmVzaC10b2tlbiIsImlhdCI6MTc1MDc2Njc5MywiZXhwIjoxNzUxNTQxMTM5LCJuYmYiOjE3NTE1Mzc1MzksImp0aSI6InhmUk9UYmtpTTE2ZjhJSEwiLCJzdWIiOiIxNSIsInBydiI6IjIzYmQ1Yzg5NDlmNjAwYWRiMzllNzAxYzQwMDg3MmRiN2E1OTc2ZjcifQ.GRWz_AiZp1njK8MBW4bLuvbLAQvjkWor9ViXEE1Ao78';

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
          child: Filepond(controller: controller),
        ),
      ),
    );
  }
}
