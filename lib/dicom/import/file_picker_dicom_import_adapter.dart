import 'package:dicom_viewer/dicom/import/dicom_import_adapter.dart';
import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';
import 'package:dicom_viewer/dicom/import/import_file_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class FilePickerDicomImportAdapter implements DicomImportAdapter {
  const FilePickerDicomImportAdapter();

  @override
  Future<DicomImportAdapterResult?> pickFiles() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.any,
      );
    } on PlatformException catch (error) {
      return DicomImportAdapterResult(
        sources: const [],
        accessIssues: [_platformExceptionMessage(error)],
      );
    }
    if (result == null) {
      return null;
    }

    final sources = <DicomImportSource>[];
    final issues = <String>[];

    for (final file in result.files) {
      final bytes = await _bytesForPickedFile(file, issues);
      if (bytes == null) {
        continue;
      }

      sources.add(
        DicomImportSource(filePath: file.path ?? file.name, bytes: bytes),
      );
    }

    return DicomImportAdapterResult(sources: sources, accessIssues: issues);
  }

  @override
  Future<DicomImportAdapterResult?> pickDirectory() async {
    final String? directoryPath;
    try {
      directoryPath = await FilePicker.getDirectoryPath();
    } on PlatformException catch (error) {
      return DicomImportAdapterResult(
        sources: const [],
        accessIssues: [_platformExceptionMessage(error)],
      );
    }
    if (directoryPath == null) {
      return null;
    }

    try {
      final sources = await readImportDirectorySources(directoryPath);
      return DicomImportAdapterResult(sources: sources);
    } on UnsupportedError catch (error) {
      return DicomImportAdapterResult(
        sources: const [],
        accessIssues: [
          error.message ?? 'Recursive folder import is unavailable.',
        ],
      );
    }
  }

  String _platformExceptionMessage(PlatformException error) {
    if (error.code == 'ENTITLEMENT_NOT_FOUND') {
      return 'Folder/file access requires the macOS user-selected file entitlement. Rebuild the app and try again.';
    }

    return error.message ?? 'The platform file picker failed: ${error.code}.';
  }

  Future<Uint8List?> _bytesForPickedFile(
    PlatformFile file,
    List<String> issues,
  ) async {
    final inMemoryBytes = file.bytes;
    if (inMemoryBytes != null) {
      return inMemoryBytes;
    }

    final path = file.path;
    if (path == null) {
      issues.add(
        'Could not read ${file.name}: no file bytes or path provided.',
      );
      return null;
    }

    try {
      return await readImportFileBytes(path);
    } on UnsupportedError {
      issues.add('Could not read ${file.name}: path access is unavailable.');
      return null;
    }
  }
}
