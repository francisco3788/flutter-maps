import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/reports/data/report_media.dart';

Future<ReportMedia?> pickReportMedia() async {
  try {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (file != null) {
      return ReportMedia.fromXFile(file);
    }
  } catch (_) {
    // Camera may be unavailable; fallback to gallery or file picker.
  }

  try {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (file != null) {
      return ReportMedia.fromXFile(file);
    }
  } catch (_) {
    // Ignore and fallback to manual file picker.
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic'],
    withData: true,
  );
  final pickedFile = result?.files.single;
  if (pickedFile == null) {
    return null;
  }

  Uint8List? bytes = pickedFile.bytes;
  if (bytes == null && pickedFile.path != null) {
    final file = XFile(pickedFile.path!);
    bytes = await file.readAsBytes();
  }
  if (bytes == null) {
    return null;
  }

  return ReportMedia(
    bytes: bytes,
    fileName: pickedFile.name,
  );
}
