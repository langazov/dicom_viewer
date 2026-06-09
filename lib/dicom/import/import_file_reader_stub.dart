import 'dart:typed_data';

import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';

Future<Uint8List> readImportFileBytes(String path) {
  throw UnsupportedError('Path-based file access is not available here.');
}

Future<List<DicomImportSource>> readImportDirectorySources(String path) {
  throw UnsupportedError('Recursive folder import is not available here.');
}
