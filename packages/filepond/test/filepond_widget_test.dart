import 'package:filepond/filepond.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_upload_server.dart';

/// A minimal "form": the Filepond field plus a Submit button that is only
/// enabled when every picked file is uploaded (`controller.isSettled`).
class _UploadForm extends StatelessWidget {
  const _UploadForm({required this.controller, this.dark = false});
  final FilepondController controller;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Filepond(
                controller: controller,
                builder: (context, controller, isAttaching) =>
                    const SizedBox(height: 40, child: Text('Pick a file')),
              ),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) => FilledButton(
                  key: const ValueKey('submit'),
                  onPressed: controller.isSettled ? () {} : null,
                  child: Text(
                    controller.isSettled ? 'Submit' : 'Files not uploaded',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _submitEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('submit'))).enabled;

void main() {
  late FakeUploadServer server;
  late FilepondController controller;

  setUp(() {
    server = FakeUploadServer();
    controller = FilepondController(
      baseUrl: FakeUploadServer.url,
      dioClient: server.dio,
    );
  });

  tearDown(() {
    server.releaseAll();
    controller.dispose();
  });

  testWidgets('one upload succeeds, one fails: retry unblocks submit', (
    tester,
  ) async {
    await tester.pumpWidget(_UploadForm(controller: controller));
    expect(_submitEnabled(tester), isTrue); // nothing picked yet

    server.replyFor('bad.pdf', FakeReply.json(500, {'message': 'Disk full'}));
    controller
      ..addFile(fakeFile('good.pdf'))
      ..addFile(fakeFile('bad.pdf'));
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2)); // pending
    expect(_submitEnabled(tester), isFalse);

    controller.uploadAll();
    await settle(tester);

    // good.pdf: done, no bar. bad.pdf: error + retry.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Upload failed'), findsOneWidget);
    expect(find.text('Disk full'), findsOneWidget);
    expect(find.text('Files not uploaded'), findsOneWidget);
    expect(_submitEnabled(tester), isFalse);

    // Retry succeeds.
    await tester.tap(find.byKey(const ValueKey('filepond-retry')));
    await settle(tester);
    expect(controller.isSettled, isTrue);

    expect(find.text('Upload failed'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(_submitEnabled(tester), isTrue);
  });

  testWidgets('removing the failed file unblocks submit', (tester) async {
    await tester.pumpWidget(_UploadForm(controller: controller));
    server.replyFor('bad.pdf', const FakeReply(500, 'nope'));
    controller.addFile(fakeFile('bad.pdf'));
    controller.uploadAll();
    await settle(tester);
    expect(_submitEnabled(tester), isFalse);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('bad.pdf'), findsNothing);
    expect(controller.files, isEmpty);
    expect(_submitEnabled(tester), isTrue);
  });

  testWidgets('shows a live progress bar while uploading', (tester) async {
    await tester.pumpWidget(_UploadForm(controller: controller));
    server.hold('a.pdf');
    controller.addFile(fakeFile('a.pdf'));
    await tester.pumpAndSettle();

    controller.uploadFile(controller.files.single);
    await settle(tester);

    expect(server.requestsFor('a.pdf'), 1);
    expect(controller.files.single.isUploading, isTrue);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1.0); // body fully sent, waiting for the server

    server.release('a.pdf');
    await settle(tester);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('rebuilds do not duplicate operation handling', (tester) async {
    var dark = false;
    late StateSetter setOuter;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setOuter = setState;
          return _UploadForm(controller: controller, dark: dark);
        },
      ),
    );
    // Each theme flip re-runs didChangeDependencies on the Filepond widget.
    for (var i = 0; i < 3; i++) {
      setOuter(() => dark = !dark);
      await tester.pumpAndSettle();
    }

    controller
      ..addFile(fakeFile('first.pdf'))
      ..addFile(fakeFile('second.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('first.pdf'), findsOneWidget);
    expect(find.text('second.pdf'), findsOneWidget);

    controller.removeFile(controller.files.first);
    await tester.pumpAndSettle();

    expect(find.text('first.pdf'), findsNothing);
    expect(find.text('second.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swapping the controller shows the new controller files', (
    tester,
  ) async {
    controller.addFile(fakeFile('old.pdf'));
    await tester.pumpWidget(_UploadForm(controller: controller));
    expect(find.text('old.pdf'), findsOneWidget);

    final other = FilepondController(
      baseUrl: FakeUploadServer.url,
      dioClient: server.dio,
      initialFiles: [fakeFile('new.pdf', filepond: 'pond-new')],
    );
    addTearDown(other.dispose);
    await tester.pumpWidget(_UploadForm(controller: other));
    await tester.pumpAndSettle();

    expect(find.text('old.pdf'), findsNothing);
    expect(find.text('new.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  group('FilepondFileStatusBar', () {
    Future<void> pumpBar(WidgetTester tester, FilepondFile file) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FilepondFileStatusBar(file: file, controller: controller),
            ),
          ),
        );

    testWidgets('pending: bar at 0', (tester) async {
      await pumpBar(tester, fakeFile('a.pdf'));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0);
    });

    testWidgets('uploaded: nothing', (tester) async {
      await pumpBar(
        tester,
        fakeFile('a.pdf', status: FilepondFileStatus.uploaded, filepond: 'p'),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('failed: error text and retry', (tester) async {
      await pumpBar(
        tester,
        fakeFile(
          'a.pdf',
          status: FilepondFileStatus.failed,
        ).copyWith(error: 'Timeout'),
      );
      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.text('Timeout'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

/// Drives the fake upload server to completion. Every await in the upload
/// path is a microtask or a short timer, so fake time is enough.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}
