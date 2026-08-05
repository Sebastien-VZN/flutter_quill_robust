import 'package:flutter/foundation.dart' show debugPrint, immutable;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/src/document/document.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/rules/rule.dart';

/// A heuristic rule for format (retain) operations.
@immutable
abstract class FormatRule extends Rule {
  const FormatRule();

  @override
  RuleType get type => RuleType.format;

  @override
  void validateArgs(int? len, Object? data, FormatAttribute? attribute) {
    if (len == null) {
      debugPrint('FormatRule.validateArgs — len is null, expected non-null');
    }
    if (data != null) {
      debugPrint(
        'FormatRule.validateArgs — data is non-null, expected null: $data',
      );
    }
    if (attribute == null) {
      debugPrint(
        'FormatRule.validateArgs — attribute is null, expected non-null',
      );
    }
  }
}

/// Produces Delta with line-level attributes applied strictly to
/// newline characters.
@immutable
class ResolveLineFormatRule extends FormatRule {
  const ResolveLineFormatRule();

  @override
  Delta? applyRule(
    Document document,
    int index, {
    int? len,
    Object? data,
    FormatAttribute? attribute,
  }) {
    if (attribute!.scope != FormatScope.block) {
      return null;
    }

    // Apply line styles to all newline characters within range of this
    // retain operation.
    var result = Delta()..retain(index);
    final itr = DeltaIterator(document.toDelta())..skip(index);
    Operation op;
    for (var cur = 0; cur < len! && itr.hasNext; cur += op.length!) {
      op = itr.next(len - cur);
      final opText = op.data is String ? op.data! as String : '';
      if (!opText.contains('\n')) {
        result.retain(op.length!);
        continue;
      }

      final delta = _applyAttribute(opText, op, attribute);
      result = result.concat(delta);
    }
    // And include extra newline after retain
    while (itr.hasNext) {
      op = itr.next();
      final opText = op.data is String ? op.data! as String : '';
      final lf = opText.indexOf('\n');
      if (lf < 0) {
        result.retain(op.length!);
        continue;
      }

      final delta = _applyAttribute(opText, op, attribute, firstOnly: true);
      result = result.concat(delta);
      break;
    }
    return result;
  }

  Delta _applyAttribute(
    String text,
    Operation op,
    FormatAttribute attribute, {
    bool firstOnly = false,
  }) {
    final result = Delta();
    var offset = 0;
    var lf = text.indexOf('\n');
    final removedBlocks = _getRemovedBlocks(attribute, op);
    while (lf >= 0) {
      final actualStyle = attribute.toJson()..addEntries(removedBlocks);
      result
        ..retain(lf - offset)
        ..retain(1, attributes: actualStyle);

      if (firstOnly) {
        return result;
      }

      offset = lf + 1;
      lf = text.indexOf('\n', offset);
    }
    // Retain any remaining characters in text
    result.retain(text.length - offset);
    return result;
  }

  Iterable<MapEntry<String, dynamic>> _getRemovedBlocks(
    FormatAttribute attribute,
    Operation op,
  ) {
    // Enforce Block Format exclusivity by rule
    if (!FormatAttribute.exclusiveBlockKeys.contains(attribute.key)) {
      return <MapEntry<String, dynamic>>[];
    }

    return op.attributes?.keys
            .where(
              (key) => FormatAttribute.exclusiveBlockKeys.contains(key) && attribute.key != key && attribute.value != null,
            )
            .map((key) => MapEntry<String, dynamic>(key, null)) ??
        [];
  }
}

/// Allows updating link format with collapsed selection.
@immutable
class FormatLinkAtCaretPositionRule extends FormatRule {
  const FormatLinkAtCaretPositionRule();

  @override
  Delta? applyRule(
    Document document,
    int index, {
    int? len,
    Object? data,
    FormatAttribute? attribute,
  }) {
    if (attribute!.key != FormatAttribute.link.key || len! > 0) {
      return null;
    }

    final delta = Delta();
    final itr = DeltaIterator(document.toDelta());
    final before = itr.skip(index);
    final after = itr.next();
    var beg = index;
    var retain = 0;
    if (before != null && before.hasAttribute(attribute.key)) {
      beg -= before.length!;
      retain = before.length!;
    }
    if (after.hasAttribute(attribute.key)) {
      retain += after.length!;
    }
    if (retain == 0) {
      return null;
    }

    delta
      ..retain(beg)
      ..retain(retain, attributes: attribute.toJson());
    return delta;
  }
}

/// Produces Delta with inline-level attributes applied to all characters
/// except newlines.
@immutable
class ResolveInlineFormatRule extends FormatRule {
  const ResolveInlineFormatRule();

  @override
  Delta? applyRule(
    Document document,
    int index, {
    int? len,
    Object? data,
    FormatAttribute? attribute,
  }) {
    if (attribute!.scope != FormatScope.inline) {
      return null;
    }

    final delta = Delta()..retain(index);
    final itr = DeltaIterator(document.toDelta())..skip(index);

    Operation op;
    for (var cur = 0; cur < len! && itr.hasNext; cur += op.length!) {
      op = itr.next(len - cur);
      final text = op.data is String ? (op.data as String?)! : '';
      var lineBreak = text.indexOf('\n');
      if (lineBreak < 0) {
        delta.retain(op.length!, attributes: attribute.toJson());
        continue;
      }
      var pos = 0;
      while (lineBreak >= 0) {
        delta
          ..retain(lineBreak - pos, attributes: attribute.toJson())
          ..retain(1);
        pos = lineBreak + 1;
        lineBreak = text.indexOf('\n', pos);
      }
      if (pos < op.length!) {
        delta.retain(op.length! - pos, attributes: attribute.toJson());
      }
    }

    return delta;
  }
}

/// Produces Delta with attributes applied to image leaf node
@immutable
class ResolveImageFormatRule extends FormatRule {
  const ResolveImageFormatRule();

  @override
  Delta? applyRule(
    Document document,
    int index, {
    int? len,
    Object? data,
    FormatAttribute? attribute,
  }) {
    if (attribute == null || attribute.key != FormatAttribute.style.key) {
      return null;
    }

    if (len != 1 || data != null) {
      debugPrint(
        'FormatRule.applyRule — unexpected args (len=$len, data=$data), expected len=1 and data=null',
      );
      return null;
    }

    final delta = Delta()
      ..retain(index)
      ..retain(1, attributes: attribute.toJson());

    return delta;
  }
}
