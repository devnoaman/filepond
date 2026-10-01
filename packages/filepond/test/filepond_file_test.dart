// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';
import 'dart:typed_data';

import 'package:filepond/filepond.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  group('FilepondFile', () {
    test('defaults to pending with no error', () {
      final file = FilepondFile(id: '1', file: bytes);
      expect(file.status, FilepondFileStatus.pending);
      expect(file.error, isNull);
      expect(file.uploading, isFalse);
      expect(file.isPending, isTrue);
      expect(file.isUploading, isFalse);
      expect(file.isUploaded, isFalse);
      expect(file.isFailed, isFalse);
    });

    test('convenience getters follow the status', () {
      final file = FilepondFile(id: '1', file: bytes);
      expect(
        file.copyWith(status: FilepondFileStatus.uploading).isUploading,
        isTrue,
      );
      expect(
        file.copyWith(status: FilepondFileStatus.uploaded).isUploaded,
        isTrue,
      );
      expect(file.copyWith(status: FilepondFileStatus.failed).isFailed, isTrue);
    });

    test('copyWith(error: null) clears the error', () {
      final failed = FilepondFile(
        id: '1',
        file: bytes,
        status: FilepondFileStatus.failed,
        error: 'boom',
      );
      expect(failed.copyWith(error: null).error, isNull);
    });

    test('value equality includes status and error', () {
      final a = FilepondFile(id: '1', file: bytes);
      expect(a, FilepondFile(id: '1', file: Uint8List.fromList([1, 2, 3, 4])));
      expect(a == a.copyWith(status: FilepondFileStatus.failed), isFalse);
      expect(a == a.copyWith(error: 'x'), isFalse);
    });
  });

  group('JSON', () {
    test('status is serialised by name and round-trips', () {
      final file = FilepondFile(
        id: '1',
        file: bytes,
        fileName: 'a.jpg',
        status: FilepondFileStatus.failed,
        error: 'Disk full',
      );

      final json = file.toJson();
      expect(json['status'], 'failed');
      expect(json['error'], 'Disk full');
      expect(json['file'], base64Encode(bytes));

      final decoded = FilepondFile.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(decoded, file);
    });

    test('legacy JSON without status and pond id → pending', () {
      final decoded = FilepondFile.fromJson({
        'id': '1',
        'file': base64Encode(bytes),
        'fileName': 'a.jpg',
        'uploading': false,
      });
      expect(decoded.status, FilepondFileStatus.pending);
    });

    test('legacy JSON with a pond id → uploaded', () {
      final decoded = FilepondFile.fromJson({
        'id': '1',
        'file': base64Encode(bytes),
        'filepond': 'pond-1',
      });
      expect(decoded.status, FilepondFileStatus.uploaded);
      expect(decoded.isUploaded, isTrue);
    });

    test('legacy in-flight upload is restored as pending, not uploading', () {
      final decoded = FilepondFile.fromJson({
        'id': '1',
        'file': base64Encode(bytes),
        'uploading': true,
      });
      expect(decoded.status, FilepondFileStatus.pending);
      expect(decoded.uploading, isFalse);
    });

    test('an explicit status wins over the legacy rules', () {
      final decoded = FilepondFile.fromJson({
        'id': '1',
        'file': base64Encode(bytes),
        'filepond': 'pond-1',
        'status': 'failed',
      });
      expect(decoded.status, FilepondFileStatus.failed);
    });
  });

  group('FilepondFileStatus', () {
    test('blocksSubmit is true for everything but uploaded', () {
      expect(
        FilepondFileStatus.values.where((s) => s.blocksSubmit),
        [
          FilepondFileStatus.pending,
          FilepondFileStatus.uploading,
          FilepondFileStatus.failed,
        ],
      );
    });

    test('isUploadable is true for pending and failed', () {
      expect(FilepondFileStatus.values.where((s) => s.isUploadable), [
        FilepondFileStatus.pending,
        FilepondFileStatus.failed,
      ]);
    });
  });
}
