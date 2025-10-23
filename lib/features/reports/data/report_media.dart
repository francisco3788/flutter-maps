import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ReportMedia {
  ReportMedia({
    required this.bytes,
    required this.fileName,
  }) : contentType = _detectMimeType(fileName);

  final Uint8List bytes;
  final String fileName;
  final String contentType;

  static Future<ReportMedia> fromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    return ReportMedia(
      bytes: bytes,
      fileName: file.name,
    );
  }

  static String _detectMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
