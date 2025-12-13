import 'dart:ui';

/// Lightweight frame timing logger for profile/release runs.
///
/// Enable with: `--dart-define=PERF_FRAME_TIMINGS=true`
class FrameTimingLogger {
  static const bool _enabled =
      bool.fromEnvironment('PERF_FRAME_TIMINGS', defaultValue: false);

  static bool _installed = false;

  static final List<double> _totalMs = <double>[];
  static int _seenFrames = 0;

  static void maybeInit() {
    if (!_enabled || _installed) return;
    _installed = true;

    final previous = PlatformDispatcher.instance.onReportTimings;
    PlatformDispatcher.instance.onReportTimings = (timings) {
      previous?.call(timings);
      _onTimings(timings);
    };

    // One-time marker so it's obvious in logs.
    // ignore: avoid_print
    print('[PERF] FrameTimingLogger enabled (PERF_FRAME_TIMINGS=true)');
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _seenFrames++;
      _totalMs.add(timing.totalSpan.inMicroseconds / 1000.0);
    }

    // Keep a rolling window (avoid unbounded memory).
    const maxSamples = 600;
    if (_totalMs.length > maxSamples) {
      _totalMs.removeRange(0, _totalMs.length - maxSamples);
    }

    // Print periodic summaries. Avoid spamming logs on every frame.
    if (_seenFrames % 120 != 0) return;

    final samples = List<double>.from(_totalMs)..sort();
    final avg = _totalMs.isEmpty
        ? 0.0
        : _totalMs.reduce((a, b) => a + b) / _totalMs.length;
    final p90 = _percentile(samples, 0.90);
    final p99 = _percentile(samples, 0.99);
    final jank16 = _totalMs.where((ms) => ms > 16.67).length;
    final jank33 = _totalMs.where((ms) => ms > 33.33).length;

    // ignore: avoid_print
    print(
      '[PERF] frames=$_seenFrames window=${_totalMs.length} '
      'avg=${avg.toStringAsFixed(1)}ms p90=${p90.toStringAsFixed(1)}ms '
      'p99=${p99.toStringAsFixed(1)}ms jank>16ms=$jank16 jank>33ms=$jank33',
    );
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0.0;
    final index =
        (p.clamp(0.0, 1.0) * (sorted.length - 1)).round().clamp(0, sorted.length - 1);
    return sorted[index];
  }
}
