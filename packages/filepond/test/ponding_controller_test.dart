// ignore_for_file: deprecated_member_use_from_same_package


import 'package:dio/dio.dart';
import 'package:filepond/filepond.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_upload_server.dart';

void main() {
  late FakeUploadServer server;
  late FilepondController controller;
  late ControllerRecorder recorder;
  late List<List<FilepondFileStatus>> changes;

  FilepondController buildController({
    bool uploadDirectly = false,
    int? maxLength,
    String pondLocation = 'filepond',
    List<FilepondFile>? initialFiles,
    Dio? dio,
  }) {
    final c = FilepondController(
      baseUrl: FakeUploadServer.url,
      dioClient: dio ?? server.dio,
      uploadDirectly: uploadDirectly,
      maxLength: maxLength,
      pondLocation: pondLocation,
      initialFiles: initialFiles,
      uploadName: 'photo',
      onFilesChange: (files) =>
          changes.add(files.map((f) => f.status).toList()),
    );
    return c;
  }

  setUp(() {
    server = FakeUploadServer();
    changes = [];
    controller = buildController();
    recorder = ControllerRecorder(controller);
  });

  tearDown(() async {
    server.releaseAll();
    await recorder.cancel();
    if (!controller.isDisposed) controller.dispose();
  });

  group('status lifecycle', () {
    test('success: pending → uploading → uploaded', () async {
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      expect(controller.files.single.status, FilepondFileStatus.pending);

      await controller.uploadFile(file);
      await flush();

      final uploaded = controller.files.single;
      expect(uploaded.status, FilepondFileStatus.uploaded);
      expect(uploaded.filepond, 'pond-a.pdf');
      expect(uploaded.error, isNull);
      expect(uploaded.isUploading, isFalse);
      expect(recorder.types, [
        UploadOperationType.insert,
        UploadOperationType.uploading,
        UploadOperationType.uploaded,
      ]);
      expect(changes, [
        [FilepondFileStatus.pending],
        [FilepondFileStatus.uploading],
        [FilepondFileStatus.uploaded],
      ]);
      expect(controller.isSettled, isTrue);
      expect(controller.getLatestProgress(file.id), 1.0);
    });

    test('sends the file under uploadName with its file name', () async {
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      await controller.uploadFile(file);

      final request = server.requests.single;
      expect(request.fieldName, 'photo');
      expect(request.fileName, 'a.pdf');
      expect(request.options.uri.toString(), FakeUploadServer.url);
    });

    test('the deprecated uploading flag mirrors the status', () async {
      server.hold('a.pdf');
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      final upload = controller.uploadFile(file);
      await flush();

      expect(controller.files.single.uploading, isTrue);
      expect(controller.files.single.isUploading, isTrue);

      server.release('a.pdf');
      await upload;
      expect(controller.files.single.uploading, isFalse);
    });

    test('500 with a JSON message → failed with the server message', () async {
      server.replyFor('a.pdf', FakeReply.json(500, {'message': 'Disk full'}));
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.uploadFile(file);
      await flush();

      final failed = controller.files.single;
      expect(failed.status, FilepondFileStatus.failed);
      expect(failed.error, 'Disk full');
      expect(failed.filepond, isNull);
      expect(changes.last, [FilepondFileStatus.failed]);
      expect(controller.isSettled, isFalse);
      expect(controller.hasFailed, isTrue);
      expect(controller.failedFiles.single.id, file.id);
      expect(recorder.operations.last.type, UploadOperationType.failed);
      expect(recorder.operations.last.message, 'Disk full');
    });

    test('500 without a body → failed with the HTTP status', () async {
      server.replyFor('a.pdf', const FakeReply(500, ''));
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.uploadFile(file);

      expect(controller.files.single.error, 'Upload failed (HTTP 500)');
    });

    test('network error → failed', () async {
      server.replyFor('a.pdf', FakeReply.networkError('offline'));
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.uploadFile(file);

      expect(controller.files.single.isFailed, isTrue);
      expect(controller.files.single.error, isNotEmpty);
    });

    test('201 is treated as success', () async {
      server.replyFor('a.pdf', FakeReply.pondId('created-id', statusCode: 201));
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.uploadFile(file);

      expect(controller.files.single.status, FilepondFileStatus.uploaded);
      expect(controller.files.single.filepond, 'created-id');
    });

    test('non-2xx accepted by a custom validateStatus still fails', () async {
      server.dio.options.validateStatus = (_) => true;
      server.replyFor('a.pdf', FakeReply.json(422, {'error': 'Too big'}));
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.uploadFile(file);

      expect(controller.files.single.isFailed, isTrue);
      expect(controller.files.single.error, 'Too big');
    });

    test('JSON object response: pond id read from pondLocation', () async {
      controller.dispose();
      controller = buildController(pondLocation: 'data/id');
      server.replyFor(
        'a.pdf',
        FakeReply.json(200, {
          'data': {'id': 'nested-42'},
        }),
      );
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.uploadFile(file);

      expect(controller.files.single.filepond, 'nested-42');
    });

    test('JSON object response without the pond id → failed', () async {
      server.replyFor('a.pdf', FakeReply.json(200, {'other': 1}));
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.uploadFile(file);

      expect(controller.files.single.isFailed, isTrue);
    });

    test('uploading a file twice concurrently sends one request', () async {
      server.hold('a.pdf');
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      final first = controller.uploadFile(file);
      await flush();
      await controller.uploadFile(controller.files.single);
      server.release('a.pdf');
      await first;

      expect(server.requestsFor('a.pdf'), 1);
    });

    test('uploading an unknown file emits failed with index -1', () async {
      await controller.uploadFile(fakeFile('ghost.pdf'));
      await flush();

      expect(recorder.operations.single.type, UploadOperationType.failed);
      expect(recorder.operations.single.index, -1);
      expect(server.requests, isEmpty);
    });
  });

  group('retry', () {
    test('retryUpload after a failure ends in uploaded', () async {
      server.replyFor('a.pdf', FakeReply.json(500, {'message': 'boom'}));
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      await controller.uploadFile(file);
      expect(controller.hasFailed, isTrue);

      await controller.retryUpload(controller.files.single);

      final retried = controller.files.single;
      expect(retried.status, FilepondFileStatus.uploaded);
      expect(retried.error, isNull);
      expect(controller.isSettled, isTrue);
      expect(server.requestsFor('a.pdf'), 2);
    });

    test('a retry restarts progress from 0', () async {
      server.replyFor('a.pdf', const FakeReply(500, 'nope'));
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      await controller.uploadFile(file);
      expect(controller.getLatestProgress(file.id), 1.0); // body was sent

      final values = <double>[];
      final sub = controller.getUploadProgress(file.id).listen(values.add);
      server.hold('a.pdf');
      final retry = controller.retryUpload(controller.files.single);
      await flush();

      expect(values.first, 0.0);
      server.release('a.pdf');
      await retry;
      await flush();
      expect(values.last, 1.0);
      await sub.cancel();
    });

    test('retryUpload ignores files that did not fail', () async {
      final file = fakeFile('a.pdf');
      controller.addFile(file);

      await controller.retryUpload(file);

      expect(server.requests, isEmpty);
      expect(controller.files.single.isPending, isTrue);
    });

    test('retryAllFailed retries every failed file', () async {
      server
        ..replyFor('a.pdf', const FakeReply(500, 'x'))
        ..replyFor('b.pdf', const FakeReply(503, 'y'));
      controller
        ..addFile(fakeFile('a.pdf'))
        ..addFile(fakeFile('b.pdf'))
        ..addFile(fakeFile('c.pdf'));
      await controller.uploadAll();
      expect(controller.failedFiles.length, 2);

      await controller.retryAllFailed();

      expect(controller.isSettled, isTrue);
      expect(server.requestsFor('c.pdf'), 1);
    });
  });

  group('uploadAll', () {
    test('uploads pending and failed files only', () async {
      server.replyFor('failed.pdf', const FakeReply(500, 'x'));
      controller
        ..addFile(fakeFile('done.pdf'))
        ..addFile(fakeFile('failed.pdf'));
      await controller.uploadAll();
      expect(controller.files.map((f) => f.status), [
        FilepondFileStatus.uploaded,
        FilepondFileStatus.failed,
      ]);

      server.hold('busy.pdf');
      controller.addFile(fakeFile('busy.pdf'));
      final busy = controller.uploadFile(controller.files.last);
      await flush();
      controller.addFile(fakeFile('new.pdf'));

      await controller.uploadAll();

      expect(server.requestsFor('done.pdf'), 1); // uploaded: skipped
      expect(server.requestsFor('failed.pdf'), 2); // failed: re-sent
      expect(server.requestsFor('new.pdf'), 1); // pending: sent
      server.release('busy.pdf');
      await busy;
      expect(server.requestsFor('busy.pdf'), 1); // uploading: not re-sent
      expect(controller.isSettled, isTrue);
    });

    test('does nothing for an empty list', () async {
      await controller.uploadAll();
      expect(server.requests, isEmpty);
    });
  });

  group('remove and cancel', () {
    test('remove during upload: no RangeError, no events, others intact',
        () async {
      server
        ..hold('a.pdf')
        ..hold('b.pdf');
      controller
        ..addFile(fakeFile('a.pdf'))
        ..addFile(fakeFile('b.pdf'));
      final uploads = controller.uploadAll();
      await flush();
      expect(controller.isUploading, isTrue);

      controller.removeFile(controller.files.first);
      server.releaseAll();
      await uploads;
      await flush();

      expect(controller.files.length, 1);
      final b = controller.files.single;
      expect(b.fileName, 'b.pdf');
      expect(b.status, FilepondFileStatus.uploaded);
      expect(b.filepond, 'pond-b.pdf');
      expect(recorder.typesFor('a.pdf'), [
        UploadOperationType.insert,
        UploadOperationType.uploading,
        UploadOperationType.remove,
      ]);
    });

    test('removeFile calls onFilesChange and emits remove', () async {
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      changes.clear();

      controller.removeFile(file);
      await flush();

      expect(changes, [<FilepondFileStatus>[]]);
      expect(recorder.operations.last.type, UploadOperationType.remove);
      expect(recorder.operations.last.index, 0);
    });

    test('removing an unknown file emits failed', () async {
      controller.removeFile(fakeFile('ghost.pdf'));
      await flush();
      expect(recorder.operations.single.type, UploadOperationType.failed);
    });

    test('dispose cancels in-flight uploads without emitting failed',
        () async {
      server.hold('a.pdf');
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      final upload = controller.uploadFile(file);
      await flush();
      final before = recorder.operations.length;
      final changesBefore = changes.length;

      controller.dispose();
      await upload;

      expect(controller.isDisposed, isTrue);
      expect(recorder.operations.length, before);
      expect(changes.length, changesBefore);
      // Calls after dispose are no-ops.
      await controller.uploadFile(file);
      expect(controller.addFile(fakeFile('b.pdf')), isFalse);
    });

    test('updateFile replaces by id and resets the status', () async {
      final file = fakeFile('a.pdf');
      controller.addFile(file);
      await controller.uploadFile(file);

      final edited = fakeFile('a_edited.pdf');
      controller.updateFile(controller.files.single, edited);

      expect(controller.files.single.id, edited.id);
      expect(controller.files.single.isPending, isTrue);
      expect(controller.isSettled, isFalse);
    });
  });

  group('adding files', () {
    test('maxLength is respected', () {
      controller.dispose();
      controller = buildController(maxLength: 1);
      expect(controller.addFile(fakeFile('a.pdf')), isTrue);
      expect(controller.addFile(fakeFile('b.pdf')), isFalse);
      expect(controller.files.length, 1);
    });

    test('duplicates (same name or same bytes) are rejected', () async {
      controller.addFile(fakeFile('a.pdf', bytes: [1, 2, 3]));

      expect(controller.addFile(fakeFile('a.pdf', id: 'other')), isFalse);
      expect(
        controller.addFile(fakeFile('copy.pdf', bytes: [1, 2, 3])),
        isFalse,
      );
      await flush();

      final dupes = recorder.operations
          .where((o) => o.type == UploadOperationType.dublicate)
          .toList();
      expect(dupes.length, 2);
      expect(dupes.every((o) => o.index == 0), isTrue);
      expect(controller.files.length, 1);
    });

    test('checkDuplicates: false accepts look-alikes', () {
      controller.addFile(fakeFile('a.pdf'));
      expect(
        controller.addFile(fakeFile('a.pdf', id: 'b'), checkDuplicates: false),
        isTrue,
      );
    });

    test('uploadDirectly uploads the added file', () async {
      controller.dispose();
      controller = buildController(uploadDirectly: true);
      controller.addFile(fakeFile('a.pdf'));

      await pumpEventQueueUntil(() => controller.isSettled);

      expect(controller.files.single.filepond, 'pond-a.pdf');
    });

    test('initial files with a pond id count as uploaded', () {
      controller.dispose();
      controller = buildController(
        initialFiles: [
          fakeFile('old.pdf', filepond: 'pond-old'),
          fakeFile('stale.pdf', status: FilepondFileStatus.uploading),
        ],
      );

      expect(controller.files.first.status, FilepondFileStatus.uploaded);
      expect(controller.files.last.status, FilepondFileStatus.pending);
      expect(controller.files.last.uploading, isFalse);
    });
  });

  group('controller getters', () {
    test('empty list: settled, nothing uploading, not allUploaded', () {
      expect(controller.isSettled, isTrue);
      expect(controller.isUploading, isFalse);
      expect(controller.hasFailed, isFalse);
      expect(controller.allUploaded, isFalse);
    });

    test('pending counts as uploading (not settled)', () {
      controller.addFile(fakeFile('a.pdf'));
      expect(controller.isUploading, isTrue);
      expect(controller.isSettled, isFalse);
    });

    test('ChangeNotifier and filesListenable fire on status changes',
        () async {
      var notified = 0;
      final snapshots = <List<FilepondFileStatus>>[];
      controller.addListener(() => notified++);
      controller.filesListenable.addListener(
        () => snapshots.add(
          controller.filesListenable.value.map((f) => f.status).toList(),
        ),
      );

      final file = fakeFile('a.pdf');
      controller.addFile(file);
      await controller.uploadFile(file);

      expect(notified, 3);
      expect(snapshots, [
        [FilepondFileStatus.pending],
        [FilepondFileStatus.uploading],
        [FilepondFileStatus.uploaded],
      ]);
      expect(
        () => controller.filesListenable.value.add(fakeFile('x.pdf')),
        throwsUnsupportedError,
      );
    });
  });

  group('regressions', () {
    test('injected Dio interceptors do not grow across uploads', () async {
      final before = server.dio.interceptors.length;
      for (var i = 0; i < 5; i++) {
        final file = fakeFile('f$i.pdf');
        controller.addFile(file);
        await controller.uploadFile(file);
      }
      expect(server.dio.interceptors.length, before);
      expect(controller.isSettled, isTrue);
    });

    test('FilepondOperation.uploading has type uploading', () {
      final op = FilepondOperation.uploading(fakeFile('a.pdf'), 0);
      expect(op.type, UploadOperationType.uploading);
    });
  });
}

/// Pumps the event queue until [condition] holds (max ~1s).
Future<void> pumpEventQueueUntil(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
