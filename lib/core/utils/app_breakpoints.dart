abstract final class AppBreakpoints {
  static const double compactDialogWidth = 600;
  static const double compactLayoutWidth = 720;
  static const double shortViewportHeight = 720;
  static const double compactFilterWidth = 560;
  static const double compactControlsWidth = 480;
  static const double ultraCompactLayoutWidth = 360;
  static const double stackedHeaderWidth = 260;
  static const double stackedMetadataWidth = 220;
  // Shared by the playback preview “short layout” check and the focus-preview
  // minimum height floor so those behaviors stay aligned.
  static const double shortPreviewHeight = 220;

  static double _effectiveWidth(
    double width, {
    double textScaleFactor = 1,
  }) {
    final normalizedTextScale = textScaleFactor < 1 ? 1.0 : textScaleFactor;
    return width / normalizedTextScale;
  }

  static bool isCompactDialogWidth(
    double width, {
    double textScaleFactor = 1,
  }) {
    return _effectiveWidth(width, textScaleFactor: textScaleFactor) <
        compactDialogWidth;
  }

  static bool isCompactLayoutWidth(
    double width, {
    double textScaleFactor = 1,
  }) {
    return _effectiveWidth(width, textScaleFactor: textScaleFactor) <
        compactLayoutWidth;
  }

  static bool isShortViewportHeight(double height) {
    return height < shortViewportHeight;
  }

  static bool isCompactFilterWidth(
    double width, {
    double textScaleFactor = 1,
  }) {
    return _effectiveWidth(width, textScaleFactor: textScaleFactor) <
        compactFilterWidth;
  }

  static bool isCompactControlsWidth(
    double width, {
    double textScaleFactor = 1,
  }) {
    return _effectiveWidth(width, textScaleFactor: textScaleFactor) <
        compactControlsWidth;
  }

  static bool isUltraCompactLayoutWidth(
    double width, {
    double textScaleFactor = 1,
  }) {
    return _effectiveWidth(width, textScaleFactor: textScaleFactor) <
        ultraCompactLayoutWidth;
  }

  static bool shouldStackHeader(
    double width, {
    double textScaleFactor = 1,
  }) {
    return _effectiveWidth(width, textScaleFactor: textScaleFactor) <
        stackedHeaderWidth;
  }

  static bool shouldStackMetadata(
    double width, {
    double textScaleFactor = 1,
  }) {
    return _effectiveWidth(width, textScaleFactor: textScaleFactor) <
        stackedMetadataWidth;
  }

  static bool isShortPreviewHeight(double height) {
    return height < shortPreviewHeight;
  }
}
