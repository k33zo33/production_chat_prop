typedef TextFilePicker =
    Future<String?> Function({
      String accept,
    });

typedef DataUriFilePicker =
    Future<String?> Function({
      String accept,
    });

const int kEmbeddedImageFileSizeLimitBytes = 2 * 1024 * 1024;

class FilePickerSizeException implements Exception {
  const FilePickerSizeException({
    required this.maxBytes,
    required this.actualBytes,
  });

  final int maxBytes;
  final int actualBytes;
}
