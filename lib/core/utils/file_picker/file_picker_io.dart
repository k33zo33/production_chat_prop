import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/foundation.dart';
import 'package:production_chat_prop/core/utils/file_picker/file_picker_types.dart';

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
      type: allowedExtensions.isEmpty
          ? picker.FileType.any
          : picker.FileType.custom,
      allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
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

Future<String?> pickFileAsDataUri({
  required String accept,
}) async {
  if (Platform.environment.containsKey(_kFlutterTestEnvironmentKey)) {
    return null;
  }

  try {
    final allowedExtensions = _allowedExtensionsFromAccept(accept);
    final result = await picker.FilePicker.platform.pickFiles(
      type: allowedExtensions.isEmpty
          ? picker.FileType.any
          : picker.FileType.custom,
      allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.size > kEmbeddedImageFileSizeLimitBytes) {
      throw FilePickerSizeException(
        maxBytes: kEmbeddedImageFileSizeLimitBytes,
        actualBytes: file.size,
      );
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }

    final mimeType = _imageMimeTypeFromPath(path);
    if (mimeType == null) {
      return null;
    }

    final bytes = await File(path).readAsBytes();
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  } on FilePickerSizeException {
    rethrow;
  } on Object catch (error) {
    debugPrint('Native file pick failed: $error');
    rethrow;
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

String? _imageMimeTypeFromPath(String path) {
  final lastDotIndex = path.lastIndexOf('.');
  if (lastDotIndex < 0 || lastDotIndex == path.length - 1) {
    return null;
  }

  final extension = path.substring(lastDotIndex + 1).toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => null,
  };
}
