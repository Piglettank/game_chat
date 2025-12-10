import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Save file on web by triggering a download
Future<bool> saveFile(String content, String fileName) async {
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    return true;
  } catch (e) {
    return false;
  }
}

/// Read file on web - not used since we use bytes from FilePicker
Future<String> readFile(String path) async {
  throw UnsupportedError('Use file.bytes on web instead of file path');
}
