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

  static bool isCompactDialogWidth(double width) {
    return width < compactDialogWidth;
  }

  static bool isCompactLayoutWidth(double width) {
    return width < compactLayoutWidth;
  }

  static bool isShortViewportHeight(double height) {
    return height < shortViewportHeight;
  }

  static bool isCompactFilterWidth(double width) {
    return width < compactFilterWidth;
  }

  static bool isCompactControlsWidth(double width) {
    return width < compactControlsWidth;
  }

  static bool isUltraCompactLayoutWidth(double width) {
    return width < ultraCompactLayoutWidth;
  }

  static bool shouldStackHeader(double width) {
    return width < stackedHeaderWidth;
  }

  static bool shouldStackMetadata(double width) {
    return width < stackedMetadataWidth;
  }

  static bool isShortPreviewHeight(double height) {
    return height < shortPreviewHeight;
  }
}
