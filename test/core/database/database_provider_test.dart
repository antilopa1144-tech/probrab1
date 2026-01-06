import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/database/database_provider.dart';

void main() {
  group('isarProvider', () {
    test('is a FutureProvider', () {
      expect(isarProvider, isA<FutureProvider>());
    });

    test('provider exists and can be accessed', () {
      // Just verify the provider is correctly defined
      // Actual Isar initialization requires platform support
      expect(isarProvider, isNotNull);
    });
  });
}
