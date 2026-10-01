import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:filepond/filepond.dart';
import 'package:flutter/material.dart';

/// Generates files in memory so the lab works on simulators and desktops
/// without a camera or photo library.
class SampleFiles {
  int _counter = 0;

  static const _palettes = [
    (Color(0xFF4F46E5), Color(0xFF06B6D4)),
    (Color(0xFFDB2777), Color(0xFFF59E0B)),
    (Color(0xFF059669), Color(0xFF84CC16)),
    (Color(0xFF7C3AED), Color(0xFFEC4899)),
  ];

  /// A 480×320 gradient PNG labelled with a running number.
  Future<FilepondFile> image() async {
    final n = ++_counter;
    final (a, b) = _palettes[n % _palettes.length];
    const size = Size(480, 320);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [a, b],
        ),
    );
    final label = TextPainter(
      text: TextSpan(
        text: 'Sample #$n',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 44,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset((size.width - label.width) / 2, (size.height - label.height) / 2),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();

    final name = 'sample_$n.png';
    return FilepondFile(
      id: 'lab://$name',
      file: png!.buffer.asUint8List(),
      fileName: name,
    );
  }

  /// A small one-page PDF.
  FilepondFile pdf() {
    final n = ++_counter;
    final name = 'document_$n.pdf';
    final body =
        '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
        '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
        '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n'
        'trailer<</Root 1 0 R>>\n%% Filepond lab document $n\n%%EOF\n';
    return FilepondFile(
      id: 'lab://$name',
      file: Uint8List.fromList(utf8.encode(body)),
      fileName: name,
    );
  }
}
