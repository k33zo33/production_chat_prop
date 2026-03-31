import 'dart:convert';

import 'package:production_chat_prop/core/utils/file_download/file_downloader.dart';
import 'package:production_chat_prop/features/projects/domain/project.dart';

enum ProjectPortfolioExportFailure {
  noProjects,
  downloadUnavailable,
}

class ProjectPortfolioExportResult {
  const ProjectPortfolioExportResult._({
    required this.isSuccess,
    this.failure,
    this.filename,
  });

  const ProjectPortfolioExportResult.success({required String filename})
    : this._(isSuccess: true, filename: filename);

  const ProjectPortfolioExportResult.failure({
    required ProjectPortfolioExportFailure failure,
  }) : this._(isSuccess: false, failure: failure);

  final bool isSuccess;
  final ProjectPortfolioExportFailure? failure;
  final String? filename;
}

class ProjectPortfolioExportService {
  ProjectPortfolioExportService({BytesDownloader? downloader})
    : _downloader = downloader ?? downloadBytes;

  final BytesDownloader _downloader;

  Future<ProjectPortfolioExportResult> exportPortfolio({
    required List<Project> projects,
  }) async {
    if (projects.isEmpty) {
      return const ProjectPortfolioExportResult.failure(
        failure: ProjectPortfolioExportFailure.noProjects,
      );
    }

    final payload = _buildPayload(projects: projects);
    final encoded = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    final filename = _buildFileName();

    final isDownloaded = await _downloader(
      bytes: encoded,
      filename: filename,
      mimeType: 'application/json',
    );
    if (!isDownloaded) {
      return const ProjectPortfolioExportResult.failure(
        failure: ProjectPortfolioExportFailure.downloadUnavailable,
      );
    }

    return ProjectPortfolioExportResult.success(filename: filename);
  }

  Map<String, dynamic> _buildPayload({
    required List<Project> projects,
  }) {
    return {
      'meta': {
        'tool': 'Production Chat Prop',
        'format': 'project_portfolio',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
      },
      'projects': projects.map((project) => project.toJson()).toList(),
    };
  }

  String _buildFileName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'pcp_project_portfolio_$timestamp.json';
  }
}
