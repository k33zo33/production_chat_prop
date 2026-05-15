import 'dart:convert';

import 'package:production_chat_prop/core/utils/export_file_name.dart';
import 'package:production_chat_prop/core/utils/file_download/file_downloader.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';

enum ProjectPackageExportFailure {
  downloadUnavailable,
}

class ProjectPackageExportResult {
  const ProjectPackageExportResult._({
    required this.isSuccess,
    required this.jsonText,
    this.failure,
    this.filename,
  });

  const ProjectPackageExportResult.success({
    required String filename,
    required String jsonText,
  }) : this._(isSuccess: true, filename: filename, jsonText: jsonText);

  const ProjectPackageExportResult.failure({
    required ProjectPackageExportFailure failure,
    required String jsonText,
    String? filename,
  }) : this._(
         isSuccess: false,
         failure: failure,
         filename: filename,
         jsonText: jsonText,
       );

  final bool isSuccess;
  final ProjectPackageExportFailure? failure;
  final String? filename;
  final String jsonText;
}

class ProjectPackageExportService {
  ProjectPackageExportService({BytesDownloader? downloader})
    : _downloader = downloader ?? downloadBytes;

  final BytesDownloader _downloader;

  String buildProjectPackageJson({required Project project}) {
    return const JsonEncoder.withIndent('  ').convert(
      _buildPayload(project: project),
    );
  }

  Future<ProjectPackageExportResult> exportProjectPackage({
    required Project project,
  }) async {
    final jsonText = buildProjectPackageJson(project: project);
    final encoded = utf8.encode(jsonText);
    final filename = _buildFileName(projectName: project.name);

    final isDownloaded = await _downloader(
      bytes: encoded,
      filename: filename,
      mimeType: 'application/json',
    );
    if (!isDownloaded) {
      return ProjectPackageExportResult.failure(
        failure: ProjectPackageExportFailure.downloadUnavailable,
        filename: filename,
        jsonText: jsonText,
      );
    }

    return ProjectPackageExportResult.success(
      filename: filename,
      jsonText: jsonText,
    );
  }

  Map<String, dynamic> _buildPayload({required Project project}) {
    return {
      'meta': {
        'tool': 'Production Chat Prop',
        'format': 'project_package',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
      },
      'project': project.toJson(),
    };
  }

  String _buildFileName({required String projectName}) {
    final timestamp = buildExportTimestamp();
    final safeProject = sanitizeExportFileNameSegment(
      projectName,
      fallback: 'project',
    );
    return 'pcp_project_${safeProject}_$timestamp.json';
  }
}
