import 'dart:convert';

import 'package:flutter/services.dart';

import '../pipeline/benchmark_loader.dart';

/// Loads bundled benchmark JSON once at app start.
class CoachingBootstrap {
  CoachingBootstrap._();

  static const String benchmarksAsset = 'assets/data/cricket_benchmarks.json';

  static Future<Map<String, dynamic>> loadBenchmarks() async {
    final raw = await rootBundle.loadString(benchmarksAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return BenchmarkLoader.benchmarksOnly(decoded);
  }

  static List<String> shotNamesFromBenchmarks(Map<String, dynamic> benchmarks) {
    return benchmarks.keys.toList()..sort();
  }
}
