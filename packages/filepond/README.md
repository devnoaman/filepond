# filepond

A Dart package providing file management components for your Flutter applications.


inspired by https://github.com/pqina/filepond
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

## Upload status

Every picked file has an explicit status:

| `file.status` | Meaning                                   | Default UI            |
|---------------|-------------------------------------------|-----------------------|
| `pending`     | Picked, upload not started yet            | progress bar at 0     |
| `uploading`   | Upload in flight                          | live progress bar     |
| `uploaded`    | Server returned a pond id (`file.filepond`) | nothing (done)      |
| `failed`      | Upload threw or the server rejected it    | error text + retry    |

```dart
final controller = FilepondController(
  baseUrl: 'https://api.example.com/upload',
  uploadDirectly: true,
);

// Gate a submit button: every picked file must be uploaded.
ListenableBuilder(
  listenable: controller, // FilepondController is a ChangeNotifier
  builder: (context, _) => FilledButton(
    onPressed: controller.isSettled ? submit : null,
    child: const Text('Submit'),
  ),
);

// In a custom itemBuilder, show progress / error + retry for one file:
FilepondFileStatusBar(file: file);

controller.hasFailed;          // any failed file?
await controller.retryUpload(file);
await controller.retryAllFailed();
controller.dispose();          // cancels in-flight uploads
```

Any 2xx response is a success. A plain-string body is used as the pond id;
for a JSON object the id is read from `pondLocation` (`'filepond'` by
default, `'/'`-separated for nested paths). Error responses fill
`file.error` with the server's `message` / `error` when present.

## Testing

```sh
flutter test            # unit + widget tests (fake Dio adapter, no network)
../../tool/check.sh     # codegen + analyze + tests for the package and the lab
```

`test/support/fake_upload_server.dart` is an in-memory Dio adapter you can
script per file name (`replyFor`, `hold` / `release`, network errors).

## Example: Upload Lab

[`apps/example`](../../apps/example) is an interactive lab: choose a server
scenario (200, 201, 500, 422, network error, slow, flaky, mixed, random),
add generated sample files or pick real ones, and watch statuses, the
`operationsStream` log, controller getters and the submit gate live.
For a real HTTP server: `node tool/mock_upload_server.mjs --throttle 256`.

## License

MIT