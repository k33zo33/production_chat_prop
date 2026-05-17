import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final body = web.document.body;
  if (body == null) {
    return false;
  }

  // Data URIs become unreliable for larger exports, especially screenshots.
  // Blob-backed object URLs keep web downloads working for beta-scale payloads.
  final byteBuffer = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final blob = web.Blob(
    <web.BlobPart>[byteBuffer.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = objectUrl
    ..download = filename
    ..style.display = 'none';

  try {
    body.append(anchor);
    anchor.click();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return true;
  } on Object {
    return false;
  } finally {
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);
  }
}
