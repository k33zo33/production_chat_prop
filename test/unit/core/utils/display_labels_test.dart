import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/core/utils/display_labels.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

void main() {
  group('ProjectTypeDisplayLabel', () {
    test('returns polished labels', () {
      expect(ProjectType.ad.label, 'Ad');
      expect(ProjectType.series.label, 'Series');
      expect(ProjectType.other.label, 'Other');
    });
  });

  group('SceneAspectRatioDisplayLabel', () {
    test('returns human-friendly ratio labels', () {
      expect(SceneAspectRatio.portrait9x16.label, '9:16');
      expect(SceneAspectRatio.landscape16x9.label, '16:9');
    });
  });
}
