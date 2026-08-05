import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/src/common/structs/offset_value.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/nodes/block.dart';
import 'package:flutter_quill/src/document/nodes/container.dart';
import 'package:flutter_quill/src/document/nodes/embeddable.dart';
import 'package:flutter_quill/src/document/nodes/leaf.dart';
import 'package:flutter_quill/src/document/nodes/node.dart';
import 'package:flutter_quill/src/document/style.dart';
import 'package:flutter_quill/src/editor/embed/embed_editor_builder.dart';
import 'package:flutter_quill/src/editor_toolbar_controller_shared/copy_cut_service/copy_cut_service_provider.dart';
import 'package:meta/meta.dart';

/// A line of rich text in a Quill document.
///
/// Line serves as a container for [Leaf]s, like [QuillText] and [Embed].
///
/// When a line contains an embed, it fully occupies the line, no other embeds
/// or text nodes are allowed.
base class Line extends QuillContainer<Leaf?> {
  @override
  Leaf get defaultChild => QuillText();

  @override
  int get length => super.length + 1;

  /// Returns `true` if this line contains an embedded object.
  bool get hasEmbed {
    return children.any((child) => child is Embed);
  }

  /// Returns next [Line] or `null` if this is the last line in the document.
  Line? get nextLine {
    if (!isLast) {
      return next is Block ? (next! as Block).first as Line? : next as Line?;
    }
    if (parent is! Block) {
      return null;
    }

    if (parent!.isLast) {
      return null;
    }
    return parent!.next is Block ? (parent!.next! as Block).first as Line? : parent!.next as Line?;
  }

  @override
  Node newInstance() => Line();

  @override
  Delta toDelta() {
    final delta = children.fold<Delta>(
      Delta(),
      (accumulated, child) => accumulated.concat(child.toDelta()),
    );
    var attributes = style;
    if (parent is Block) {
      final block = parent! as Block;
      attributes = attributes.mergeAll(block.style);
    }

    delta.insert("\n", attributes: attributes.toJson());
    return delta;
  }

  @override
  String toPlainText([
    Iterable<EmbedBuilder>? embedBuilders,
    EmbedBuilder? unknownEmbedBuilder,
  ]) => '${super.toPlainText(embedBuilders, unknownEmbedBuilder)}\n';

  @override
  String toString() {
    final body = children.join(' → ');
    final styleString = style.isNotEmpty ? ' $style' : '';
    return '¶ $body ⏎$styleString';
  }

  @override
  void insert(int index, Object data, Style? style) {
    debugPrint("[LINE-INSERT-IN] index=$index data=$data style=$style");
    var value = index;
    if (data is Embeddable) {
      // We do not check whether this line already has any children here as
      // inserting an embed into a line with other text is acceptable from the
      // Delta format perspective.
      // We rely on heuristic rules to ensure that embeds occupy an entire line.
      _insertSafe(value, data, style);
      return;
    }

    final text = data as String;
    final lineBreak = text.indexOf('\n');
    if (lineBreak < 0) {
      _insertSafe(value, text, style);
      // No need to update line or block format since those attributes can only
      // be attached to `\n` character and we already know it's not present.
      return;
    }

    final prefix = text.substring(0, lineBreak);
    _insertSafe(value, prefix, style);

    if (prefix.isNotEmpty) {
      value += prefix.length;
    }

    // Next line inherits our format.
    final nextLine = _getNextLine(value);

    // Reset our format and unwrap from a block if needed.
    clearStyle();
    if (parent is Block) {
      _unwrap();
    }

    // Now we can apply new format and re-layout.
    _format(style);

    // Continue with remaining part.
    final remain = text.substring(lineBreak + 1);
    nextLine.insert(0, remain, style);
  }

  @override
  void retain(int index, int? len, Style? style) {
    if (style == null) {
      return;
    }
    final length = this.length;

    final local = math.min(length - index, len!);
    // If index is at newline character then this is a line/block style update.
    final isLineFormat = (index + local == length) && local == 1;

    if (isLineFormat) {
      final inlineAttrs = style.values.where(
        (attr) => attr.scope != FormatScope.block && attr.scope != FormatScope.metadata,
      );
      if (inlineAttrs.isNotEmpty) {
        debugPrint(
          'Line.retain — inline attributes applied to line itself, filtering them out: $inlineAttrs',
        );
      }
      _format(style);
    } else {
      // Otherwise forward to children as it's an inline format update.
      final attr = <String, FormatAttribute>{}
        ..addEntries(
          style.attributes.entries.where(
            (a) => a.value.scope != FormatScope.block,
          ),
        );
      if (index + local == length) {
        debugPrint(
          'Line.retain — unexpectedly at line end (index=$index, local=$local, length=$length), skipping inline retain',
        );
        return;
      }
      super.retain(index, local, Style.attr(attr));
    }

    final remain = len - local;
    if (remain > 0) {
      if (nextLine == null) {
        debugPrint(
          'Line.retain — nextLine is null but remain=$remain > 0, skipping propagation',
        );
        return;
      }
      nextLine!.retain(0, remain, style);
    }
  }

  @override
  void delete(int index, int? len) {
    final length = this.length;
    final local = math.min(length - index, len!);
    final isLFDeleted = index + local == length; // Line feed
    if (isLFDeleted) {
      // Our newline character deleted with all style information.
      clearStyle();
      if (local > 1) {
        // Exclude newline character from delete range for children.
        super.delete(index, local - 1);
      }
    } else {
      super.delete(index, local);
    }

    final remaining = len - local;
    if (remaining > 0 && nextLine != null) {
      nextLine?.delete(0, remaining);
    }

    if (isLFDeleted && isNotEmpty) {
      // Since we lost our line-break and still have child text nodes those must
      // migrate to the next line.

      // nextLine might have been unmounted since last assert so we need to
      // check again we still have a line after us.
      if (nextLine != null) {
        // Move remaining children in this line to the next line so that all
        // attributes of nextLine are preserved.
        nextLine?.moveChildToNewParent(this);
        moveChildToNewParent(nextLine);
      }
    }

    if (isLFDeleted) {
      // Now we can remove this line.
      final block = parent!; // remember reference before un-linking.
      unlink();
      block.adjust();
    }
  }

  /// Formats this line.
  void _format(Style? newStyle) {
    if (newStyle == null || newStyle.isEmpty) {
      return;
    }

    applyStyle(newStyle);
    final blockStyle = newStyle.getBlockExceptHeader();
    if (blockStyle == null) {
      return;
    } // No block-level changes

    if (parent is Block) {
      final parentStyle = (parent! as Block).style.getBlocksExceptHeader();
      const map = MapEquality<String, FormatAttribute>();
      final equalStyle = map.equals(
        newStyle.getBlocksExceptHeader(),
        parentStyle,
      );
      // Ensure that we're only unwrapping the block only if we unset a single
      // block format in the `parentStyle` and there are no more block formats
      // left to unset.
      if (blockStyle.value == null && parentStyle.containsKey(blockStyle.key) && parentStyle.length == 1) {
        _unwrap();
      } else if (!equalStyle) {
        _unwrap();
        // Block style now can contain multiple attributes
        if (newStyle.attributes.keys.any(
          FormatAttribute.exclusiveBlockKeys.contains,
        )) {
          parentStyle.removeWhere(
            (key, attr) => FormatAttribute.exclusiveBlockKeys.contains(key),
          );
        }
        parentStyle.removeWhere(
          (key, attr) => newStyle.attributes.keys.contains(key),
        );
        final parentStyleToMerge = Style.attr(parentStyle);
        final result = newStyle.mergeAll(parentStyleToMerge);
        _applyBlockStyles(result);
      } // else the same style, no-op.
    } else if (blockStyle.value != null) {
      // Only wrap with a new block if this is not an unset
      _applyBlockStyles(newStyle);
    }
  }

  void _applyBlockStyles(Style newStyle) {
    var block = Block();
    for (final style in newStyle.getBlocksExceptHeader().values) {
      block = block..applyAttribute(style);
    }
    _wrap(block);
    block.adjust();
  }

  /// Wraps this line with new parent [block].
  ///
  /// This line can not be in a [Block] when this method is called.
  void _wrap(Block block) {
    if (parent == null || parent is Block) {
      debugPrint(
        'Line._wrap — invalid parent state (parent=${parent.runtimeType}), aborting wrap',
      );
      return;
    }
    insertAfter(block);
    unlink();
    block.add(this);
  }

  /// Unwraps this line from it's parent [Block].
  ///
  /// This method asserts if current [parent] of this line is not a [Block].
  void _unwrap() {
    if (parent is! Block) {
      throw ArgumentError('Invalid parent');
    }
    final block = parent! as Block;

    if (!block.children.contains(this)) {
      debugPrint(
        'Line._unwrap — this line is not in block.children, aborting unwrap',
      );
      return;
    }

    if (isFirst) {
      unlink();
      block.insertBefore(this);
    } else if (isLast) {
      unlink();
      block.insertAfter(this);
    } else {
      /// need to split this block into two as [line] is in the middle.
      final before = block.clone() as Block;
      block.insertBefore(before);

      var child = block.first! as Line;
      while (child != this) {
        child.unlink();
        before.add(child);
        child = block.first! as Line;
      }
      unlink();
      block.insertBefore(this);
    }
    block.adjust();
  }

  Line _getNextLine(int index) {
    var safeIndex = index;
    if (safeIndex != 0 && !(safeIndex > 0 && safeIndex < length)) {
      debugPrint(
        'Line._getNextLine — invalid index=$index (length=$length), using 0 as fallback',
      );
      safeIndex = 0;
    }

    final line = clone() as Line;
    insertAfter(line);
    if (safeIndex == length - 1) {
      return line;
    }

    final query = queryChild(safeIndex, false);
    while (!query.node!.isLast) {
      final next = (last as Leaf)..unlink();
      line.addFirst(next);
    }
    final child = query.node! as Leaf;
    final cut = child.splitAt(query.offset);
    cut?.unlink();
    line.addFirst(cut);
    return line;
  }

  void _insertSafe(int index, Object data, Style? style) {
    debugPrint("[LINE-INSAFE-IN] index=$index length=$length data=$data");
    if (index < 0 || index > length) {
      debugPrint("[LINE-INSAFE-GUARD] BLOQUÉ — index=$index hors [0,$length]");
      debugPrint(
        'Line._insertSafe — invalid index=$index (length=$length), aborting insert',
      );
      return;
    }

    // var inlineStyles = style;
    // if (style != null) {
    //   final nonInlineStyles =
    //       style.attributes.values.where((v) => !v.isInline).toSet();
    //   final styleToApply = style.removeAll(nonInlineStyles);
    //   inlineStyles = styleToApply;
    // }

    var safeData = data;
    if (safeData is String) {
      if (safeData.contains('\n')) {
        debugPrint("[LINE-INSAFE-NEWLINE] data contient newline, strip");
        debugPrint(
          'Line._insertSafe — data contains newline, stripping it: $safeData',
        );
        safeData = safeData.replaceAll('\n', '');
        if (safeData.isEmpty) {
          debugPrint("[LINE-INSAFE-EMPTY] data vide après strip newline, return");
          return;
        }
      }
      if (safeData.isEmpty) {
        debugPrint("[LINE-INSAFE-EMPTY] data vide, return");
        return;
      }
    }

    debugPrint("[LINE-INSAFE-OK] insertion effective, isEmpty=$isEmpty data=$safeData");
    if (isEmpty) {
      final child = Leaf(safeData);
      add(child);
      child.format(style);
    } else {
      final result = queryChild(index, true);
      debugPrint("[LINE-INSAFE-DELEG] delegate à child offset=${result.offset} node=${result.node}");
      result.node!.insert(result.offset, safeData, style);
    }
  }

  /// Returns style for specified text range.
  ///
  /// Only attributes applied to all characters within this range are
  /// included in the result. Inline and line level attributes are
  /// handled separately, e.g.:
  ///
  /// - line attribute X is included in the result only if it exists for
  ///   every line within this range (partially included lines are counted).
  /// - inline attribute X is included in the result only if it exists
  ///   for every character within this range (line-break characters excluded).
  ///
  /// In essence, it is INTERSECTION of each individual segment's styles
  Style collectStyle(int offset, int len) {
    final local = math.min(length - offset, len);
    var result = const Style();
    final excluded = <FormatAttribute>{};

    void handle(Style style) {
      for (final attr in result.values) {
        if (!style.containsKey(attr.key) || (style.attributes[attr.key]?.value != attr.value)) {
          excluded.add(attr);
        }
      }
      result = result.removeAll(excluded);
    }

    final data = queryChild(offset, true);
    var node = data.node as Leaf?;
    if (node != null) {
      result = node.style;
      var pos = node.length - data.offset;
      while (!node!.isLast && pos < local) {
        node = node.next! as Leaf;
        handle(node.style);
        pos += node.length;
      }
    }

    /// Blank lines do not have style and must get the active style from prior line
    if (isEmpty) {
      var prevLine = previous;
      while (prevLine is Block && prevLine.isNotEmpty) {
        prevLine = prevLine.children.last;
      }
      if (prevLine is Line) {
        result = result.mergeAll(prevLine.collectStyle(prevLine.length - 1, 1));
      }
    } else {
      result = result.mergeAll(style);
    }
    if (parent is Block) {
      final block = parent! as Block;
      result = result.mergeAll(block.style);
    }

    var remaining = len - local;
    var nxt = nextLine;

    /// Skip over empty lines that have no attributes
    while (remaining > 0 && nxt != null && nxt.isEmpty) {
      remaining--;
      nxt = nxt.nextLine;
    }
    if (remaining > 0 && nxt != null) {
      final rest = nxt.collectStyle(0, remaining);
      handle(rest);
    }

    return result;
  }

  /// Returns each node segment's offset in selection
  /// with its corresponding style or embed as a list of [StyledNodeEntry].
  List<StyledNodeEntry> collectAllIndividualStylesAndEmbed(
    int offset,
    int len, {
    int beg = 0,
  }) {
    final local = math.min(length - offset, len);
    final result = <StyledNodeEntry>[];

    final data = queryChild(offset, true);
    var node = data.node as Leaf?;
    if (node != null) {
      var pos = math.min(local, node.length - data.offset);
      if (node is QuillText && node.style.isNotEmpty) {
        result.add(StyleEntry(beg, node.style, pos));
      } else if (node.value is Embeddable) {
        result.add(EmbedEntry(beg, node.value as Embeddable, pos));
      }

      while (!node!.isLast && pos < local) {
        node = node.next! as Leaf;
        final span = math.min(local - pos, node.length);
        if (node is QuillText && node.style.isNotEmpty) {
          result.add(StyleEntry(pos + beg, node.style, span));
        } else if (node.value is Embeddable) {
          result.add(EmbedEntry(pos + beg, node.value as Embeddable, span));
        }
        pos += node.length;
      }

      if (style.isNotEmpty) {
        result.add(StyleEntry(beg, style, pos));
      }
    }

    final remaining = len - local;
    if (remaining > 0 && nextLine != null) {
      final rest = nextLine!.collectAllIndividualStylesAndEmbed(
        0,
        remaining,
        beg: local + beg,
      );
      result.addAll(rest);
    }

    return result;
  }

  /// Returns all styles for any character within the specified text range.
  /// In essence, it is UNION of each individual segment's styles
  List<Style> collectAllStyles(int offset, int len) {
    final local = math.min(length - offset, len);
    final result = <Style>[];

    final data = queryChild(offset, true);
    var node = data.node as Leaf?;
    if (node != null) {
      result.add(node.style);
      var pos = node.length - data.offset;
      while (!node!.isLast && pos < local) {
        node = node.next! as Leaf;
        result.add(node.style);
        pos += node.length;
      }
    }

    result.add(style);
    if (parent is Block) {
      final block = parent! as Block;
      result.add(block.style);
    }

    final remaining = len - local;
    if (remaining > 0 && nextLine != null) {
      final rest = nextLine!.collectAllStyles(0, remaining);
      result.addAll(rest);
    }

    return result;
  }

  /// Returns all styles for any character within the specified text range.
  List<OffsetStyleValue<Style>> collectAllStylesWithOffsets(
    int offset,
    int len, {
    int beg = 0,
  }) {
    final local = math.min(length - offset, len);
    final result = <OffsetStyleValue<Style>>[];

    final data = queryChild(offset, true);
    var node = data.node as Leaf?;
    if (node != null) {
      var pos = 0;
      pos = node.length - data.offset;
      result.add(
        OffsetStyleValue(node.documentOffset, node.style, node.length),
      );
      while (!node!.isLast && pos < local) {
        node = node.next! as Leaf;
        result.add(
          OffsetStyleValue(node.documentOffset, node.style, node.length),
        );
        pos += node.length;
      }
    }

    result.add(OffsetStyleValue(documentOffset, style, length));
    if (parent is Block) {
      final block = parent! as Block;
      result.add(
        OffsetStyleValue(block.documentOffset, block.style, block.length),
      );
    }

    final remaining = len - local;
    if (remaining > 0 && nextLine != null) {
      final rest = nextLine!.collectAllStylesWithOffsets(
        0,
        remaining,
        beg: local,
      );
      result.addAll(rest);
    }

    return result;
  }

  /// Returns plain text within the specified text range.
  String getPlainText(
    int offset,
    int len, {
    @internal Iterable<EmbedBuilder>? embedBuilders,
    @internal EmbedBuilder? unknownEmbedBuilder,
  }) {
    final plainText = StringBuffer();
    _getPlainText(
      offset,
      len,
      plainText,
      embedBuilders: embedBuilders,
      unknownEmbedBuilder: unknownEmbedBuilder,
    );
    return plainText.toString();
  }

  int _getNodeText(
    Leaf node,
    StringBuffer buffer,
    int offset,
    int remaining, {
    Iterable<EmbedBuilder>? embedBuilders,
    EmbedBuilder? unknownEmbedBuilder,
  }) {
    final text = node.toPlainText(embedBuilders, unknownEmbedBuilder);
    if (text == Embed.kObjectReplacementCharacter) {
      final embed = node.value as Embeddable;

      final service = CopyCutServiceProvider();
      final provider = service.instance;
      // By default getCopyCutAction just return the same operation
      // returning Embed.kObjectReplacementCharacter for the buffer
      final action = provider.getCopyCutAction(embed.type);
      final data = action.call(embed.data);
      // This conditional avoid an issue where the plain data copied
      // to the clipboard, when it is pasted on the editor
      // the content has a unexpected behaviors
      if (data != Embed.kObjectReplacementCharacter) {
        buffer.write(data);
        return remaining;
      } else {
        buffer.write(action.call(data));
      }
      return remaining - node.length;
    }

    /// Text for clipboard will expand the content of Embed nodes
    if (node is Embed) {
      buffer.write(text);
      return remaining - 1;
    }

    final end = math.min(offset + remaining, text.length);
    buffer.write(text.substring(offset, end));
    return remaining - (end - offset);
  }

  int _getPlainText(
    int offset,
    int len,
    StringBuffer plainText, {
    Iterable<EmbedBuilder>? embedBuilders,
    EmbedBuilder? unknownEmbedBuilder,
  }) {
    var len0 = len;
    final data = queryChild(offset, false);
    var node = data.node as Leaf?;

    while (len0 > 0) {
      if (node == null) {
        // blank line
        plainText.write('\n');
        len0 -= 1;
      } else {
        len0 = _getNodeText(
          node,
          plainText,
          offset - node.offset,
          len0,
          embedBuilders: embedBuilders,
          unknownEmbedBuilder: unknownEmbedBuilder,
        );

        while (!node!.isLast && len0 > 0) {
          node = node.next! as Leaf;
          len0 = _getNodeText(
            node,
            plainText,
            0,
            len0,
            embedBuilders: embedBuilders,
            unknownEmbedBuilder: unknownEmbedBuilder,
          );
        }

        if (len0 > 0) {
          // end of this line
          plainText.write('\n');
          len0 -= 1;
        }
      }

      if (len0 > 0 && nextLine != null) {
        len0 = nextLine!._getPlainText(
          0,
          len0,
          plainText,
          embedBuilders: embedBuilders,
          unknownEmbedBuilder: unknownEmbedBuilder,
        );
      }
    }

    return len0;
  }
}
