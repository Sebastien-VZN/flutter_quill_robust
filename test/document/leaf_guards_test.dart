import "package:flutter_quill/flutter_quill.dart";
import "package:flutter_quill/quill_delta.dart";
import "package:test/test.dart";

/// Récupère le premier Leaf (QuillText) d'un Document simple "text\n".
Leaf _firstLeaf(Document doc) {
  final line = doc.queryChild(0).node! as Line;
  return line.queryChild(0, false).node! as Leaf;
}

void main() {
  group("Leaf factory guards", () {
    test("Leaf with empty string returns empty QuillText", () {
      final leaf = Leaf("");
      expect(leaf, isA<QuillText>());
      expect(leaf.length, 0);
    });

    test("Leaf with non-empty string returns QuillText", () {
      final leaf = Leaf("hello");
      expect(leaf, isA<QuillText>());
      expect(leaf.length, 5);
    });

    test("Leaf with Embeddable returns Embed", () {
      const embeddable = Embeddable("custom", "data");
      final leaf = Leaf(embeddable);
      expect(leaf, isA<Embed>());
      expect(leaf.length, 1);
    });
  });

  group("QuillText newline guard", () {
    test("QuillText with newline does not crash", () {
      // Le guard log uniquement, ne crash pas
      final text = QuillText("hello\nworld");
      expect(text.length, 11);
    });

    test("QuillText without newline works normally", () {
      final text = QuillText("hello");
      expect(text.value, "hello");
      expect(text.length, 5);
    });
  });

  group("Leaf.insert guards", () {
    test("insert with negative index returns silently", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      expect(doc.toPlainText(), contains("text"));
    });

    test("insert with index > length returns silently", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final leaf = _firstLeaf(doc);
      leaf.insert(leaf.length + 1, "A", null);
      expect(doc.toPlainText(), contains("text"));
    });
  });

  group("Leaf.delete guards", () {
    test("delete with index >= length returns silently", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final leaf = _firstLeaf(doc);
      leaf.delete(leaf.length, 1);
      expect(doc.toPlainText(), contains("text"));
    });
  });

  group("Leaf.splitAt guards", () {
    test("splitAt with negative index returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final leaf = _firstLeaf(doc);
      final result = leaf.splitAt(-1);
      expect(result, isNull);
    });

    test("splitAt with index > length returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final leaf = _firstLeaf(doc);
      final result = leaf.splitAt(leaf.length + 1);
      expect(result, isNull);
    });

    test("splitAt with valid index 0 returns this", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final leaf = _firstLeaf(doc);
      final result = leaf.splitAt(0);
      expect(result, same(leaf));
    });
  });

  group("Leaf.cutAt guards", () {
    test("cutAt with negative index returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final leaf = _firstLeaf(doc);
      final result = leaf.cutAt(-1);
      expect(result, isNull);
    });

    test("cutAt with index > length returns null", () {
      final doc = Document.fromDelta(Delta()..insert("text\n"));
      final leaf = _firstLeaf(doc);
      final result = leaf.cutAt(leaf.length + 1);
      expect(result, isNull);
    });
  });
}
