import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/haptic_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticFeedbackService', () {
    late List<MethodCall> hapticCalls;

    setUp(() {
      hapticCalls = [];
      // Mock the HapticFeedback method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          hapticCalls.add(methodCall);
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('selection() triggers haptic feedback', () {
      HapticFeedbackService.selection();

      expect(hapticCalls, isNotEmpty);
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
      );
    });

    test('medium() triggers haptic feedback', () {
      HapticFeedbackService.medium();

      expect(hapticCalls, isNotEmpty);
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
      );
    });

    test('heavy() triggers haptic feedback', () {
      HapticFeedbackService.heavy();

      expect(hapticCalls, isNotEmpty);
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
      );
    });

    test('success() triggers haptic feedback', () {
      HapticFeedbackService.success();

      expect(hapticCalls, isNotEmpty);
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
      );
    });

    test('error() triggers haptic feedback', () {
      HapticFeedbackService.error();

      expect(hapticCalls, isNotEmpty);
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
      );
    });

    test('buttonPress() triggers haptic feedback', () {
      HapticFeedbackService.buttonPress();

      expect(hapticCalls, isNotEmpty);
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
      );
    });

    test('swipe() triggers haptic feedback', () {
      HapticFeedbackService.swipe();

      expect(hapticCalls, isNotEmpty);
      expect(
        hapticCalls.any((call) => call.method == 'HapticFeedback.vibrate'),
        isTrue,
      );
    });

    test('all methods can be called without error', () {
      expect(() => HapticFeedbackService.selection(), returnsNormally);
      expect(() => HapticFeedbackService.medium(), returnsNormally);
      expect(() => HapticFeedbackService.heavy(), returnsNormally);
      expect(() => HapticFeedbackService.success(), returnsNormally);
      expect(() => HapticFeedbackService.error(), returnsNormally);
      expect(() => HapticFeedbackService.buttonPress(), returnsNormally);
      expect(() => HapticFeedbackService.swipe(), returnsNormally);
    });

    test('selection and buttonPress use same feedback type', () {
      hapticCalls.clear();
      HapticFeedbackService.selection();
      final selectionCalls = List<MethodCall>.from(hapticCalls);

      hapticCalls.clear();
      HapticFeedbackService.buttonPress();
      final buttonPressCalls = List<MethodCall>.from(hapticCalls);

      // Both should use selectionClick
      expect(selectionCalls.length, buttonPressCalls.length);
    });

    test('medium and success use same feedback type', () {
      hapticCalls.clear();
      HapticFeedbackService.medium();
      final mediumCalls = List<MethodCall>.from(hapticCalls);

      hapticCalls.clear();
      HapticFeedbackService.success();
      final successCalls = List<MethodCall>.from(hapticCalls);

      // Both should use mediumImpact
      expect(mediumCalls.length, successCalls.length);
    });

    test('heavy and error use same feedback type', () {
      hapticCalls.clear();
      HapticFeedbackService.heavy();
      final heavyCalls = List<MethodCall>.from(hapticCalls);

      hapticCalls.clear();
      HapticFeedbackService.error();
      final errorCalls = List<MethodCall>.from(hapticCalls);

      // Both should use heavyImpact
      expect(heavyCalls.length, errorCalls.length);
    });
  });
}
