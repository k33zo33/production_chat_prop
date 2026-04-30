import 'package:production_chat_prop/features/projects/domain/project.dart';
import 'package:production_chat_prop/features/projects/domain/scene.dart';

extension ProjectTypeDisplayLabel on ProjectType {
  String get label {
    return switch (this) {
      ProjectType.ad => 'Ad',
      ProjectType.series => 'Series',
      ProjectType.other => 'Other',
    };
  }
}

extension SceneAspectRatioDisplayLabel on SceneAspectRatio {
  String get label {
    return switch (this) {
      SceneAspectRatio.portrait9x16 => '9:16',
      SceneAspectRatio.landscape16x9 => '16:9',
    };
  }
}
