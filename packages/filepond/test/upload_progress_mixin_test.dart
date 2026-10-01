import 'package:filepond/src/upload_file_mixin.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tracker with UploadProgressMixin {}

void main() {
  late _Tracker tracker;

  setUp(() => tracker = _Tracker());
  tearDown(() => tracker.disposeUploadProgress());

  test('reports clamped, rounded progress', () async {
    final values = <double>[];
    tracker.getUploadProgress('a').listen(values.add);

    tracker
      ..updateUploadProgress('a', -1)
      ..updateUploadProgress('a', 0.004)
      ..updateUploadProgress('a', 0.456)
      ..updateUploadProgress('a', 0.995)
      ..updateUploadProgress('a', 7);
    await Future<void>.delayed(Duration.zero);

    expect(values, [0.0, 0.01, 0.46, 1.0, 1.0]);
    expect(tracker.getLatestProgress('a'), 1.0);
  });

  test('the stream stays open after 1.0 so a retry is still delivered',
      () async {
    final values = <double>[];
    var done = false;
    tracker
        .getUploadProgress('a')
        .listen(values.add, onDone: () => done = true);

    tracker.updateUploadProgress('a', 1.0);
    tracker.resetUploadProgress('a');
    tracker.updateUploadProgress('a', 0.5);
    await Future<void>.delayed(Duration.zero);

    expect(done, isFalse);
    expect(values, [1.0, 0.0, 0.5]);
    expect(tracker.getLatestProgress('a'), 0.5);
  });

  test('the same stream is returned for the same id', () {
    expect(
      tracker.getUploadProgress('a'),
      equals(tracker.getUploadProgress('a')),
    );
  });

  test('clearUploadProgress closes the stream and forgets the value',
      () async {
    var done = false;
    tracker.getUploadProgress('a').listen(null, onDone: () => done = true);
    tracker.updateUploadProgress('a', 0.3);

    tracker.clearUploadProgress('a');
    await Future<void>.delayed(Duration.zero);

    expect(done, isTrue);
    expect(tracker.getLatestProgress('a'), 0.0);
  });
}
