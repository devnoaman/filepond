import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// How the upload server answers. Used by the in-app fake server and sent
/// to the Node mock server (`tool/mock_upload_server.mjs`) as `x-scenario`.
enum LabScenario {
  success('200 OK', 'Plain-text pond id'),
  created('201 Created', 'JSON {"filepond": id} — exercises pondLocation'),
  serverError('500 error', 'JSON {"message": "Disk full"}'),
  validation('422 rejected', 'JSON {"error": "File too large"}'),
  network('Network error', 'Connection drops, no response'),
  slow('Slow (3 s)', 'Succeeds after a 3 s wait'),
  flaky('Flaky', 'First attempt per file fails, retry succeeds'),
  mixed('Mixed', 'Alternates success / 500 per request'),
  random('Random', '70 % success, 30 % failure');

  const LabScenario(this.label, this.description);
  final String label;
  final String description;
}

/// In-memory upload endpoint: a Dio adapter that answers according to
/// [scenario], so every status can be reproduced without a backend.
class LabServer implements HttpClientAdapter {
  LabServer({LabScenario scenario = LabScenario.success})
    : scenario = ValueNotifier(scenario);

  final ValueNotifier<LabScenario> scenario;
  final Map<String, int> _attempts = {};
  final _random = Random();
  int _requests = 0;

  /// Number of requests received so far.
  int get requestCount => _requests;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Read the body like a socket would; this drives onSendProgress.
    var bytes = 0;
    await for (final chunk
        in requestStream ?? const Stream<Uint8List>.empty()) {
      bytes += chunk.length;
      await Future<void>.delayed(const Duration(milliseconds: 4));
    }
    final data = options.data;
    final fileName = data is FormData && data.files.isNotEmpty
        ? data.files.first.value.filename ?? 'file'
        : 'file';
    final attempt = _attempts.update(fileName, (n) => n + 1, ifAbsent: () => 1);
    final n = ++_requests;

    // Simulated latency so the "uploading" state is visible.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final id = 'pond_${n}_${bytes}b';
    switch (scenario.value) {
      case LabScenario.success:
        return _text(200, id);
      case LabScenario.created:
        return _json(201, {'filepond': id});
      case LabScenario.serverError:
        return _json(500, {'message': 'Disk full'});
      case LabScenario.validation:
        return _json(422, {'error': 'File too large'});
      case LabScenario.network:
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'Connection reset by peer',
        );
      case LabScenario.slow:
        await Future<void>.delayed(const Duration(seconds: 3));
        return _text(200, id);
      case LabScenario.flaky:
        return attempt == 1
            ? _json(503, {'message': 'Service unavailable, try again'})
            : _text(200, id);
      case LabScenario.mixed:
        return n.isOdd ? _text(200, id) : _json(500, {'message': 'Disk full'});
      case LabScenario.random:
        return _random.nextDouble() < 0.7
            ? _text(200, id)
            : _json(500, {'message': 'Random failure'});
    }
  }

  ResponseBody _text(int status, String body) => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['text/plain'],
    },
  );

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
