import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/app_breakpoints.dart';

void main() {
  group('AppBreakpoints', () {
    test('compact layout threshold stays aligned with mobile surfaces', () {
      expect(AppBreakpoints.isCompactLayoutWidth(719), isTrue);
      expect(AppBreakpoints.isCompactLayoutWidth(720), isFalse);
    });

    test('compact and ultra-compact helpers keep boundary behavior stable', () {
      expect(AppBreakpoints.isCompactFilterWidth(559), isTrue);
      expect(AppBreakpoints.isCompactFilterWidth(560), isFalse);
      expect(AppBreakpoints.isCompactControlsWidth(479), isTrue);
      expect(AppBreakpoints.isCompactControlsWidth(480), isFalse);
      expect(AppBreakpoints.isUltraCompactLayoutWidth(359), isTrue);
      expect(AppBreakpoints.isUltraCompactLayoutWidth(360), isFalse);
    });

    test('stacking and dialog helpers keep existing thresholds explicit', () {
      expect(AppBreakpoints.shouldStackHeader(259), isTrue);
      expect(AppBreakpoints.shouldStackHeader(260), isFalse);
      expect(AppBreakpoints.shouldStackMetadata(219), isTrue);
      expect(AppBreakpoints.shouldStackMetadata(220), isFalse);
      expect(AppBreakpoints.isCompactDialogWidth(599), isTrue);
      expect(AppBreakpoints.isCompactDialogWidth(600), isFalse);
      expect(AppBreakpoints.isShortViewportHeight(719), isTrue);
      expect(AppBreakpoints.isShortViewportHeight(720), isFalse);
      expect(AppBreakpoints.isShortPreviewHeight(219), isTrue);
      expect(AppBreakpoints.isShortPreviewHeight(220), isFalse);
    });

    test('text scale can trigger compact breakpoints on medium widths', () {
      expect(
        AppBreakpoints.isCompactLayoutWidth(760, textScaleFactor: 1.2),
        isTrue,
      );
      expect(
        AppBreakpoints.isCompactFilterWidth(600, textScaleFactor: 1.1),
        isTrue,
      );
      expect(
        AppBreakpoints.isCompactControlsWidth(500, textScaleFactor: 1.1),
        isTrue,
      );
      expect(
        AppBreakpoints.isCompactDialogWidth(640, textScaleFactor: 1.1),
        isTrue,
      );
      expect(
        AppBreakpoints.shouldStackHeader(300, textScaleFactor: 1.2),
        isTrue,
      );
      expect(
        AppBreakpoints.shouldStackMetadata(240, textScaleFactor: 1.1),
        isTrue,
      );
      expect(
        AppBreakpoints.isUltraCompactLayoutWidth(390, textScaleFactor: 1.1),
        isTrue,
      );
    });
  });
}
