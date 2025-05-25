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

class _FilePonderScreenState extends State<FilePonderScreen> {
  var controller = FilepondController(
    baseUrl: 'http://localhost:3010/upload',
    pondLocation: 'filepond/a/b/c',
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Filepond(controller: controller)));
  }
}
