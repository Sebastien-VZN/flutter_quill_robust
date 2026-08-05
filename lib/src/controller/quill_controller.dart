import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/src/common/structs/offset_value.dart';
import 'package:flutter_quill/src/controller/clipboard/quill_controller_paste.dart';
import 'package:flutter_quill/src/controller/clipboard/quill_controller_rich_paste.dart';
import 'package:flutter_quill/src/controller/quill_controller_config.dart';
import 'package:flutter_quill/src/delta/delta_diff.dart';
import 'package:flutter_quill/src/document/document.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/nodes/leaf.dart';
import 'package:flutter_quill/src/document/structs/doc_change.dart';
import 'package:flutter_quill/src/document/style.dart';
import 'package:flutter_quill/src/editor/config/editor_config.dart';
import 'package:flutter_quill/src/editor/raw_editor/raw_editor_state.dart';
import 'package:meta/meta.dart';

typedef ReplaceTextCallback = bool Function(int index, int len, Object? data);
typedef DeleteCallback = void Function(int cursorPosition, bool forward);

class QuillController extends ChangeNotifier {
  QuillController({
    required this._document,
    required this._selection,
    this.config = const QuillControllerConfig(),
    this.keepStyleOnNewLine = true,
    this.onReplaceText,
    this.onDelete,
    this.onSelectionCompleted,
    this.onSelectionChanged,
    this.readOnly = false,
  });

  factory QuillController.basic({
    QuillControllerConfig config = const QuillControllerConfig(),
  }) => QuillController(
    config: config,
    document: Document(),
    selection: const TextSelection.collapsed(offset: 0),
  );

  final QuillControllerConfig config;

  /// Document managed by this controller.
  Document _document;

  Document get document => _document;

  // Store editor config to pass them to the document to
  // support search within embed objects https://github.com/singerdmx/flutter-quill/pull/2090.
  // For internal use only, should not be exposed as a public API.
  QuillEditorConfig? _editorConfig;

  @visibleForTesting
  @internal
  QuillEditorConfig? get editorConfig => _editorConfig;
  @internal
  set editorConfig(QuillEditorConfig? value) {
    _editorConfig = value;
    _setDocumentSearchProperties();
  }

  // Pass required editor config to the document
  // to support search within embed objects https://github.com/singerdmx/flutter-quill/pull/2090
  void _setDocumentSearchProperties() {
    _document
      ..searchConfig = _editorConfig?.searchConfig
      ..embedBuilders = _editorConfig?.embedBuilders
      ..unknownEmbedBuilder = _editorConfig?.unknownEmbedBuilder;
  }

  set document(Document doc) {
    _document = doc;
    _setDocumentSearchProperties();

    // Prevent the selection from
    _selection = const TextSelection(baseOffset: 0, extentOffset: 0);

    notifyListeners();
  }

  /// Tells whether to keep or reset the [toggledStyle]
  /// when user adds a new line.
  final bool keepStyleOnNewLine;

  /// Currently selected text within the [document].
  TextSelection get selection => _selection;
  TextSelection _selection;

  /// Custom [replaceText] handler
  /// Return false to ignore the event
  ReplaceTextCallback? onReplaceText;

  /// Custom delete handler
  DeleteCallback? onDelete;

  void Function()? onSelectionCompleted;
  void Function(TextSelection textSelection)? onSelectionChanged;

  /// Store any styles attribute that got toggled by the tap of a button
  /// and that has not been applied yet.
  /// It gets reset after each format action within the [document].
  Style toggledStyle = const Style();

  /// [raw_editor_actions] handling of backspace event may need to force the style displayed in the toolbar
  void forceToggledStyle(Style style) {
    toggledStyle = style;
    notifyListeners();
  }

  bool ignoreFocusOnTextChange = false;

  /// Skip the keyboard request in [QuillRawEditorState.requestKeyboard].
  ///
  /// See also: [QuillRawEditorState._didChangeTextEditingValue]
  bool skipRequestKeyboard = false;

