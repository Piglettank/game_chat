import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Save file on web by triggering a download
Future<bool> saveFile(String content, String fileName) async {
  try {
    final bytes = utf8.encode(content);
    final blobParts = [bytes.toJS].toJS;
    final blobOptions = web.BlobPropertyBag(type: 'application/json');
    final blob = web.Blob(blobParts, blobOptions);
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);

    return true;
  } catch (e) {
    return false;
  }
}

/// Read file on web - not used since we use bytes from FilePicker
Future<String> readFile(String path) async {
  throw UnsupportedError('Use file.bytes on web instead of file path');
}
