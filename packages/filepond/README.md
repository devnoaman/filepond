# filepond

A Dart package providing file management components for your Flutter applications.

## Features

- Easy-to-use file picker and uploader components
- Customizable UI for file selection and upload progress
- Supports multiple file types

## Installation

Add the following to your `pubspec.yaml`:

```sh
flutter pub add filepond
```

Then run:

```sh
flutter pub get
```

## Usage

Import the package in your Dart code:

```dart
import 'package:filepond/filepond.dart';
```

Wrap your widget tree with the `Filepond` widget and provide a controller:

```dart
import 'package:filepond/filepond.dart';

class MyFileUploader extends StatelessWidget {
  final controller = FilepondController(baseUrl: 'http://localhost:3000/upload');

  @override
  Widget build(BuildContext context) {
    return Filepond(
      controller: controller,
      // FilepondWidget is used internally as the child
    );
  }
}
```

To access the controller anywhere in the widget subtree, use:

```dart
final controller = Filepond.controllerOf(context);
```

You can then call upload methods or listen to progress using the controller.

## Example

See the [`apps/example`](../../apps/example) app for a complete usage example.

## License

MIT