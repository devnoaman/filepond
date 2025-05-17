import 'package:filepond/filepond.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = FilepondController(
      baseUrl: 'http://localhost:3010/upload',
    );
    controller.operationsStream.listen((onData) {
      print(onData.toString());
    });
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Filepond(
            // baseUrl: 'http://localhost:3010/upload',
            controller: controller,
          ),
        ),
      ),
    );
  }
}
