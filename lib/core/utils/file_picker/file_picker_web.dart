import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String?> pickTextFile({
  required String accept,
}) async {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = accept
    ..style.display = 'none';

  void completeWith(String? value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
    input.remove();
  }

  input.onchange = ((web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      completeWith(null);
      return;
    }

    final file = files.item(0);
    if (file == null) {
      completeWith(null);
      return;
    }

    final reader = web.FileReader();
    reader
      ..onload = ((web.Event _) {
        final result = reader.result;
        if (result == null) {
          completeWith(null);
          return;
        }
        completeWith((result as Object).toString());
      }).toJS
      ..onerror = ((web.Event _) {
        completeWith(null);
      }).toJS
      ..readAsText(file);
  }).toJS;

  web.document.body?.append(input);
  input.click();
  return completer.future;
}
