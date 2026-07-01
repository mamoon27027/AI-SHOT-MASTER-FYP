/// Helpers to parse `cricket_benchmarks.json` once loaded as a Dart map.

class BenchmarkLoader {
  BenchmarkLoader._();

  /// Extracts inner `"benchmarks"` object from root JSON decoded map.
  static Map<String, dynamic> benchmarksOnly(Map<String, dynamic> rootJson) {
    final b = rootJson['benchmarks'];
    if (b is! Map<String, dynamic>) {
      throw FormatException('Missing or invalid "benchmarks" object');
    }
    return Map<String, dynamic>.from(b);
  }

  /// Reads metadata block if present (optional UI / debugging).
  static Map<String, dynamic>? metadata(Map<String, dynamic> rootJson) {
    final m = rootJson['metadata'];
    if (m is Map<String, dynamic>) return Map<String, dynamic>.from(m);
    return null;
  }
}
