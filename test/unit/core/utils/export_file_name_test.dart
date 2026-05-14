import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/export_file_name.dart';

void main() {
  group('sanitizeExportFileNameSegment', () {
    test('falls back when the source value sanitizes to empty', () {
      expect(
        sanitizeExportFileNameSegment('###   ', fallback: 'project'),
        'project',
      );
    });

    test('collapses separators and trims surrounding underscores', () {
      expect(
        sanitizeExportFileNameSegment('  Demo /// Scene   01  ', fallback: 'x'),
        'demo_scene_01',
      );
    });

    test('truncates long segments without leaving a trailing underscore', () {
      expect(
        sanitizeExportFileNameSegment(
          'alpha beta gamma delta epsilon zeta eta theta',
          fallback: 'project',
          maxLength: 16,
        ),
        'alpha_beta_gamma',
      );
    });

    test('uses a safe default when the fallback is also empty', () {
      expect(
        sanitizeExportFileNameSegment('***', fallback: '   '),
        'item',
      );
    });
  });

  test('buildExportTimestamp keeps zero-padded ordering-friendly format', () {
    expect(
      buildExportTimestamp(DateTime(2026, 5, 4, 3, 2, 1)),
      '20260504_030201',
    );
  });
}
