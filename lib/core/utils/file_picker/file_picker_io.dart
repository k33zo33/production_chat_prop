import 'dart:io';

import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/foundation.dart';

const _kFlutterTestEnvironmentKey = 'FLUTTER_TEST';

Future<String?> pickTextFile({
  required String accept,
}) async {
  if (Platform.environment.containsKey(_kFlutterTestEnvironmentKey)) {
    return null;
  }

  try {
    final allowedExtensions = _allowedExtensionsFromAccept(accept);
    final result = await picker.FilePicker.platform.pickFiles(
      type:
          allowedExtensions.isEmpty
              ? picker.FileType.any
              : picker.FileType.custom,
      allowedExtensions:
          allowedExtensions.isEmpty ? null : allowedExtensions,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }

    return File(path).readAsString();
  } on Object catch (error) {
    debugPrint('Native file pick failed: $error');
    return null;
  }
}

List<String> _allowedExtensionsFromAccept(String accept) {
  return accept
      .split(',')
      .map((entry) => entry.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .map(_extensionFromAcceptEntry)
      .whereType<String>()
      .toSet()
      .toList(growable: false);
}

String? _extensionFromAcceptEntry(String entry) {
  if (entry.startsWith('.') && entry.length > 1) {
    return entry.substring(1);
  }

  if (!entry.contains('/')) {
    return null;
  }

  final subtype = entry.split('/').last;
  if (subtype.isEmpty || subtype.contains('*')) {
    return null;
  }

  return subtype.split('+').first;
}
