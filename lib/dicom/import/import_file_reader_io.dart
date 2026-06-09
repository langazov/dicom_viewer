import 'dart:io';
import 'dart:typed_data';

import 'package:dicom_viewer/dicom/import/dicom_import_source.dart';

Future<Uint8List> readImportFileBytes(String path) {
  return File(path).readAsBytes();
}

Future<List<DicomImportSource>> readImportDirectorySources(String path) async {
  final directory = Directory(path);
  final sources = <DicomImportSource>[];

  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }

    try {
      sources.add(
        DicomImportSource(
          filePath: entity.path,
          bytes: await entity.readAsBytes(),
        ),
      );
    } on FileSystemException {
      continue;
    }
  }

  sources.sort((left, right) => left.filePath.compareTo(right.filePath));
  return sources;
}
