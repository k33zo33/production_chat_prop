import 'package:production_chat_prop/core/utils/file_picker/file_picker_stub.dart'
    if (dart.library.html) 'package:production_chat_prop/core/utils/file_picker/file_picker_web.dart'
    as impl;

typedef TextFilePicker =
    Future<String?> Function({
      String accept,
    });

Future<String?> pickTextFile({
  String accept = '.json,application/json',
}) {
  return impl.pickTextFile(accept: accept);
}
