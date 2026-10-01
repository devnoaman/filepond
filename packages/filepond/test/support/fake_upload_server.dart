import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:filepond/filepond.dart';

/// What the fake server answers for one request.
class FakeReply {
  const FakeReply(
    this.statusCode,
    this.body, {
    this.contentType = 'text/plain',
    this.error,
  });

  /// 200 with a plain-text pond id.
  factory FakeReply.pondId(String id, {int statusCode = 200}) =>
      FakeReply(statusCode, id);

  /// A JSON body with [statusCode].
  factory FakeReply.json(int statusCode, Object body) => FakeReply(
    statusCode,
    jsonEncode(body),
    contentType: Headers.jsonContentType,
  );

  /// The connection fails before any response (e.g. offline).
  factory FakeReply.networkError([String message = 'Connection reset']) =>
      FakeReply(0, '', error: message);

  final int statusCode;
  final String body;
  final String contentType;
  final String? error;
}

/// A request the fake server received.
class FakeRequest {
  FakeRequest(this.options, this.fieldName, this.fileName);
  final RequestOptions options;
  final String? fieldName;
  final String? fileName;
}

typedef FakeHandler = FutureOr<FakeReply> Function(FakeRequest request);

/// In-memory upload endpoint for tests: a Dio [HttpClientAdapter] whose
/// answers are scripted per request (by default: a pond id per file).
///
/// ```dart
/// final server = FakeUploadServer()
///   ..replyFor('bad.pdf', FakeReply.json(500, {'message': 'Disk full'}));
/// final controller = FilepondController(baseUrl: server.url, dioClient: server.dio);
/// ```
class FakeUploadServer implements HttpClientAdapter {
  FakeUploadServer({FakeHandler? handler}) : _handler = handler {
    dio = Dio()..httpClientAdapter = this;
  }

  static const url = 'https://upload.test/upload';

  /// Dio wired to this server. Pass it as `dioClient`.
  late final Dio dio;

  FakeHandler? _handler;
  final Map<String, List<FakeReply>> _scripted = {};
  final Map<String, Completer<void>> _gates = {};

  /// Every request received, in order.
  final List<FakeRequest> requests = [];

  /// Replaces the default handler for all following requests.
  set handler(FakeHandler handler) => _handler = handler;

  /// Queues [replies] for uploads of [fileName], answered in order. When the
  /// queue is empty the default handler (or a pond id) is used.
  void replyFor(String fileName, FakeReply reply, [List<FakeReply>? more]) {
    _scripted.putIfAbsent(fileName, () => []).addAll([reply, ...?more]);
  }

  /// Holds uploads of [fileName] in flight until [release] is called.
  void hold(String fileName) => _gates[fileName] = Completer<void>();

  /// Lets a held upload of [fileName] continue.
  void release(String fileName) {
    final gate = _gates.remove(fileName);
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  /// Releases every held upload.
  void releaseAll() => _gates.keys.toList().forEach(release);

  int requestsFor(String fileName) =>
      requests.where((r) => r.fileName == fileName).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Consume the body like a real socket would: drives onSendProgress.
    await requestStream?.drain<void>();

    String? fieldName;
    String? fileName;
    final data = options.data;
    if (data is FormData && data.files.isNotEmpty) {
      fieldName = data.files.first.key;
      fileName = data.files.first.value.filename;
    }
    final request = FakeRequest(options, fieldName, fileName);
    requests.add(request);

    final gate = fileName == null ? null : _gates[fileName];
    if (gate != null) await gate.future;

    final queue = fileName == null ? null : _scripted[fileName];
    final reply = (queue != null && queue.isNotEmpty)
        ? queue.removeAt(0)
        : await (_handler ?? _defaultHandler)(request);

    if (reply.error != null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: reply.error!,
      );
    }
    return ResponseBody.fromString(
      reply.body,
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [reply.contentType],
      },
    );
  }

  static FakeReply _defaultHandler(FakeRequest request) =>
      FakeReply.pondId('pond-${request.fileName}');

  @override
  void close({bool force = false}) {}
}

/// A small in-memory file for tests.
FilepondFile fakeFile(
  String name, {
  List<int>? bytes,
  String? id,
  String? filepond,
  FilepondFileStatus status = FilepondFileStatus.pending,
}) => FilepondFile(
  id: id ?? '/tmp/$name',
  file: Uint8List.fromList(bytes ?? utf8.encode('content of $name')),
  fileName: name,
  filepond: filepond,
  status: status,
);

/// Records everything a controller reports, for assertions.
class ControllerRecorder {
  ControllerRecorder(FilepondController controller) {
    _sub = controller.operationsStream.listen(operations.add);
  }

  late final StreamSubscription<FilepondOperation> _sub;
  final List<FilepondOperation> operations = [];

  List<UploadOperationType> get types =>
      operations.map((o) => o.type).toList();

  List<UploadOperationType> typesFor(String fileName) => operations
      .where((o) => o.file?.fileName == fileName)
      .map((o) => o.type)
      .toList();

  Future<void> cancel() => _sub.cancel();
}

/// Lets queued stream events reach their listeners.
Future<void> flush() => Future<void>.delayed(Duration.zero);
