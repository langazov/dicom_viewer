import 'dart:typed_data';

class DicomImportSource {
  const DicomImportSource({required this.filePath, required this.bytes});

  final String filePath;
  final Uint8List bytes;
}
