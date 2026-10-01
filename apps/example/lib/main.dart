import 'package:flutter/material.dart';

import 'basic/basic_usage_page.dart';
import 'lab/upload_lab_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filepond Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const ExamplesHome(),
    );
  }
}

/// Switches between the basic integration and the Upload Lab, keeping
/// each page's state alive.
class ExamplesHome extends StatefulWidget {
  const ExamplesHome({super.key});

  @override
  State<ExamplesHome> createState() => _ExamplesHomeState();
}

class _ExamplesHomeState extends State<ExamplesHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [BasicUsagePage(), UploadLabPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.attach_file),
            label: 'Basic usage',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            label: 'Upload Lab',
          ),
        ],
      ),
    );
  }
}
