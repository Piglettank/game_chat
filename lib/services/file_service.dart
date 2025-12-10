import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/tournament.dart';

// Conditional import for web vs native
import 'file_service_stub.dart'
    if (dart.library.html) 'file_service_web.dart'
    if (dart.library.io) 'file_service_native.dart'
    as platform;

class FileService {
  /// Save tournament to a JSON file
  static Future<bool> saveTournament(Tournament tournament) async {
    try {
      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(tournament.toJson());

      // Add date and time to filename
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${_pad(now.month)}-${_pad(now.day)}_${_pad(now.hour)}-${_pad(now.minute)}';
      final fileName = '${_sanitizeFileName(tournament.title)}_$timestamp.json';

      return await platform.saveFile(jsonString, fileName);
    } catch (e) {
      debugPrint('Error saving tournament: $e');
      return false;
    }
  }

  /// Pad single digit numbers with leading zero
  static String _pad(int number) {
    return number.toString().padLeft(2, '0');
  }

  /// Load tournament from a JSON file
  static Future<Tournament?> loadTournament() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Open Tournament',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true, // Important for web - loads file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        String jsonString;
        if (file.bytes != null) {
          // Web: use bytes
          jsonString = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          // Native: use path
          jsonString = await platform.readFile(file.path!);
        } else {
          return null;
        }

        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return Tournament.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading tournament: $e');
      return null;
    }
  }

  /// Sanitize file name by removing invalid characters
  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