  /// True when this [QuillController] instance has been disposed.
  ///
  /// A safety mechanism to ensure that listeners don't crash when adding,
  /// removing or listeners to this instance.
  bool _isDisposed = false;
  Stream<DocChange> get changes => document.changes;
  TextEditingValue get plainTextEditingValue => TextEditingValue(text: document.toPlainText(), selection: selection);

  /// Only attributes applied to all characters within this range are
  /// included in the result.
  Style getSelectionStyle() {
    return document.collectStyle(selection.start, selection.end - selection.start).mergeAll(toggledStyle);
  }

  // Increases or decreases the indent of the current selection by 1.
  void indentSelection(bool isIncrease) {
    if (selection.isCollapsed) {
      _indentSelectionFormat(isIncrease);
    } else {
      _indentSelectionEachLine(isIncrease);
    }
  }

  void _indentSelectionFormat(bool isIncrease) {
    final indent = getSelectionStyle().attributes[FormatAttribute.indent.key];

    if (indent == null) {
      if (isIncrease) {
        formatSelection(FormatAttribute.indentL1);
      }
      return;
    }

    final level = indent.intValue; // int? — caste via valueType, null si type inattendu
    if (level == null) return;
    if (indent.value == 1 && !isIncrease) {
      formatSelection(FormatAttribute.clone(FormatAttribute.indentL1, null));
      return;
    }

    if (indent.intValue == null) return;
    if (isIncrease) {
      if (indent.intValue! < 5) {
        formatSelection(FormatAttribute.getIndentLevel(indent.intValue! + 1));
      }
      return;
    }
    formatSelection(FormatAttribute.getIndentLevel(indent.intValue! - 1));
  }

  void _indentSelectionEachLine(bool isIncrease) {
    final styles = document.collectAllStylesWithOffset(
      selection.start,
      selection.end - selection.start,
    );
    for (final style in styles) {
      final indent = style.value.attributes[FormatAttribute.indent.key];
      final formatIndex = math.max(style.offset, selection.start);
      final formatLength = math.min(style.offset + (style.length ?? 0), selection.end) - style.offset;
      FormatAttribute? formatAttribute;
      if (indent == null) {
        if (isIncrease) {
          formatAttribute = FormatAttribute.indentL1;
        }
      } else if (indent.value == 1 && !isIncrease) {
        formatAttribute = FormatAttribute.clone(FormatAttribute.indentL1, null);
      } else if (isIncrease) {
        if (indent.intValue == null) continue;
        if (indent.intValue! < 5) {
          formatAttribute = FormatAttribute.getIndentLevel(
            indent.intValue! + 1,
          );
        }
      } else {
        if (indent.intValue == null) continue;
        formatAttribute = FormatAttribute.getIndentLevel(indent.intValue! - 1);
      }
      if (formatAttribute != null) {
        document.format(formatIndex, formatLength, formatAttribute);
      }
    }
    notifyListeners();
  }

  /// Returns all styles and Embed for each node within selection
  List<StyledNodeEntry> getAllIndividualSelectionStylesAndEmbed() {
    final stylesAndEmbed = document.collectAllIndividualStyleAndEmbed(
      selection.start,
      selection.end - selection.start,
    );
    return stylesAndEmbed;
  }

  /// Returns plain text for each node within selection
  String getPlainText() {
    final text = document.getPlainText(
      selection.start,
      selection.end - selection.start,
    );
    return text;
  }

  /// Returns all styles for any character within the specified text range.
  List<Style> getAllSelectionStyles() {
    final styles = document.collectAllStyles(
      selection.start,
      selection.end - selection.start,
    )..add(toggledStyle);
    return styles;
  }

  void undo() {
    final result = document.undo();
    if (result.changed) {
      _handleHistoryChange(result.len);
    }
  }

  void _handleHistoryChange(int len) {
    updateSelection(TextSelection.collapsed(offset: len), ChangeSource.local);
  }

