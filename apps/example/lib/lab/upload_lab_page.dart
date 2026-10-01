import 'dart:async';

import 'package:dio/dio.dart';
import 'package:filepond/filepond.dart';
import 'package:flutter/material.dart';

import 'lab_server.dart';
import 'sample_files.dart';

enum _ServerMode { fake, real }

/// Interactive playground for every upload status:
/// pick a server scenario, add files, watch statuses / events, retry, and
/// check that the form only submits when every file is uploaded.
class UploadLabPage extends StatefulWidget {
  const UploadLabPage({super.key});

  @override
  State<UploadLabPage> createState() => _UploadLabPageState();
}

class _UploadLabPageState extends State<UploadLabPage> {
  final _labServer = LabServer(scenario: LabScenario.mixed);
  final _samples = SampleFiles();
  final _events = <_LogEntry>[];
  final _urlController = TextEditingController(
    text: 'http://localhost:3010/upload',
  );

  late final Dio _fakeDio = Dio()..httpClientAdapter = _labServer;
  Dio? _realDio;

  _ServerMode _mode = _ServerMode.fake;
  SourceType _sourceType = SourceType.gallery;
  bool _uploadDirectly = true;
  int? _maxLength = 5;
  bool _customItems = false;

  late FilepondController _controller;
  StreamSubscription<FilepondOperation>? _subscription;
  FilepondFile? _lastAdded;

  Dio get _dio => _mode == _ServerMode.fake ? _fakeDio : _realDio!;

