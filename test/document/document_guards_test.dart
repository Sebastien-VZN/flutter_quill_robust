import "package:flutter/material.dart";
import "package:flutter_quill/flutter_quill.dart";
import "package:flutter_quill/quill_delta.dart";
import "package:test/test.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group("Document.insert guards", () {
    test("insert with valid index and String returns non-null Delta", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.insert(0, "A");
      expect(delta, isNotNull);
      expect(delta!.isNotEmpty, isTrue);
    });

    test("insert with negative index returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.insert(-1, "A");
      expect(delta, isNull);
    });

    test("insert with invalid data type returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.insert(0, 42);
      expect(delta, isNull);
    });

    test("insert empty string returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.insert(0, "");
      expect(delta, isNull);
    });

    test("insert Embeddable converts to JSON and composes", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final embed = BlockEmbed.formula("x^2");
      final delta = doc.insert(0, embed);
      expect(delta, isNotNull);
    });
  });

  group("Document.delete guards", () {
    test("delete with valid index and len returns non-null Delta", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.delete(0, 2);
      expect(delta, isNotNull);
      expect(delta!.isNotEmpty, isTrue);
    });

    test("delete with negative index returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.delete(-1, 2);
      expect(delta, isNull);
    });

    test("delete with zero len returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.delete(0, 0);
      expect(delta, isNull);
    });

    test("delete with negative len returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.delete(0, -1);
      expect(delta, isNull);
    });
  });

  group("Document.replace guards", () {
    test("replace with valid params returns non-null Delta", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.replace(0, 2, "AB");
      expect(delta, isNotNull);
    });

    test("replace with negative index returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.replace(-1, 2, "AB");
      expect(delta, isNull);
    });

    test("replace with invalid data type returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.replace(0, 2, 42);
      expect(delta, isNull);
    });

    test("replace with empty string and zero len returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.replace(0, 0, "");
      expect(delta, isNull);
    });

    test("replace with Delta data composes correctly", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final pasteDelta = Delta()..insert("pasted");
      final delta = doc.replace(0, 2, pasteDelta);
      expect(delta, isNotNull);
    });
  });

  group("Document.format guards", () {
    test("format with valid params returns empty Delta (no change)", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.format(0, 2, FormatAttribute.bold);
      expect(delta, isNotNull);
    });

    test("format with negative index returns empty Delta", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.format(-1, 2, FormatAttribute.bold);
      expect(delta, isEmpty);
    });

    test("format with null attribute returns empty Delta", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.format(0, 2, null);
      expect(delta, isEmpty);
    });

    test("format with negative len returns empty Delta", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final delta = doc.format(0, -1, FormatAttribute.bold);
      expect(delta, isEmpty);
    });
  });

  group("Document.compose guards", () {
    test("compose with valid Delta modifies document", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final before = doc.toDelta();
      doc.compose(
        Delta()
          ..insert("X")
          ..retain(1),
        ChangeSource.local,
      );
      final after = doc.toDelta();
      expect(before != after, isTrue);
    });

    test("compose with empty Delta returns early (no change)", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final before = doc.toDelta();
      doc.compose(Delta(), ChangeSource.local);
      final after = doc.toDelta();
      expect(before, equals(after));
    });

    test("compose with closed observer returns early", () async {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final before = doc.toDelta();
      await doc.close();
      doc.compose(Delta()..insert("X"), ChangeSource.local);
      final after = doc.toDelta();
      expect(before, equals(after));
    });
  });

  group("Document.loadDocument guards", () {
    test("loadDocument with valid Delta loads correctly", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      expect(doc.toPlainText(), contains("text"));
    });

    test("loadDocument with Delta not ending in newline returns early", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"))..loadDocument(Delta()..insert("no-newline"));
      expect(doc.toPlainText(), contains("text"));
    });

    test("loadDocument with empty Delta throws ArgumentError", () {
      expect(() => Document.fromDelta(Delta()), throwsArgumentError);
    });
  });

  group("Document.close", () {
    test("close returns Future<void>", () async {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final result = doc.close();
      expect(result, isA<Future<void>>());
      await result;
    });
  });

  group("QuillController.compose named parameters", () {
    test("compose with named parameters works correctly", () {
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert("test"),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        );
      expect(controller.document.toPlainText(), contains("test"));
    });
  });

  group("Document.insert return type nullable", () {
    test("insert return type is Delta?", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final result = doc.insert(0, "A");
      expect(result, isA<Delta?>());
    });
  });

  group("Document.fromJson typed parameter", () {
    test("fromJson accepts List<dynamic>", () {
      final json = [
        {"insert": "hello\n"},
      ];
      final doc = Document.fromJson(json);
      expect(doc.toPlainText(), contains("hello"));
    });
  });

  group("Document.collectAllIndividualStyleAndEmbed return type", () {
    test("returns List<StyledNodeEntry>", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final result = doc.collectAllIndividualStyleAndEmbed(0, 2);
      expect(result, isA<List<StyledNodeEntry>>());
    });
  });
}
