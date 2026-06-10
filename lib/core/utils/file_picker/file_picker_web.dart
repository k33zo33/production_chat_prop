import 'dart:async';
import 'dart:js_interop';

import 'package:production_chat_prop/core/utils/file_picker/file_picker_types.dart';
import 'package:web/web.dart' as web;

Future<String?> pickTextFile({
  required String accept,
}) async {
  return _pickSingleFile(
    accept: accept,
    onFileSelected: (file, completeWith, completeWithError) {
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
    },
  );
}

Future<String?> pickFileAsDataUri({
  required String accept,
}) async {
  return _pickSingleFile(
    accept: accept,
    onFileSelected: (file, completeWith, completeWithError) {
      final fileSize = file.size;
      if (fileSize > kEmbeddedImageFileSizeLimitBytes) {
        completeWithError(
          FilePickerSizeException(
            maxBytes: kEmbeddedImageFileSizeLimitBytes,
            actualBytes: fileSize,
          ),
        );
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
        ..readAsDataURL(file);
    },
  );
}

Future<String?> _pickSingleFile({
  required String accept,
  required void Function(
    web.File file,
    void Function(String? value) completeWith,
    void Function(Object error) completeWithError,
  )
  onFileSelected,
}) async {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = accept
    ..style.display = 'none';
  Timer? cancelFallbackTimer;
  late final JSFunction cancelListener;
  late final JSFunction windowFocusListener;

  void cleanup() {
    cancelFallbackTimer?.cancel();
    input.removeEventListener('cancel', cancelListener);
    web.window.removeEventListener('focus', windowFocusListener);
    input.remove();
  }

  void completeWith(String? value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
    cleanup();
  }

  void completeWithError(Object error) {
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
    cleanup();
  }

  cancelListener = ((web.Event _) {
    completeWith(null);
  }).toJS;

  windowFocusListener = ((web.Event _) {
    final files = input.files;
    if (files != null && files.length > 0) {
      return;
    }

    cancelFallbackTimer?.cancel();
    cancelFallbackTimer = Timer(const Duration(milliseconds: 250), () {
      final nextFiles = input.files;
      if (nextFiles == null || nextFiles.length == 0) {
        completeWith(null);
      }
    });
  }).toJS;

  input.addEventListener('cancel', cancelListener);
  web.window.addEventListener('focus', windowFocusListener);

  input.onchange = ((web.Event _) {
    cancelFallbackTimer?.cancel();

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

    onFileSelected(file, completeWith, completeWithError);
  }).toJS;

  web.document.body?.append(input);
  input.click();
  return completer.future;
}