  @override
  void initState() {
    super.initState();
    _labServer.scenario.addListener(_onScenarioChanged);
    _controller = _buildController();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _labServer.scenario.removeListener(_onScenarioChanged);
    _urlController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Controller wiring
  // ---------------------------------------------------------------------------

  FilepondController _buildController() {
    if (_mode == _ServerMode.real) {
      _realDio ??= Dio();
      _realDio!.options.headers['x-scenario'] = _labServer.scenario.value.name;
    }
    final controller = FilepondController(
      baseUrl: _mode == _ServerMode.fake
          ? 'https://lab.filepond.local/upload'
          : _urlController.text.trim(),
      dioClient: _dio,
      uploadName: 'file',
      sourceType: _sourceType,
      uploadDirectly: _uploadDirectly,
      maxLength: _maxLength,
      allowEdit: true,
    );
    _subscription?.cancel();
    _subscription = controller.operationsStream.listen(_log);
    return controller;
  }

  void _rebuildController() {
    final old = _controller;
    setState(() {
      _controller = _buildController();
      _events.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _onScenarioChanged() {
    _realDio?.options.headers['x-scenario'] = _labServer.scenario.value.name;
    setState(() {});
  }

  void _log(FilepondOperation op) {
    if (!mounted) return;
    setState(() {
      _events.insert(0, _LogEntry(DateTime.now(), op));
      if (_events.length > 200) _events.removeLast();
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _addImage() async {
    final file = await _samples.image();
    _lastAdded = file;
    _controller.addFile(file);
  }

  void _addPdf() {
    final file = _samples.pdf();
    _lastAdded = file;
    _controller.addFile(file);
  }

  void _addDuplicate() {
    final last = _lastAdded;
    if (last == null) {
      _snack('Add a file first, then add it again to see a duplicate event.');
      return;
    }
    _controller.addFile(last.copyWith(id: '${last.id}#copy'));
  }

  void _clear() {
    for (final file in List.of(_controller.files)) {
      _controller.removeFile(file);
    }
  }

  void _submit() {
    if (!_controller.isSettled) {
      _snack(
        "Some files haven't uploaded yet. Retry or remove them.",
        error: true,
      );
      return;
    }
    final ids = _controller.files.map((f) => f.filepond).join(', ');
    _snack(ids.isEmpty ? 'Submitted (no files).' : 'Submitted pond ids: $ids');
  }

  void _snack(String message, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? scheme.error : null,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filepond Upload Lab'),
        actions: [
          IconButton(
            tooltip: 'Reset controller',
            onPressed: _rebuildController,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final controls = [
              _ScenarioCard(server: _labServer),
              _settingsCard(context),
              _StateCard(
                controller: _controller,
                requests: _mode == _ServerMode.fake
                    ? _labServer.requestCount
                    : null,
                interceptors: _dio.interceptors.length,
              ),
            ];
            final work = [
              _fieldCard(context),
              _EventLog(
                events: _events,
                onClear: () => setState(_events.clear),
              ),
            ];
            if (!wide) {
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [...controls, ...work],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 380,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: controls,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: work,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context) {
    return _Section(
      title: 'Setup',
      children: [
        SegmentedButton<_ServerMode>(
          segments: const [
            ButtonSegment(
              value: _ServerMode.fake,
              label: Text('In-app server'),
              icon: Icon(Icons.memory),
            ),
            ButtonSegment(
              value: _ServerMode.real,
              label: Text('HTTP server'),
              icon: Icon(Icons.dns_outlined),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) {
            _mode = s.first;
            _rebuildController();
          },
        ),
        if (_mode == _ServerMode.real) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Upload URL',
              helperText:
                  'Run: node tool/mock_upload_server.mjs  (Android emulator: http://10.0.2.2:3010/upload)',
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Apply',
                icon: const Icon(Icons.check),
                onPressed: _rebuildController,
              ),
            ),
            onSubmitted: (_) => _rebuildController(),
          ),
        ],
        const SizedBox(height: 12),
        Text('Picker source', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SegmentedButton<SourceType>(
          segments: const [
            ButtonSegment(value: SourceType.gallery, label: Text('Gallery')),
            ButtonSegment(value: SourceType.camera, label: Text('Camera')),
            ButtonSegment(value: SourceType.files, label: Text('Files')),
          ],
          selected: {_sourceType},
          onSelectionChanged: (s) => setState(() {
            _sourceType = s.first;
            _controller.sourceType = _sourceType;
          }),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Upload directly'),
          subtitle: const Text('Start uploading as soon as a file is added'),
          value: _uploadDirectly,
          onChanged: (v) => setState(() {
            _uploadDirectly = v;
            _controller.uploadDirectly = v;
          }),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Custom item builder'),
          subtitle: const Text('Off: package default tiles'),
          value: _customItems,
          onChanged: (v) => setState(() => _customItems = v),
        ),
        Row(
          children: [
            const Expanded(child: Text('Max files')),
            DropdownButton<int?>(
              value: _maxLength,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: 5, child: Text('5')),
                DropdownMenuItem(value: null, child: Text('No limit')),
              ],
              onChanged: (v) => setState(() {
                _maxLength = v;
                _controller.maxLength = v;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldCard(BuildContext context) {
    final c = _controller;
    return _Section(
      title: 'Form field',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _addImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Add sample image'),
            ),
            FilledButton.tonalIcon(
              onPressed: _addPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Add sample PDF'),
            ),
            OutlinedButton.icon(
              onPressed: _addDuplicate,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Add duplicate'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Filepond(
          controller: c,
          title: 'Or pick a real file',
          itemBuilder: _customItems ? _customItem : null,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: c.files.any((f) => f.status.isUploadable)
                  ? c.uploadAll
                  : null,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload all'),
            ),
            OutlinedButton.icon(
              onPressed: c.hasFailed ? c.retryAllFailed : null,
              icon: const Icon(Icons.refresh),
              label: Text('Retry failed (${c.failedFiles.length})'),
            ),
            OutlinedButton.icon(
              onPressed: c.files.isEmpty ? null : _clear,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Remove all'),
            ),
          ],
        ),
        const Divider(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: c.isSettled
                ? null
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: c.isSettled
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: _submit,
          icon: Icon(c.isSettled ? Icons.send : Icons.block),
          label: Text(
            c.isSettled ? 'Submit form' : 'Submit blocked — files not uploaded',
          ),
        ),
      ],
    );
  }

  Widget _customItem(
    BuildContext context,
    FilepondFile file,
    int index,
    Animation<double> animation,
    VoidCallback onRemove,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final (color, label) = switch (file.status) {
      FilepondFileStatus.pending => (scheme.outline, 'Waiting'),
      FilepondFileStatus.uploading => (scheme.primary, 'Uploading'),
      FilepondFileStatus.uploaded => (Colors.green, 'Uploaded'),
      FilepondFileStatus.failed => (scheme.error, 'Failed'),
    };
    final isImage =
        (file.fileName ?? '').toLowerCase().endsWith('.png') ||
        (file.fileName ?? '').toLowerCase().endsWith('.jpg') ||
        (file.fileName ?? '').toLowerCase().endsWith('.jpeg');

    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.only(top: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: 48,
                      child: isImage
                          ? Image.memory(file.file, fit: BoxFit.cover)
                          : ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: const Icon(Icons.insert_drive_file),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName ?? file.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Dot(color: color),
                            const SizedBox(width: 6),
                            Text(label, style: TextStyle(color: color)),
                            if (file.filepond != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  file.filepond!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (file.isPending)
                    IconButton(
                      tooltip: 'Upload',
                      onPressed: () => _controller.uploadFile(file),
                      icon: const Icon(Icons.cloud_upload_outlined),
                    ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              if (!file.isUploaded) ...[
                const SizedBox(height: 8),
                FilepondFileStatusBar(file: file, controller: _controller),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.server});
  final LabServer server;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LabScenario>(
      valueListenable: server.scenario,
      builder: (context, scenario, _) => _Section(
        title: 'Server scenario',
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in LabScenario.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: s == scenario,
                  onSelected: (_) => server.scenario.value = s,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scenario.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.controller,
    required this.requests,
    required this.interceptors,
  });
  final FilepondController controller;
  final int? requests;
  final int interceptors;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    int count(FilepondFileStatus s) =>
        c.files.where((f) => f.status == s).length;

    return _Section(
      title: 'Controller state',
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Flag('isSettled', c.isSettled, good: true),
            _Flag('isUploading', c.isUploading),
            _Flag('hasFailed', c.hasFailed, good: false),
            _Flag('allUploaded', c.allUploaded),
          ],
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {1: IntrinsicColumnWidth()},
          children: [
            for (final s in FilepondFileStatus.values)
              _row(context, s.name, '${count(s)}'),
            _row(context, 'files', '${c.files.length} / ${c.maxLength ?? '∞'}'),
            if (requests != null) _row(context, 'requests', '$requests'),
            _row(context, 'dio interceptors', '$interceptors (must not grow)'),
          ],
        ),
      ],
    );
  }

  TableRow _row(BuildContext context, String k, String v) => TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(k, style: Theme.of(context).textTheme.bodySmall),
      ),
      Text(
        v,
        style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      ),
    ],
  );
}

class _Flag extends StatelessWidget {
  const _Flag(this.name, this.value, {this.good});
  final String name;
  final bool value;

  /// When set, highlights `value == good` green and the opposite red.
  final bool? good;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = good == null
        ? (value ? scheme.primary : scheme.outline)
        : (value == good
              ? Colors.green
              : (value ? scheme.error : scheme.outline));
    return Chip(
      avatar: Icon(
        value ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
        color: color,
      ),
      label: Text('$name: $value'),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _LogEntry {
  _LogEntry(this.time, this.operation);
  final DateTime time;
  final FilepondOperation operation;
}

class _EventLog extends StatelessWidget {
  const _EventLog({required this.events, required this.onClear});
  final List<_LogEntry> events;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color colorFor(UploadOperationType t) => switch (t) {
      UploadOperationType.insert => scheme.primary,
      UploadOperationType.uploading => Colors.orange,
      UploadOperationType.uploaded => Colors.green,
      UploadOperationType.failed => scheme.error,
      UploadOperationType.remove => scheme.outline,
      UploadOperationType.update => Colors.blueGrey,
      UploadOperationType.dublicate => Colors.purple,
    };

    return _Section(
      title: 'operationsStream (${events.length})',
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: events.isEmpty ? null : onClear,
            child: const Text('Clear log'),
          ),
        ),
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No events yet — add a file.'),
          ),
        for (final e in events.take(60))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.time.hour.toString().padLeft(2, '0')}:'
                  '${e.time.minute.toString().padLeft(2, '0')}:'
                  '${e.time.second.toString().padLeft(2, '0')}.'
                  '${(e.time.millisecond ~/ 10).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: colorFor(e.operation.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    e.operation.type.name,
                    style: TextStyle(
                      color: colorFor(e.operation.type),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      e.operation.file?.fileName ?? '—',
                      if (e.operation.index != null) '#${e.operation.index}',
                      if (e.operation.message != null) e.operation.message!,
                    ].join('  ·  '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
