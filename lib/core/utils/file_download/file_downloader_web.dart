import 'dart:convert';

import 'package:web/web.dart' as web;

Future<bool> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final encoded = base64Encode(bytes);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = 'data:$mimeType;base64,$encoded'
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor
    ..click()
    ..remove();
  return true;
}
