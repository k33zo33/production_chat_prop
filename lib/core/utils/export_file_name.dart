String buildExportTimestamp([DateTime? now]) {
  final value = now ?? DateTime.now();
  return '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}_'
      '${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}'
      '${value.second.toString().padLeft(2, '0')}';
}

String sanitizeExportFileNameSegment(
  String value, {
  required String fallback,
  int maxLength = 40,
}) {
  final sanitizedFallback = _sanitizeSegment(fallback);
  final resolvedFallback = sanitizedFallback.isEmpty
      ? 'item'
      : sanitizedFallback;
  final sanitizedValue = _sanitizeSegment(value);
  final candidate = sanitizedValue.isEmpty ? resolvedFallback : sanitizedValue;

  if (candidate.length <= maxLength) {
    return candidate;
  }

  final truncated = candidate.substring(0, maxLength);
  final trimmed = truncated.replaceFirst(RegExp(r'_+$'), '');
  return trimmed.isEmpty ? resolvedFallback : trimmed;
}

String _sanitizeSegment(String value) {
  final normalized = value.trim().toLowerCase();
  final replaced = normalized.replaceAll(RegExp('[^a-z0-9]+'), '_');
  return replaced
      .replaceAll(RegExp('_+'), '_')
      .replaceFirst(RegExp('^_+'), '')
      .replaceFirst(RegExp(r'_+$'), '');
}
