import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

const _kFlutterTestEnvironmentKey = 'FLUTTER_TEST';

Future<bool> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  if (Platform.environment.containsKey(_kFlutterTestEnvironmentKey)) {
    return false;
  }

  try {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'production_chat_prop_export_',
    );
    final file = File('${tempDirectory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile(
            file.path,
            mimeType: mimeType,
            name: filename,
          ),
        ],
        fileNameOverrides: <String>[filename],
        sharePositionOrigin: _defaultSharePositionOrigin(),
        subject: filename,
        text: 'Production Chat Prop export',
      ),
    );

    return result.status != ShareResultStatus.unavailable;
  } on Object catch (error) {
    debugPrint('Native file share failed: $error');
    return false;
  }
}

ui.Rect? _defaultSharePositionOrigin() {
  final views = ui.PlatformDispatcher.instance.views;
  if (views.isEmpty) {
    return null;
  }

  final view = views.first;
  final devicePixelRatio = view.devicePixelRatio;
  if (devicePixelRatio <= 0) {
    return null;
  }

  final logicalWidth = view.physicalSize.width / devicePixelRatio;
  final logicalHeight = view.physicalSize.height / devicePixelRatio;
  if (logicalWidth <= 0 || logicalHeight <= 0) {
    return null;
  }

  return ui.Rect.fromLTWH(0, 0, logicalWidth, logicalHeight);
}
