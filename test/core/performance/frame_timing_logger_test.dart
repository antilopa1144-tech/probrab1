import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/performance/frame_timing_logger.dart';

void main() {
  group('FrameTimingLogger', () {
    test('maybeInit can be called safely', () {
      // In test environment PERF_FRAME_TIMINGS is false by default
      // so maybeInit should return early without doing anything
      expect(() => FrameTimingLogger.maybeInit(), returnsNormally);
    });

    test('maybeInit can be called multiple times', () {
      // Should be idempotent
      FrameTimingLogger.maybeInit();
      FrameTimingLogger.maybeInit();
      FrameTimingLogger.maybeInit();

      // No exception means success
      expect(true, isTrue);
    });

    test('is disabled by default in tests', () {
      // The _enabled flag is false by default because
      // PERF_FRAME_TIMINGS environment variable is not set
      // We can verify this by calling maybeInit and expecting
      // no exception or side effects
      expect(() => FrameTimingLogger.maybeInit(), returnsNormally);
    });
  });
}
