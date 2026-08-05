import 'package:flutter_quill/flutter_quill.dart';
import 'package:test/test.dart';

void main() {
  /// Attributes are assigned an FormatScope to define how they are used.
  /// Collections of FormatAttribute keys are used to allow quick iteration by type of scope.
  group('collections of keys', () {
    test('unmodifiable inlineKeys', () {
      expect(
        () => FormatAttribute.inlineKeys.add('value'),
        throwsA(const TypeMatcher<UnsupportedError>()),
      );
    });

    /// All registered attributes should be listed in collections of keys.
    test('collections of keys', () {
      final all = <String>{}..addAll(FormatAttribute.registeredAttributeKeys);
      for (final key in FormatAttribute.inlineKeys) {
        expect(all.remove(key), true);
      }
      for (final key in FormatAttribute.blockKeys) {
        expect(all.remove(key), true);
      }
      for (final key in FormatAttribute.metadataKeys) {
        expect(all.remove(key), true);
      }
      expect(all, <String>{});
    });

    /// verify collections contain the correct FormatScope.
    test('collections of scope', () {
      for (final key in FormatAttribute.inlineKeys) {
        expect(
          FormatAttribute.fromKeyValue(key, null)!.scope,
          FormatScope.inline,
        );
      }
      for (final key in FormatAttribute.blockKeys) {
        expect(
          FormatAttribute.fromKeyValue(key, null)!.scope,
          FormatScope.block,
        );
      }
    });
  });
}