  void redo() {
    final result = document.redo();
    if (result.changed) {
      _handleHistoryChange(result.len);
    }
  }

  bool get hasUndo => document.hasUndo;

  bool get hasRedo => document.hasRedo;

  /// clear editor
  void clear() {
    replaceText(
      0,
      plainTextEditingValue.text.length - 1,
      '',
      const TextSelection.collapsed(offset: 0),
    );
  }

  void replaceText(
    int index,
    int len,
    Object? data,
    TextSelection? textSelection, {
    bool ignoreFocus = false,
    bool shouldNotifyListeners = true,
  }) {
    print("[CTRL-IN] replaceText(index=$index, len=$len, data=$data, sel=$textSelection, ignoreFocus=$ignoreFocus, notify=$shouldNotifyListeners)");
    if (onReplaceText != null && !onReplaceText!(index, len, data)) {
      print("[CTRL-IN] onReplaceText a bloqué");
      return;
    }

    Delta? delta;
    Style? style;
    if (len > 0 || data is! String || data.isNotEmpty) {
      delta = document.replace(index, len, data);
      print("[CTRL-DOC] document.replace retourné: delta=${delta == null ? 'NULL' : 'ops=${delta.length} isEmpty=${delta.isEmpty}'}");

      /// Remove block styles as they can only be attached to line endings
      style = Style.attr(
        Map<String, FormatAttribute>.fromEntries(
          toggledStyle.attributes.entries.where(
            (a) => a.value.scope != FormatScope.block,
          ),
        ),
      );
      var shouldRetainDelta = style.isNotEmpty && delta != null && delta.isNotEmpty && delta.length <= 2 && delta.last.isInsert;
      if (shouldRetainDelta && style.isNotEmpty && delta.length == 2 && delta.last.data == '\n') {
        // if all attributes are inline, shouldRetainDelta should be false
        final anyAttributeNotInline = style.values.any(
          (attr) => !attr.isInline,
        );
        if (!anyAttributeNotInline) {
          shouldRetainDelta = false;
        }
      }
      if (shouldRetainDelta) {
        final retainDelta = Delta()
          ..retain(index)
          ..retain(data is String ? data.length : 1, style.toJson());
        document.compose(retainDelta, ChangeSource.local);
      }
    }

    if (textSelection != null) {
      if (delta == null || delta.isEmpty) {
        _updateSelection(textSelection);
      } else {
        final user = Delta()
          ..retain(index)
          ..insert(data)
          ..delete(len);
        final positionDelta = getPositionDelta(user, delta);
        _updateSelection(
          textSelection.copyWith(
            baseOffset: textSelection.baseOffset + positionDelta,
            extentOffset: textSelection.extentOffset + positionDelta,
          ),
          insertNewline: data == '\n',
        );
      }
    }

    if (ignoreFocus) {
      ignoreFocusOnTextChange = true;
    }
    if (shouldNotifyListeners) {
      notifyListeners();
    }
    ignoreFocusOnTextChange = false;
  }

  /// Called in two cases:
  /// forward == false && textBefore.isEmpty
  /// forward == true && textAfter.isEmpty
  /// Android only
  /// see https://github.com/singerdmx/flutter-quill/discussions/514
  void handleDelete(int cursorPosition, bool forward) => onDelete?.call(cursorPosition, forward);

  void formatTextStyle(int index, int len, Style style) {
    style.attributes.forEach((key, attr) {
      formatText(index, len, attr);
    });
  }

