import 'package:production_chat_prop/core/utils/file_picker/file_picker_stub.dart'
    if (dart.library.io) 'package:production_chat_prop/core/utils/file_picker/file_picker_io.dart'
    if (dart.library.html) 'package:production_chat_prop/core/utils/file_picker/file_picker_web.dart'
    as impl;

export 'package:production_chat_prop/core/utils/file_picker/file_picker_types.dart';

Future<String?> pickTextFile({
  String accept = '.json,application/json',
}) {
  return impl.pickTextFile(accept: accept);
}

Future<String?> pickFileAsDataUri({
  String accept = 'image/png,image/jpeg,image/webp,image/gif',
}) {
  return impl.pickFileAsDataUri(accept: accept);
}
