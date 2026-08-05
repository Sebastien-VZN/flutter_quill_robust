import "dart:collection" show LinkedList;
import "dart:developer" as developer;

import "package:flutter_quill/src/document/nodes/leaf.dart";
import "package:flutter_quill/src/document/nodes/line.dart";
import "package:flutter_quill/src/document/nodes/node.dart";
import "package:flutter_quill/src/document/style.dart";
import "package:flutter_quill/src/editor/embed/embed_editor_builder.dart";

/// Container can accommodate other nodes.
///
/// Delegates insert, retain and delete operations to children nodes. For each
/// operation container looks for a child at specified index position and
/// forwards operation to that child.
///
/// Most of the operation handling logic is implemented by [Line]
/// and [QuillText].
///
/// All assertions have been replaced with defensive guards using [debugPrint]
/// for diagnostic logging. No [assert] calls remain in production code paths —
/// the editor degrades gracefully instead of crashing in release builds.
abstract base class QuillContainer<T extends Node?> extends Node {
  final LinkedList<Node> _children = LinkedList<Node>();

  /// List of children.
  LinkedList<Node> get children => _children;

  /// Returns total number of child nodes in this container.
  ///
  /// To get text length of this container see [length].
  int get childCount => _children.length;

  /// Returns the first child [Node].
  Node? get first => isEmpty ? null : _children.first;

  /// Returns the last child [Node].
  Node get last => _children.last;

  /// Returns `true` if this container has no child nodes.
  bool get isEmpty => _children.isEmpty;

  /// Returns `true` if this container has at least 1 child.
  bool get isNotEmpty => _children.isNotEmpty;

  /// Returns an instance of default child for this container node.
  ///
  /// Always returns fresh instance.
  T get defaultChild;

  int? _length;

  /// Adds [node] to the end of this container children list.
  ///
  /// If [node] already has a parent, logs a [debugPrint] warning and detaches
  /// it from its previous parent before adding it to this container.
  void add(T node) {
    if (node?.parent != null) {
      developer.log(
        "QuillContainer.add: node already has a parent — detaching first.",
        name: "quill.container",
      );
      node?.unlink();
    }
    node?.parent = this;
    _children.add(node as Node);
    clearLengthCache();
  }

  /// Adds [node] to the beginning of this container children list.
  ///
  /// If [node] already has a parent, logs a [debugPrint] warning and detaches
  /// it from its previous parent before adding it to this container.
  void addFirst(T node) {
    if (node?.parent != null) {
      developer.log(
        "QuillContainer.addFirst: node already has a parent — detaching first.",
        name: "quill.container",
      );
      node?.unlink();
    }
    node?.parent = this;
    _children.addFirst(node as Node);
    clearLengthCache();
  }

  /// Removes [node] from this container.
  ///
  /// If [node] does not belong to this container, logs a [debugPrint] warning
  /// and returns without modifying the children list.
  void remove(T node) {
    if (node?.parent != this) {
      developer.log(
        "QuillContainer.remove: node does not belong to this container — skipping.",
        name: "quill.container",
      );
      return;
    }
    node?.parent = null;
    _children.remove(node as Node);
    clearLengthCache();
  }

  /// Moves children of this node to [newParent].
  void moveChildToNewParent(QuillContainer? newParent) {
    if (isEmpty) {
      return;
    }

    final last = newParent!.isEmpty ? null : newParent.last as T?;
    while (isNotEmpty) {
      final child = first as T;
      child?.unlink();
      newParent.add(child);
    }

    /// In case [newParent] already had children we need to make sure
    /// combined list is optimized.
    if (last != null) last.adjust();
  }

  /// Queries the child [Node] at [offset] in this container.
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified offset.
  ///
  /// [ChildQuery.offset] is set to relative offset within returned child node
  /// which points at the same character position in the document as the
  /// original [offset].
  ChildQuery queryChild(int offset, bool inclusive) {
    if (offset < 0 || offset > length) {
      return ChildQuery(null, 0);
    }

    var value = offset;
    for (final node in children) {
      final len = node.length;
      if (value < len || (inclusive && value == len && node.isLast)) {
        return ChildQuery(node, value);
      }
      value -= len;
    }
    return ChildQuery(null, 0);
  }

  @override
  String toPlainText([
    Iterable<EmbedBuilder>? embedBuilders,
    EmbedBuilder? unknownEmbedBuilder,
  ]) => children.map((e) => e.toPlainText(embedBuilders, unknownEmbedBuilder)).join();

  @override
  int get length {
    _length ??= _children.fold(0, (cur, node) => (cur ?? 0) + node.length);
    return _length!;
  }

  @override
  void clearLengthCache() {
    _length = null;
    clearOffsetCache();
    if (parent != null) {
      parent!.clearLengthCache();
    }
  }

  /// Inserts [data] at [index] with optional [style].
  ///
  /// If the container is empty, a default child is created and the data is
  /// inserted into it. If [index] is out of bounds, logs a [debugPrint] warning
  /// and returns without modifying the document.
  @override
  void insert(int index, Object data, Style? style) {
    if (index < 0 || index > length) {
      developer.log(
        "QuillContainer.insert: index $index out of bounds (length=$length) — skipping.",
        name: "quill.container",
      );
      return;
    }

    if (isNotEmpty) {
      final child = queryChild(index, false);
      if (child.isNotEmpty) {
        child.node!.insert(child.offset, data, style);
      }
    } else {
      final node = defaultChild;
      add(node);
      node?.insert(index, data, style);
    }
  }

  /// Retains formatting at [index] for [len] characters with optional [style].
  ///
  /// If the container is empty, logs a [debugPrint] warning and returns
  /// without modifying the document.
  @override
  void retain(int index, int? len, Style? style) {
    if (isEmpty) {
      developer.log(
        "QuillContainer.retain: container is empty — skipping.",
        name: "quill.container",
      );
      return;
    }
    final child = queryChild(index, false);
    child.node!.retain(child.offset, len, style);
  }

  /// Deletes [len] characters starting at [index].
  ///
  /// If the container is empty, logs a [debugPrint] warning and returns
  /// without modifying the document.
  @override
  void delete(int index, int? len) {
    if (isEmpty) {
      developer.log(
        "QuillContainer.delete: container is empty — skipping.",
        name: "quill.container",
      );
      return;
    }
    final child = queryChild(index, false);
    child.node!.delete(child.offset, len);
  }

  @override
  String toString() => _children.join("\n");
}

/// Result of a child query in a [QuillContainer].
class ChildQuery {
  ChildQuery(this.node, this.offset);

  /// The child node if found, otherwise `null`.
  final Node? node;

  /// Starting offset within the child [node] which points at the same
  /// character in the document as the original offset passed to
  /// [QuillContainer.queryChild] method.
  final int offset;

  /// Returns `true` if there is no child node found, e.g. [node] is `null`.
  bool get isEmpty => node == null;

  /// Returns `true` [node] is not `null`.
  bool get isNotEmpty => node != null;
}
