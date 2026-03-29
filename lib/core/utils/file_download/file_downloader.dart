import 'package:production_chat_prop/core/utils/file_download/file_downloader_stub.dart'
    if (dart.library.html)
    'package:production_chat_prop/core/utils/file_download/file_downloader_web.dart'
    as impl;

Future<bool> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) {
  return impl.downloadBytes(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}
