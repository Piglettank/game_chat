import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// Save file on native platforms using file picker
Future<bool> saveFile(String content, String fileName) async {
  try {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Tournament',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(content);
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

/// Read file on native platforms
Future<String> readFile(String path) async {
  final file = File(path);
  return await file.readAsString();
}