  void formatText(
    int index,
    int len,
    FormatAttribute? attribute, {
    bool shouldNotifyListeners = true,
  }) {
    if (len == 0 && attribute!.key != FormatAttribute.link.key) {
      // Add the attribute to our toggledStyle.
      // It will be used later upon insertion.
      toggledStyle = toggledStyle.put(attribute);
    }

    final change = document.format(index, len, attribute);
    // Transform selection against the composed change and give priority to
    // the change. This is needed in cases when format operation actually
    // inserts data into the document (e.g. embeds).
    final adjustedSelection = selection.copyWith(
      baseOffset: change.transformPosition(selection.baseOffset),
      extentOffset: change.transformPosition(selection.extentOffset),
    );
    if (selection != adjustedSelection) {
      _updateSelection(adjustedSelection);
    }
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  void formatSelection(
    FormatAttribute? attribute, {
    bool shouldNotifyListeners = true,
  }) {
    formatText(
      selection.start,
      selection.end - selection.start,
      attribute,
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  void moveCursorToStart() {
    updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
  }

  void moveCursorToPosition(int position) {
    updateSelection(
      TextSelection.collapsed(offset: position),
      ChangeSource.local,
    );
  }

  void moveCursorToEnd() {
    updateSelection(
      TextSelection.collapsed(offset: plainTextEditingValue.text.length),
      ChangeSource.local,
    );
  }

  void updateSelection(TextSelection textSelection, ChangeSource source) {
    _updateSelection(textSelection);
    notifyListeners();
  }

  void compose({
    required Delta delta,
    required TextSelection textSelection,
    required ChangeSource source,
  }) {
    if (delta.isNotEmpty) {
      document.compose(delta, source);
    }

    final copy = selection.copyWith(
      baseOffset: delta.transformPosition(selection.baseOffset, force: false),
      extentOffset: delta.transformPosition(
        selection.extentOffset,
        force: false,
      ),
    );
    if (selection != copy) {
      _updateSelection(textSelection);
    }

    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    // By using `_isDisposed`, make sure that `addListener` won't be called on a
    // disposed `ChangeListener`
    if (!_isDisposed) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    // By using `_isDisposed`, make sure that `removeListener` won't be called
    // on a disposed `ChangeListener`
    if (!_isDisposed) {
      super.removeListener(listener);
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      unawaited(document.close());
    }

    _isDisposed = true;
    super.dispose();
  }

  void _updateSelection(
    TextSelection textSelection, {
    bool insertNewline = false,
  }) {
    _selection = textSelection;
    final end = document.length - 1;
    _selection = selection.copyWith(
      baseOffset: math.min(selection.baseOffset, end),
      extentOffset: math.min(selection.extentOffset, end),
    );
    if (keepStyleOnNewLine) {
      if (insertNewline && selection.start > 0) {
        final style = document.collectStyle(selection.start - 1, 0);
        final ignoredStyles = style.attributes.values.where(
          (s) => !s.isInline || s.key == FormatAttribute.link.key,
        );
        toggledStyle = style.removeAll(ignoredStyles.toSet());
      } else {
        toggledStyle = const Style();
      }
    } else {
      toggledStyle = const Style();
    }
    onSelectionChanged?.call(textSelection);
  }

  /// Given offset, find its leaf node in document
  Leaf? queryNode(int offset) {
    return document.querySegmentLeafNode(offset).leaf;
  }

  // Notify toolbar buttons directly with attributes
  Map<String, FormatAttribute> toolbarButtonToggler = const {};

  /// Clipboard caches last copy to allow paste with styles. Static to allow paste between multiple instances of editor.
  static String _pastePlainText = '';
  static Delta _pasteDelta = Delta();
  static List<StyledNodeEntry> _pasteStyleAndEmbed = <StyledNodeEntry>[];

  String get pastePlainText => _pastePlainText;
  Delta get pasteDelta => _pasteDelta;
  List<StyledNodeEntry> get pasteStyleAndEmbed => _pasteStyleAndEmbed;

  /// Whether the text can be changed.
  ///
  /// When this is set to `true`, the text cannot be modified
  /// by any shortcut or keyboard operation. The text is still selectable.
  ///
  /// Defaults to `false`.
  bool readOnly;

  Future<bool> clipboardSelection(bool copy) async {
    await Clipboard.setData(const ClipboardData(text: ''));

    /// Get the text for the selected region and expand the content of Embedded objects.
    _pastePlainText = document.getPlainText(
      selection.start,
      selection.end - selection.start,
      includeEmbeds: true,
    );

    /// Get the internal representation so it can be pasted into a QuillEditor with style retained.
    _pasteStyleAndEmbed = getAllIndividualSelectionStylesAndEmbed();

    /// Get the deltas for the selection so they can be pasted into a QuillEditor with styles and embeds retained.
    _pasteDelta = document.toDelta().slice(selection.start, selection.end);

    if (!selection.isCollapsed) {
      await Clipboard.setData(ClipboardData(text: _pastePlainText));
      if (!copy) {
        if (readOnly) return false;
        final sel = selection;
        replaceText(
          sel.start,
          sel.end - sel.start,
          '',
          TextSelection.collapsed(offset: sel.start),
        );
      }
      return true;
    }
    return false;
  }

  /// Returns whether paste operation was handled here.
  /// [updateEditor] is called if paste operation was successful.

  Future<bool> clipboardPaste({void Function()? updateEditor}) async {
    if (readOnly || !selection.isValid) return true;

    final clipboardConfig = config.clipboardConfig;

    if (await clipboardConfig?.onClipboardPaste?.call() == true) {
      updateEditor?.call();
      return true;
    }

    const enableExternalRichPasteDefault = true;
    if (clipboardConfig?.enableExternalRichPaste ?? enableExternalRichPasteDefault) {
      final pasteMarkdownSuccess = await pasteMarkdown();
      if (pasteMarkdownSuccess) {
        updateEditor?.call();
        return true;
      }
    }

    // Only process plain text if no rich text was pasted.
    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final plainText = (await Clipboard.getData(Clipboard.kTextPlain))?.text;

    if (plainText != null) {
      final plainTextToPaste = await getTextToPaste(plainText);
      if (pastePlainTextOrDelta(
        plainTextToPaste,
        pastePlainText: _pastePlainText,
        pasteDelta: _pasteDelta,
      )) {
        updateEditor?.call();
        return true;
      }
    }

    final onUnprocessedPaste = clipboardConfig?.onUnprocessedPaste;
    if (onUnprocessedPaste != null) {
      if (await onUnprocessedPaste()) {
        updateEditor?.call();
        return true;
      }
    }

    return false;
  }

  void replaceTextWithEmbeds(
    int index,
    int len,
    String insertedText,
    TextSelection? textSelection, {
    bool ignoreFocus = false,
    bool shouldNotifyListeners = true,
  }) {
    final containsEmbed = insertedText.codeUnits.contains(
      Embed.kObjectReplacementInt,
    );
    final result = containsEmbed ? _adjustInsertedText(insertedText) : insertedText;
    replaceText(
      index,
      len,
      result,
      textSelection,
      ignoreFocus: ignoreFocus,
      shouldNotifyListeners: shouldNotifyListeners,
    );
    _applyPasteStyleAndEmbed(result, index, containsEmbed);
  }

  void _applyPasteStyleAndEmbed(
    String insertedText,
    int start,
    bool containsEmbed,
  ) {
    if (insertedText == pastePlainText && pastePlainText != '' || containsEmbed) {
      final pos = start;
      for (final p in pasteStyleAndEmbed) {
        final offset = p.offset;
        final local = pos + offset;
        switch (p) {
          case EmbedEntry(:final embed):
            replaceText(local, 0, embed, null);
          case StyleEntry(:final style):
            if (style.isInline) {
              formatTextStyle(local, p.length!, style);
            } else if (style.isBlock) {
              final node = document.queryChild(local).node;
              if (node != null && p.length == node.length - 1) {
                for (final attribute in style.values) {
                  document.format(local, 0, attribute);
                }
              }
            }
        }
      }
    }
  }

  String _adjustInsertedText(String text) {
    final sb = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == Embed.kObjectReplacementInt) {
        continue;
      }
      sb.write(text[i]);
    }
    return sb.toString();
  }
}
