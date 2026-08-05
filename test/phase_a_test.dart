import "package:flutter_quill/flutter_quill.dart";
import "package:test/test.dart";

void main() {
  group("BlockEmbed statics — Phase A2", () {
    test("customType is a static const String", () {
      expect(BlockEmbed.customType, equals("custom"));
    });

    test("formulaType is a static const String", () {
      expect(BlockEmbed.formulaType, equals("formula"));
    });

    test("custom() returns a BlockEmbed with customType", () {
      final embed = BlockEmbed.custom(const _TestCustomBlock());
      expect(embed, isA<BlockEmbed>());
      expect(embed.type, equals("custom"));
    });

    test("formula() returns a BlockEmbed with formulaType", () {
      final embed = BlockEmbed.formula("x^2 + y^2");
      expect(embed, isA<BlockEmbed>());
      expect(embed.type, equals("formula"));
      expect(embed.data, equals("x^2 + y^2"));
    });
  });

  group("FormatAttribute named constructor — Phase A1", () {
    test("constructor accepts named parameters", () {
      const attr = FormatAttribute.bold;
      expect(attr.key, equals("bold"));
      expect(attr.scope, equals(FormatScope.inline));
      expect(attr.value, equals(true));
      expect(attr.valueType, equals(FormatValueType.boolean));
    });

    test("constructor is const-compatible with null value", () {
      const attr = FormatAttribute.color;
      expect(attr.value, isNull);
    });

    test("link named constant exists and has correct key", () {
      expect(FormatAttribute.link.key, equals("link"));
      expect(FormatAttribute.link.scope, equals(FormatScope.inline));
    });

    test("bold named constant exists and has correct key", () {
      expect(FormatAttribute.bold.key, equals("bold"));
      expect(FormatAttribute.bold.scope, equals(FormatScope.inline));
    });
  });
}

class _TestCustomBlock extends CustomBlockEmbed {
  const _TestCustomBlock() : super("custom", "test-data");
}
