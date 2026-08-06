import 'dart:async' show StreamSubscription, unawaited;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:math' as math;
import 'dart:ui' as ui hide TextStyle;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart' show KeyboardVisibilityController;
import 'package:flutter_quill/src/common/structs/horizontal_spacing.dart';
import 'package:flutter_quill/src/common/structs/offset_value.dart';
import 'package:flutter_quill/src/common/structs/vertical_spacing.dart';
import 'package:flutter_quill/src/common/utils/platform.dart';
import 'package:flutter_quill/src/common/utils/quill_debug_logs.dart';
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/delta/delta_diff.dart';
import 'package:flutter_quill/src/document/document.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/nodes/block.dart';
import 'package:flutter_quill/src/document/nodes/line.dart';
import 'package:flutter_quill/src/document/nodes/node.dart';
import 'package:flutter_quill/src/editor/editor.dart';
import 'package:flutter_quill/src/editor/raw_editor/keyboard_shortcuts/editor_keyboard_shortcut_actions_manager.dart';
import 'package:flutter_quill/src/editor/raw_editor/keyboard_shortcuts/editor_keyboard_shortcuts.dart';
import 'package:flutter_quill/src/editor/raw_editor/raw_editor.dart';
import 'package:flutter_quill/src/editor/raw_editor/raw_editor_render_object.dart';
import 'package:flutter_quill/src/editor/raw_editor/raw_editor_state_selection_delegate_mixin.dart';
import 'package:flutter_quill/src/editor/raw_editor/raw_editor_state_text_input_client_mixin.dart';
import 'package:flutter_quill/src/editor/raw_editor/scribble_focusable.dart';
import 'package:flutter_quill/src/editor/widgets/cursor.dart';
import 'package:flutter_quill/src/editor/widgets/default_styles.dart';
import 'package:flutter_quill/src/editor/widgets/link.dart';
import 'package:flutter_quill/src/editor/widgets/proxy.dart';
import 'package:flutter_quill/src/editor/widgets/text/text_block.dart';
import 'package:flutter_quill/src/editor/widgets/text/text_line.dart';
import 'package:flutter_quill/src/editor/widgets/text/text_selection.dart';

class QuillRawEditorState extends EditorState
    with
        AutomaticKeepAliveClientMixin<QuillRawEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<QuillRawEditor>,
        RawEditorStateTextInputClientMixin,
        RawEditorStateSelectionDelegateMixin {
  late final EditorKeyboardShortcutsActionsManager _shortcutActionsManager;

  final GlobalKey _editorKey = GlobalKey();

  KeyboardVisibilityController? _keyboardVisibilityController;
  StreamSubscription<bool>? _keyboardVisibilitySubscription;
  bool _keyboardVisible = false;

  // Selection overlay
  @override
  EditorTextSelectionOverlay? get selectionOverlay => _selectionOverlay;
  EditorTextSelectionOverlay? _selectionOverlay;

  @override
  ScrollController get scrollController => _scrollController;
  late ScrollController _scrollController;

  // Cursors
  late CursorCont _cursorCont;

  QuillController get controller => widget.controller;

  // Focus
  bool _didAutoFocus = false;

  bool get _hasFocus => widget.config.focusNode.hasFocus;

  // Theme
  DefaultStyles? _styles;

  // for pasting style
  @override
  List<StyledNodeEntry> get pasteStyleAndEmbed => controller.pasteStyleAndEmbed;

  @override
  String get pastePlainText => controller.pastePlainText;

  ClipboardStatusNotifier? _clipboardStatus;
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  TextDirection get _textDirection => Directionality.of(context);

  @override
  bool get dirty => _dirty;
  bool _dirty = false;

  @override
  void insertContent(KeyboardInsertedContent content) {
    final isAllowed =
        widget.config.contentInsertionConfiguration?.allowedMimeTypes.contains(
          content.mimeType,
        ) ??
        false;
    if (!isAllowed) {
      quillDebugPrint(
        'RawEditorState.insertContent — mimeType ${content.mimeType} not allowed, skipping',
      );
      return;
    }
    widget.config.contentInsertionConfiguration?.onContentInserted.call(
      content,
    );
  }

  /// Copy current selection to [Clipboard].
  @override
  void copySelection(SelectionChangedCause cause) {
    unawaited(controller.clipboardSelection(true));

    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar();

      // Collapse the selection and hide the toolbar and handles.
      userUpdateTextEditingValue(
        TextEditingValue(
          text: textEditingValue.text,
          selection: TextSelection.collapsed(
            offset: textEditingValue.selection.end,
          ),
        ),
        SelectionChangedCause.toolbar,
      );
    }
  }

  /// Cut current selection to [Clipboard].
  @override
  void cutSelection(SelectionChangedCause cause) {
    unawaited(controller.clipboardSelection(false));

    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar();
    }
  }

  /// Paste text from [Clipboard].
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (controller.readOnly) {
      return;
    }

    if (await controller.clipboardPaste()) {
      bringIntoView(textEditingValue.selection.extent);
      return;
    }
  }

  /// Select the entire text value.
  @override
  void selectAll(SelectionChangedCause cause) {
    userUpdateTextEditingValue(
      textEditingValue.copyWith(
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: textEditingValue.text.length,
        ),
      ),
      cause,
    );

    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
    }
  }

  /// Returns the [ContextMenuButtonItem]s representing the buttons in this
  /// platform's default selection menu for [QuillRawEditor].
  /// Copied from [EditableTextState].
  List<ContextMenuButtonItem> get contextMenuButtonItems {
    return EditableText.getEditableButtonItems(
      clipboardStatus: (_clipboardStatus != null) ? _clipboardStatus!.value : null,
      onCopy: copyEnabled ? () => copySelection(SelectionChangedCause.toolbar) : null,
      onCut: cutEnabled ? () => cutSelection(SelectionChangedCause.toolbar) : null,
      onPaste: pasteEnabled ? () => pasteText(SelectionChangedCause.toolbar) : null,
      onSelectAll: selectAllEnabled ? () => selectAll(SelectionChangedCause.toolbar) : null,
      onLookUp: lookUpEnabled ? () => lookUpSelection(SelectionChangedCause.toolbar) : null,
      onSearchWeb: searchWebEnabled ? () => searchWebForSelection(SelectionChangedCause.toolbar) : null,
      onShare: shareEnabled ? () => shareSelection(SelectionChangedCause.toolbar) : null,
      onLiveTextInput: liveTextInputEnabled ? () {} : null,
    );
  }

  /// Look up the current selection,
  /// as in the "Look Up" edit menu button on iOS.
  ///
  /// Currently this is only implemented for iOS.
  ///
  /// Throws an error if the selection is empty or collapsed.
  Future<void> lookUpSelection(SelectionChangedCause cause) async {
    final text = textEditingValue.selection.textInside(textEditingValue.text);
    if (text.isEmpty) {
      return;
    }
    await SystemChannels.platform.invokeMethod('LookUp.invoke', text);
  }

  /// Launch a web search on the current selection,
  /// as in the "Search Web" edit menu button on iOS.
  ///
  /// Currently this is only implemented for iOS.
  ///
  /// When 'obscureText' is true or the selection is empty,
  /// this function will not do anything
  Future<void> searchWebForSelection(SelectionChangedCause cause) async {
    final text = textEditingValue.selection.textInside(textEditingValue.text);
    if (text.isNotEmpty) {
      await SystemChannels.platform.invokeMethod('SearchWeb.invoke', text);
    }
  }

  /// Launch the share interface for the current selection,
  /// as in the "Share" edit menu button on iOS.
  ///
  /// Currently this is only implemented for iOS.
  ///
  /// When 'obscureText' is true or the selection is empty,
  /// this function will not do anything
  Future<void> shareSelection(SelectionChangedCause cause) async {
    final text = textEditingValue.selection.textInside(textEditingValue.text);
    if (text.isNotEmpty) {
      await SystemChannels.platform.invokeMethod('Share.invoke', text);
    }
  }

  /// Returns the anchor points for the default context menu.
  ///
  /// Copied from [EditableTextState].
  TextSelectionToolbarAnchors get contextMenuAnchors {
    final glyphHeights = _getGlyphHeights();
    final selection = textEditingValue.selection;
    final points = renderEditor.getEndpointsForSelection(selection);
    return TextSelectionToolbarAnchors.fromSelection(
      renderBox: renderEditor,
      startGlyphHeight: glyphHeights.startGlyphHeight,
      endGlyphHeight: glyphHeights.endGlyphHeight,
      selectionEndpoints: points,
    );
  }

  /// Gets the line heights at the start and end of the selection for the given
  /// [QuillRawEditorState].
  ///
  /// Copied from [EditableTextState].
  QuillEditorGlyphHeights _getGlyphHeights() {
    final selection = textEditingValue.selection;

    // Only calculate handle rects if the text in the previous frame
    // is the same as the text in the current frame. This is done because
    // widget.renderObject contains the renderEditable from the previous frame.
    // If the text changed between the current and previous frames then
    // widget.renderObject.getRectForComposingRange might fail. In cases where
    // the current frame is different from the previous we fall back to
    // renderObject.preferredLineHeight.
    final prevText = renderEditor.document.toPlainText();
    final currText = textEditingValue.text;
    if (prevText != currText || !selection.isValid || selection.isCollapsed) {
      return QuillEditorGlyphHeights(
        renderEditor.preferredLineHeight(selection.base),
        renderEditor.preferredLineHeight(selection.base),
      );
    }

    final startCharacterRect = renderEditor.getLocalRectForCaret(
      selection.base,
    );
    final endCharacterRect = renderEditor.getLocalRectForCaret(
      selection.extent,
    );
    return QuillEditorGlyphHeights(
      startCharacterRect.height,
      endCharacterRect.height,
    );
  }

  void _defaultOnTapOutside(PointerDownEvent event) {
    /// The focus dropping behavior is only present on desktop platforms
    /// and mobile browsers.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        // On mobile platforms, we don't unfocus on touch events unless they're
        // in the web browser, but we do unfocus for all other kinds of events.
        switch (event.kind) {
          case ui.PointerDeviceKind.touch:
            break;
          case ui.PointerDeviceKind.mouse:
          case ui.PointerDeviceKind.stylus:
          case ui.PointerDeviceKind.invertedStylus:
          case ui.PointerDeviceKind.unknown:
            widget.config.focusNode.unfocus();
          case ui.PointerDeviceKind.trackpad:
            throw UnimplementedError(
              'Unexpected pointer down event for trackpad.',
            );
        }
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        widget.config.focusNode.unfocus();
    }
  }

  Widget _scribbleFocusable(Widget child) {
    return ScribbleFocusable(
      editorKey: _editorKey,
      enabled: widget.config.enableScribble && !widget.config.readOnly,
      renderBoxForBounds: () => context.findAncestorStateOfType<QuillEditorState>()?.context.findRenderObject() as RenderBox?,
      onScribbleFocus: (offset) {
        widget.config.focusNode.requestFocus();
        widget.config.onScribbleActivated?.call();
      },
      scribbleAreaInsets: widget.config.scribbleAreaInsets,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // debugCheckHasMediaQuery retourne toujours true en release (no-op).
    // En debug, il lance un assert si MediaQuery est absent.
    // On l'utilise ici pour logger le cas où MediaQuery serait absent.
    if (!debugCheckHasMediaQuery(context)) {
      quillDebugPrint("QuillRawEditorState build — MediaQuery absent du context");
      return const SizedBox.shrink();
    }
    super.build(context);

    var doc = controller.document;
    if (doc.isEmpty() && widget.config.placeholder != null) {
      final raw = widget.config.placeholder?.replaceAll('"', r'\"');
      // get current block attributes applied to the first line even if it
      // is empty
      final blockAttributesWithoutContent = doc.root.children.firstOrNull?.toDelta().first.attributes;
      // check if it has code block attribute to add '//' to give to the users
      // the feeling of this is really a block of code
      final isCodeBlock = blockAttributesWithoutContent?.containsKey('code-block') ?? false;
      // we add the block attributes at the same time as the placeholder to allow the editor to display them without removing
      // the placeholder (this is really awkward when everything is empty)
      final blockAttrInsertion = blockAttributesWithoutContent == null
          ? ''
          : ',{"insert":"\\n","attributes":${jsonEncode(blockAttributesWithoutContent)}}';

      final jsonRaw =
          '[{"attributes":{"placeholder":true},"insert":"${isCodeBlock ? '// ' : ''}$raw${blockAttrInsertion.isEmpty ? r'\n' : ''}"}$blockAttrInsertion]';
      final decode = jsonDecode(jsonRaw);
      if (decode is List<dynamic>) {
        doc = Document.fromJson(decode);
      } else {
        quillDebugPrint("QuillRawEditorState build decode jsonRaw ERROR");
      }
    }

    if (!widget.config.disableClipboard) {
      // Web - esp Safari Mac/iOS has security measures in place that restrict
      // cliboard status checks w/o direct user interaction. Initializing the
      // ClipboardStatusNotifier with a default value of unknown will cause the
      // clipboard status to be checked w/o user interaction which fails. Default
      // to pasteable for web.
      if (kIsWeb) {
        _clipboardStatus = ClipboardStatusNotifier(
          value: ClipboardStatus.pasteable,
        );
      }
    }

    Widget child;
    if (widget.config.scrollable) {
      /// Since [SingleChildScrollView] does not implement
      /// `computeDistanceToActualBaseline` it prevents the editor from
      /// providing its baseline metrics. To address this issue we wrap
      /// the scroll view with [BaselineProxy] which mimics the editor's
      /// baseline.
      // This implies that the first line has no styles applied to it.
      final baselinePadding = EdgeInsets.only(
        top: _styles!.paragraph!.verticalSpacing.top,
      );
      child = BaselineProxy(
        textStyle: _styles!.paragraph!.style,
        padding: baselinePadding,
        child: _scribbleFocusable(
          SingleChildScrollView(
            controller: _scrollController,
            physics: widget.config.scrollPhysics,
            child: CompositedTransformTarget(
              link: _toolbarLayerLink,
              child: MouseRegion(
                cursor: widget.config.readOnly ? widget.config.readOnlyMouseCursor : SystemMouseCursors.text,
                child: QuillRawEditorMultiChildRenderObject(
                  key: _editorKey,
                  offset: _scrollController.hasClients ? _scrollController.position : null,
                  document: doc,
                  selection: controller.selection,
                  hasFocus: _hasFocus,
                  scrollable: widget.config.scrollable,
                  textDirection: _textDirection,
                  startHandleLayerLink: _startHandleLayerLink,
                  endHandleLayerLink: _endHandleLayerLink,
                  onSelectionChanged: _handleSelectionChanged,
                  onSelectionCompleted: _handleSelectionCompleted,
                  scrollBottomInset: widget.config.scrollBottomInset,
                  padding: widget.config.padding,
                  maxContentWidth: widget.config.maxContentWidth,
                  cursorController: _cursorCont,
                  floatingCursorDisabled: widget.config.floatingCursorDisabled,
                  children: _buildChildren(doc, context),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      child = _scribbleFocusable(
        CompositedTransformTarget(
          link: _toolbarLayerLink,
          child: Semantics(
            child: MouseRegion(
              cursor: widget.config.readOnly ? widget.config.readOnlyMouseCursor : SystemMouseCursors.text,
              child: QuillRawEditorMultiChildRenderObject(
                key: _editorKey,
                offset: _scrollController.hasClients ? _scrollController.position : null,
                document: doc,
                selection: controller.selection,
                hasFocus: _hasFocus,
                scrollable: widget.config.scrollable,
                cursorController: _cursorCont,
                textDirection: _textDirection,
                startHandleLayerLink: _startHandleLayerLink,
                endHandleLayerLink: _endHandleLayerLink,
                onSelectionChanged: _handleSelectionChanged,
                onSelectionCompleted: _handleSelectionCompleted,
                scrollBottomInset: widget.config.scrollBottomInset,
                padding: widget.config.padding,
                maxContentWidth: widget.config.maxContentWidth,
                floatingCursorDisabled: widget.config.floatingCursorDisabled,
                children: _buildChildren(doc, context),
              ),
            ),
          ),
        ),
      );
    }
    final constraints = widget.config.expands
        ? const BoxConstraints.expand()
        : BoxConstraints(
            minHeight: widget.config.minHeight ?? 0.0,
            maxHeight: widget.config.maxHeight ?? double.infinity,
          );

    return TextFieldTapRegion(
      enabled: widget.config.onTapOutsideEnabled,
      onTapOutside: (event) {
        final onTapOutside = widget.config.onTapOutside;
        if (onTapOutside != null) {
          onTapOutside.call(event, widget.config.focusNode);
          return;
        }
        _defaultOnTapOutside(event);
      },
      child: QuillStyles(
        data: _styles!,
        child: EditorKeyboardShortcuts(
          actions: _shortcutActionsManager.actions,
          onKeyPressed: widget.config.onKeyPressed,
          characterEvents: widget.config.characterShortcutEvents,
          spaceEvents: widget.config.spaceShortcutEvents,
          constraints: constraints,
          focusNode: widget.config.focusNode,
          controller: controller,
          readOnly: widget.config.readOnly,
          enableAlwaysIndentOnTab: widget.config.enableAlwaysIndentOnTab,
          customShortcuts: widget.config.customShortcuts,
          customActions: widget.config.customActions,
          child: child,
        ),
      ),
    );
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause cause,
  ) {
    final oldSelection = controller.selection;
    controller.updateSelection(selection, ChangeSource.local);

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();

    if (!_keyboardVisible) {
      // This will show the keyboard for all selection changes on the
      // editor, not just changes triggered by user gestures.
      requestKeyboard();
    }

    if (cause == SelectionChangedCause.drag) {
      // When user updates the selection while dragging make sure to
      // bring the updated position (base or extent) into view.
      if (oldSelection.baseOffset != selection.baseOffset) {
        bringIntoView(selection.base);
      } else if (oldSelection.extentOffset != selection.extentOffset) {
        bringIntoView(selection.extent);
      }
    }
  }

  void _handleSelectionCompleted() {
    controller.onSelectionCompleted?.call();
  }

  /// Updates the checkbox positioned at [offset] in document
  /// by changing its attribute according to [value].
  void _handleCheckboxTap(int offset, bool value) {
    final requestKeyboardFocusOnCheckListChanged = widget.config.requestKeyboardFocusOnCheckListChanged;
    if (!(widget.config.checkBoxReadOnly ?? widget.config.readOnly)) {
      _disableScrollControllerAnimateOnce = true;
      final currentSelection = controller.selection.copyWith();
      final attribute = value ? FormatAttribute.checked : FormatAttribute.unchecked;

      _markNeedsBuild();
      controller
        ..ignoreFocusOnTextChange = true
        ..skipRequestKeyboard = !requestKeyboardFocusOnCheckListChanged
        ..formatText(offset, 0, attribute)
        // Checkbox tapping causes controller.selection to go to offset 0
        // Stop toggling those two toolbar buttons
        ..toolbarButtonToggler = {
          FormatAttribute.list.key: attribute,
          FormatAttribute.header.key: FormatAttribute.header,
        };

      // Go back from offset 0 to current selection
      SchedulerBinding.instance.addPostFrameCallback((_) {
        controller
          ..ignoreFocusOnTextChange = false
          ..skipRequestKeyboard = !requestKeyboardFocusOnCheckListChanged
          ..updateSelection(currentSelection, ChangeSource.local);
      });
    }
  }

  List<Widget> _buildChildren(Document doc, BuildContext context) {
    final result = <Widget>[];
    final indentLevelCounts = <int, int>{};
    // this need for several ordered list in document
    // we need to reset indents Map, if list finished
    // List finished when there is node without FormatAttribute.ol in styles
    // So in this case we set clearIndents=true and send it
    // to the next EditableTextBlock
    var prevNodeOl = false;
    var clearIndents = false;

    for (final node in doc.root.children) {
      final attrs = node.style.attributes;

      if (prevNodeOl && attrs[FormatAttribute.list.key] != FormatAttribute.ol || attrs.isEmpty) {
        clearIndents = true;
      }

      prevNodeOl = attrs[FormatAttribute.list.key] == FormatAttribute.ol;
      final nodeTextDirection = getDirectionOfNode(node, _textDirection);
      if (node is Line) {
        final editableTextLine = _getEditableTextLineFromNode(
          node,
          context,
          attrs,
        );
        result.add(
          Directionality(
            textDirection: nodeTextDirection,
            child: editableTextLine,
          ),
        );
      } else if (node is Block) {
        final editableTextBlock = EditableTextBlock(
          block: node,
          controller: controller,
          customLeadingBlockBuilder: widget.config.customLeadingBuilder,
          textDirection: nodeTextDirection,
          scrollBottomInset: widget.config.scrollBottomInset,
          horizontalSpacing: _getHorizontalSpacingForBlock(node, _styles),
          verticalSpacing: _getVerticalSpacingForBlock(node, _styles),
          textSelection: controller.selection,
          color: widget.config.selectionColor,
          styles: _styles,
          enableInteractiveSelection: widget.config.enableInteractiveSelection,
          hasFocus: _hasFocus,
          contentPadding: attrs.containsKey(FormatAttribute.codeBlock.key) ? const EdgeInsets.all(16) : null,
          textSpanBuilder: widget.config.textSpanBuilder,
          linkActionPicker: _linkActionPicker,
          onLaunchUrl: widget.config.onLaunchUrl,
          cursorCont: _cursorCont,
          indentLevelCounts: indentLevelCounts,
          clearIndents: clearIndents,
          onCheckboxTap: _handleCheckboxTap,
          readOnly: widget.config.readOnly,
          checkBoxReadOnly: widget.config.checkBoxReadOnly,
          customRecognizerBuilder: widget.config.customRecognizerBuilder,
          customStyleBuilder: widget.config.customStyleBuilder,
          customLinkPrefixes: widget.config.customLinkPrefixes,
          composingRange: composingRange.value,
        );
        result.add(
          Directionality(
            textDirection: nodeTextDirection,
            child: editableTextBlock,
          ),
        );

        clearIndents = false;
      } else {
        _dirty = false;
        throw StateError('Unreachable.');
      }
    }
    _dirty = false;
    return result;
  }

  EditableTextLine _getEditableTextLineFromNode(
    Line node,
    BuildContext context,
    Map<String, FormatAttribute> attrs,
  ) {
    final textLine = TextLine(
      line: node,
      textDirection: _textDirection,
      textSpanBuilder: widget.config.textSpanBuilder,
      customStyleBuilder: widget.config.customStyleBuilder,
      customRecognizerBuilder: widget.config.customRecognizerBuilder,
      styles: _styles!,
      readOnly: widget.config.readOnly,
      controller: controller,
      linkActionPicker: _linkActionPicker,
      onLaunchUrl: widget.config.onLaunchUrl,
      customLinkPrefixes: widget.config.customLinkPrefixes,
      composingRange: composingRange.value,
    );
    final editableTextLine = EditableTextLine(
      line: node,
      leading: null,
      body: textLine,
      horizontalSpacing: _getHorizontalSpacingForLine(node, _styles),
      verticalSpacing: _getVerticalSpacingForLine(node, _styles),
      textDirection: _textDirection,
      textSelection: controller.selection,
      color: widget.config.selectionColor,
      enableInteractiveSelection: widget.config.enableInteractiveSelection,
      hasFocus: _hasFocus,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      cursorCont: _cursorCont,
      inlineCodeStyle: _styles!.inlineCode!,
      decoration: _getDecoration(node, _styles, attrs),
    );
    return editableTextLine;
  }

  HorizontalSpacing? _getHorizontalSpacingForLine(
    Line line,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = line.style.attributes;

    if (attrs.containsKey(FormatAttribute.header.key)) {
      final formatKey = attrs[FormatAttribute.header.key];
      final headerValue = formatKey?.intValue;
      if (headerValue == null) {
        quillDebugPrint('_getHorizontalSpacingForLine Error formatKey');
        return null;
      }

      switch (headerValue) {
        case 1:
          return defaultStyles!.h1!.horizontalSpacing;
        case 2:
          return defaultStyles!.h2!.horizontalSpacing;
        case 3:
          return defaultStyles!.h3!.horizontalSpacing;
        case 4:
          return defaultStyles!.h4!.horizontalSpacing;
        case 5:
          return defaultStyles!.h5!.horizontalSpacing;
        case 6:
          return defaultStyles!.h6!.horizontalSpacing;
        default:
          quillDebugPrint('_getHorizontalSpacingForLine no switch value');
          return null;
      }
    }

    return defaultStyles!.paragraph!.horizontalSpacing;
  }

  VerticalSpacing? _getVerticalSpacingForLine(
    Line line,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = line.style.attributes;
    if (attrs.containsKey(FormatAttribute.header.key)) {
      final formatKey = attrs[FormatAttribute.header.key];
      final headerValue = formatKey?.intValue;
      if (headerValue == null) {
        quillDebugPrint('_getVerticalSpacingForLine Error formatKey');
        return null;
      }

      switch (headerValue) {
        case 1:
          return defaultStyles!.h1!.verticalSpacing;
        case 2:
          return defaultStyles!.h2!.verticalSpacing;
        case 3:
          return defaultStyles!.h3!.verticalSpacing;
        case 4:
          return defaultStyles!.h4!.verticalSpacing;
        case 5:
          return defaultStyles!.h5!.verticalSpacing;
        case 6:
          return defaultStyles!.h6!.verticalSpacing;
        default:
          quillDebugPrint('_getVerticalSpacingForLine no switch value');
          return null;
      }
    }

    return defaultStyles!.paragraph!.verticalSpacing;
  }

  HorizontalSpacing _getHorizontalSpacingForBlock(
    Block node,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = node.style.attributes;
    if (attrs.containsKey(FormatAttribute.blockQuote.key)) {
      return defaultStyles!.quote!.horizontalSpacing;
    } else if (attrs.containsKey(FormatAttribute.codeBlock.key)) {
      return defaultStyles!.code!.horizontalSpacing;
    } else if (attrs.containsKey(FormatAttribute.indent.key)) {
      return defaultStyles!.indent!.horizontalSpacing;
    } else if (attrs.containsKey(FormatAttribute.list.key)) {
      return defaultStyles!.lists!.horizontalSpacing;
    } else if (attrs.containsKey(FormatAttribute.align.key)) {
      return defaultStyles!.align!.horizontalSpacing;
    }
    return HorizontalSpacing.zero;
  }

  VerticalSpacing _getVerticalSpacingForBlock(
    Block node,
    DefaultStyles? defaultStyles,
  ) {
    final attrs = node.style.attributes;
    if (attrs.containsKey(FormatAttribute.blockQuote.key)) {
      return defaultStyles!.quote!.verticalSpacing;
    } else if (attrs.containsKey(FormatAttribute.codeBlock.key)) {
      return defaultStyles!.code!.verticalSpacing;
    } else if (attrs.containsKey(FormatAttribute.indent.key)) {
      return defaultStyles!.indent!.verticalSpacing;
    } else if (attrs.containsKey(FormatAttribute.list.key)) {
      return defaultStyles!.lists!.verticalSpacing;
    } else if (attrs.containsKey(FormatAttribute.align.key)) {
      return defaultStyles!.align!.verticalSpacing;
    }
    return VerticalSpacing.zero;
  }

  BoxDecoration? _getDecoration(
    Node node,
    DefaultStyles? defaultStyles,
    Map<String, FormatAttribute> attrs,
  ) {
    if (attrs.containsKey(FormatAttribute.header.key)) {
      final level = attrs[FormatAttribute.header.key]!.value;
      switch (level) {
        case 1:
          return defaultStyles!.h1!.decoration;
        case 2:
          return defaultStyles!.h2!.decoration;
        case 3:
          return defaultStyles!.h3!.decoration;
        case 4:
          return defaultStyles!.h4!.decoration;
        case 5:
          return defaultStyles!.h5!.decoration;
        case 6:
          return defaultStyles!.h6!.decoration;
        default:
          throw ArgumentError('Invalid level $level');
      }
    }
    return null;
  }

  void _didChangeTextEditingValueListener() {
    _didChangeTextEditingValue(controller.ignoreFocusOnTextChange);
  }

  @override
  void initState() {
    super.initState();
    _shortcutActionsManager = EditorKeyboardShortcutsActionsManager(
      rawEditorState: this,
      context: context,
    );

    if (_clipboardStatus != null) {
      _clipboardStatus!.addListener(_onChangedClipboardStatus);
    }

    _scrollController = widget.config.scrollController;
    _scrollController.addListener(_updateSelectionOverlayForScroll);

    _cursorCont = CursorCont(
      show: ValueNotifier<bool>(widget.config.showCursor),
      style: widget.config.cursorStyle,
      tickerProvider: this,
    );

    // Floating cursor
    _floatingCursorResetController = AnimationController(vsync: this);
    _floatingCursorResetController.addListener(onFloatingCursorResetTick);

    if (isKeyboardOS) {
      _keyboardVisible = true;
    } else if (!kIsWeb && isFlutterTest) {
      // treat tests like a keyboard OS
      _keyboardVisible = true;
    } else {
      // treat iOS Simulator like a keyboard OS
      unawaited(
        isIOSSimulator().then((isIosSimulator) {
          if (isIosSimulator) {
            _keyboardVisible = true;
          } else {
            _keyboardVisibilityController = KeyboardVisibilityController();
            _keyboardVisible = _keyboardVisibilityController!.isVisible;
            _keyboardVisibilitySubscription = _keyboardVisibilityController?.onChange.listen((visible) {
              _keyboardVisible = visible;
              if (visible) {
                _onChangeTextEditingValue(!_hasFocus);
              }
            });

            HardwareKeyboard.instance.addHandler(_hardwareKeyboardEvent);
          }
        }),
      );
    }

    controller.addListener(_didChangeTextEditingValueListener);

    if (!widget.config.readOnly) {
      // listen to composing range changes
      composingRange.addListener(_onComposingRangeChanged);
      // Focus
      widget.config.focusNode.addListener(_handleFocusChanged);
    }
  }

  // KeyboardVisibilityController only checks for keyboards that
  // adjust the screen size. Also watch for hardware keyboards
  // that don't alter the screen (i.e. Chromebook, Android tablet
  // and any hardware keyboards from an OS not listed in isKeyboardOS())
  bool _hardwareKeyboardEvent(KeyEvent _) {
    if (!_keyboardVisible) {
      // hardware keyboard key pressed. Set visibility to true
      _keyboardVisible = true;
      // update the editor
      _onChangeTextEditingValue(!_hasFocus);
    }

    // remove the key handler - it's no longer needed. If
    // KeyboardVisibilityController clears visibility, it wil
    // also enable it when appropriate.
    HardwareKeyboard.instance.removeHandler(_hardwareKeyboardEvent);

    // we didn't handle the event, just needed to know a key was pressed
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentStyles = QuillStyles.getStyles(context, true);
    final defaultStyles = const DefaultStyles().getInstance(context);
    _styles = (parentStyles != null) ? defaultStyles.merge(parentStyles) : defaultStyles;

    if (widget.config.customStyles != null) {
      _styles = _styles!.merge(widget.config.customStyles!);
    }

    _requestAutoFocusIfShould();
  }

  void _requestAutoFocusIfShould() {
    final focusManager = FocusScope.of(context);
    if (!_didAutoFocus && widget.config.autoFocus) {
      focusManager.autofocus(widget.config.focusNode);
      _didAutoFocus = true;
    }
  }

  @override
  void didUpdateWidget(QuillRawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    _cursorCont.show.value = widget.config.showCursor;
    _cursorCont.style = widget.config.cursorStyle;

    if (controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      controller.addListener(_didChangeTextEditingValue);
      updateRemoteValueIfNeeded();
    }

    if (widget.config.scrollController != _scrollController) {
      _scrollController.removeListener(_updateSelectionOverlayForScroll);
      _scrollController = widget.config.scrollController;
      _scrollController.addListener(_updateSelectionOverlayForScroll);
    }

    if (widget.config.focusNode != oldWidget.config.focusNode) {
      oldWidget.config.focusNode.removeListener(_handleFocusChanged);
      widget.config.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(textEditingValue);
    }

    _selectionOverlay?.handlesVisible = _shouldShowSelectionHandles();
    if (!shouldCreateInputConnection) {
      closeConnectionIfNeeded();
    } else {
      if (oldWidget.config.readOnly && _hasFocus) {
        openConnectionIfNeeded();
      }
    }

    // in case customStyles changed in new widget
    if (widget.config.customStyles != null) {
      _styles = _styles!.merge(widget.config.customStyles!);
    }
  }

  bool _shouldShowSelectionHandles() {
    return widget.config.showSelectionHandles && !controller.selection.isCollapsed;
  }

  @override
  void dispose() {
    closeConnectionIfNeeded();
    unawaited(_keyboardVisibilitySubscription?.cancel());
    HardwareKeyboard.instance.removeHandler(_hardwareKeyboardEvent);
    if (hasConnection) {
      quillDebugPrint(
        'RawEditorState.dispose — still has connection after closeConnectionIfNeeded, forcing close',
      );
      closeConnectionIfNeeded();
    }
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    controller.removeListener(_didChangeTextEditingValueListener);
    if (!widget.config.readOnly) {
      widget.config.focusNode.removeListener(_handleFocusChanged);
      composingRange.removeListener(_onComposingRangeChanged);
    }
    _cursorCont.dispose();
    if (_clipboardStatus != null) {
      _clipboardStatus!
        ..removeListener(_onChangedClipboardStatus)
        ..dispose();
    }
    super.dispose();
  }

  void _updateSelectionOverlayForScroll() {
    _selectionOverlay?.updateForScroll();
  }

  void _onComposingRangeChanged() {
    // During widget teardown (hot-reload / test disposal) the composing
    // notifier can still fire between `deactivate` and the final `dispose`.
    // In that window `mounted` may still be `true` while the element is in a
    // defunct lifecycle state: calling `setState` would throw. Defer to a
    // post-frame callback and re-check `mounted` so we never touch a stale
    // element.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _markNeedsBuild();
    });
  }

  /// Marks the editor as dirty and trigger a rebuild.
  ///
  /// When the editor is dirty methods that depend on the editor
  /// state being in sync with the controller know they may be
  /// operating on stale data.
  void _markNeedsBuild() {
    setState(() {
      _dirty = true;
    });
  }

  void _didChangeTextEditingValue([bool ignoreFocus = false]) {
    if (kIsWeb) {
      _onChangeTextEditingValue(ignoreFocus);
      if (!ignoreFocus) {
        requestKeyboard();
      }
      return;
    }

    if (ignoreFocus || _keyboardVisible) {
      _onChangeTextEditingValue(ignoreFocus);
    } else {
      requestKeyboard();
      // Keep the platform IME's editing state (selection) in sync even when the
      // soft keyboard is not (yet) visible — e.g. Android with a hardware
      // keyboard. Without this, after moving the caret with a tap/mouse the IME
      // keeps its stale cursor position and inserts typed text there.
      // Does nothing if no input connection is open.
      updateRemoteValueIfNeeded();
      if (mounted) {
        // Use controller.value in build()
        // Mark widget as dirty and trigger build and updateChildren
        _markNeedsBuild();
      }
    }

    _shortcutActionsManager.adjacentLineAction.stopCurrentVerticalRunIfSelectionChanges();
  }

  void _onChangeTextEditingValue([bool ignoreCaret = false]) {
    updateRemoteValueIfNeeded();
    if (ignoreCaret) {
      return;
    }
    _showCaretOnScreen();
    _cursorCont.startOrStopCursorTimerIfNeeded(_hasFocus, controller.selection);
    if (hasConnection) {
      // To keep the cursor from blinking while typing, we want to restart the
      // cursor timer every time a new character is typed.
      _cursorCont
        ..stopCursorTimer(resetCharTicks: false)
        ..startCursorTimer();
    }

    // Refresh selection overlay after the build step had a chance to
    // update and register all children of RenderEditor. Otherwise this will
    // fail in situations where a new line of text is entered, which adds
    // a new RenderEditableBox child. If we try to update selection overlay
    // immediately it'll not be able to find the new child since it hasn't been
    // built yet.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateOrDisposeSelectionOverlayIfNeeded();
    });
    if (mounted) {
      // Use controller.value in build()
      // Mark widget as dirty and trigger build and updateChildren
      _markNeedsBuild();
    }
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (!_hasFocus || textEditingValue.selection.isCollapsed) {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      } else {
        _selectionOverlay!.update(textEditingValue);
      }
    } else if (_hasFocus) {
      _selectionOverlay = EditorTextSelectionOverlay(
        value: textEditingValue,
        context: context,
        debugRequiredFor: widget,
        startHandleLayerLink: _startHandleLayerLink,
        endHandleLayerLink: _endHandleLayerLink,
        renderObject: renderEditor,
        selectionCtrls: widget.config.selectionCtrls,
        selectionDelegate: this,
        clipboardStatus: _clipboardStatus,
        contextMenuBuilder: widget.config.contextMenuBuilder == null ? null : (context) => widget.config.contextMenuBuilder!(context, this),
        dragOffsetNotifier: widget.dragOffsetNotifier,
      );
      _selectionOverlay!.handlesVisible = _shouldShowSelectionHandles();
      _selectionOverlay!.showHandles();
    }
  }

  void _handleFocusChanged() {
    quillDebugPrint(" _handleFocusChanged INFO void _hasFocus=$_hasFocus dirty=$dirty");
    if (dirty) {
      quillDebugPrint("yolo !");
      requestKeyboard();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _afterFocusChanged();
      });
      return;
    }
    _afterFocusChanged();
  }

  void _afterFocusChanged() {
    quillDebugPrint("[FOCUS-OPEN] dirty=false, appelle openOrCloseConnection");
    if (!_hasFocus && hasConnection && !widget.config.readOnly) {
      // On Windows desktop, each keystroke can trigger a brief app lifecycle
      // cycle (inactive -> resumed) which causes FocusManager to revoke focus
      // from all non-primary FocusNodes. If the IME connection is still alive
      // we re-acquire focus so the user can keep typing instead of having the
      // connection closed under their fingers.
      quillDebugPrint("[FOCUS-REACQUIRE] focus perdu mais connexion active, re-requestFocus");
      widget.config.focusNode.requestFocus();
      return;
    }
    openOrCloseConnection();
    _cursorCont.startOrStopCursorTimerIfNeeded(_hasFocus, controller.selection);
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      WidgetsBinding.instance.addObserver(this);
      _showCaretOnScreen();
    } else {
      WidgetsBinding.instance.removeObserver(this);
    }
    updateKeepAlive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasFocus && hasConnection && !widget.config.readOnly) {
      quillDebugPrint("[LIFECYCLE-RESUME] re-requestFocus après cycle lifecycle");
      widget.config.focusNode.requestFocus();
    }
  }

  void _onChangedClipboardStatus() {
    if (!mounted) return;
    // Inform the widget that the value of clipboardStatus has changed.
    // Trigger build and updateChildren
    _markNeedsBuild();
  }

  Future<LinkMenuAction> _linkActionPicker(Node linkNode) async {
    final attr = linkNode.style.attributes[FormatAttribute.link.key];
    if (attr == null || attr.stringValue == null) {
      return LinkMenuAction.none;
    }
    return widget.config.linkActionPickerDelegate(
      context,
      attr.stringValue!,
      linkNode,
    );
  }

  bool _showCaretOnScreenScheduled = false;

  // This is a workaround for checkbox tapping issue
  // https://github.com/singerdmx/flutter-quill/issues/619
  // We cannot treat {"list": "checked"} and {"list": "unchecked"} as
  // block of the same style
  // This causes controller.selection to go to offset 0
  bool _disableScrollControllerAnimateOnce = false;

  void _showCaretOnScreen() {
    if (!widget.config.showCursor || _showCaretOnScreenScheduled) {
      return;
    }

    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.config.scrollable || _scrollController.hasClients) {
        _showCaretOnScreenScheduled = false;

        if (!mounted) {
          return;
        }

        final viewport = RenderAbstractViewport.of(renderEditor);
        final editorOffset = renderEditor.localToGlobal(
          Offset.zero,
          ancestor: viewport,
        );
        final offsetInViewport = _scrollController.offset + editorOffset.dy;

        final offset = renderEditor.getOffsetToRevealCursor(
          _scrollController.position.viewportDimension,
          _scrollController.offset,
          offsetInViewport,
        );

        if (offset != null) {
          if (_disableScrollControllerAnimateOnce) {
            _disableScrollControllerAnimateOnce = false;
            return;
          }
          unawaited(
            _scrollController.animateTo(
              math.min(offset, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 100),
              curve: Curves.fastOutSlowIn,
            ),
          );
        }
      }
    });
  }

  /// The renderer for this widget's editor descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures.
  @override
  RenderEditor get renderEditor => _editorKey.currentContext!.findRenderObject()! as RenderEditor;

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  @override
  void requestKeyboard() {
    quillDebugPrint("[REQKB] _hasFocus=$_hasFocus keyboardVisible=$_keyboardVisible skip=${controller.skipRequestKeyboard}");
    if (controller.skipRequestKeyboard) {
      quillDebugPrint("[REQKB] skipRequestKeyboard=true, return");
      controller.skipRequestKeyboard = false;
      return;
    }
    if (_hasFocus) {
      final keyboardAlreadyShown = _keyboardVisible;
      quillDebugPrint("[REQKB-OPEN] appelle openConnectionIfNeeded, keyboardAlreadyShown=$keyboardAlreadyShown");
      openConnectionIfNeeded();
      if (!keyboardAlreadyShown) {
        /// delay 500 milliseconds for waiting keyboard show up
        Future.delayed(const Duration(milliseconds: 500), _showCaretOnScreen);
      } else {
        _showCaretOnScreen();
      }
    } else {
      quillDebugPrint("[REQKB-NOFOCUS] pas de focus, requestFocus");
      widget.config.focusNode.requestFocus();
    }
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
  /// is already shown, or when no text selection currently exists.
  @override
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb) {
      return false;
    }

    // selectionOverlay is aggressively released when selection is collapsed
    // to remove unnecessary handles. Since a toolbar is requested here,
    // attempt to create the selectionOverlay if it's not already created.
    if (_selectionOverlay == null) {
      _updateOrDisposeSelectionOverlayIfNeeded();
    }

    if (_selectionOverlay == null || _selectionOverlay!.toolbar != null) {
      return false;
    }

    _selectionOverlay!.update(textEditingValue);
    _selectionOverlay!.showToolbar();
    return true;
  }

  @override
  bool get wantKeepAlive => widget.config.focusNode.hasFocus;

  @override
  AnimationController get floatingCursorResetController => _floatingCursorResetController;

  late AnimationController _floatingCursorResetController;

  @override
  void insertTextPlaceholder(Size size) {
    // this is needed for Scribble (Stylus input) in Apple platforms
    // and this package does not implement this feature
  }

  @override
  void removeTextPlaceholder() {
    // this is needed for Scribble (Stylus input) in Apple platforms
    // and this package does not implement this feature
  }

  @override
  void didChangeInputControl(
    TextInputControl? oldControl,
    TextInputControl? newControl,
  ) {
    // implement didChangeInputControl
  }

  /// macOS-specific method that should not be called on other platforms.
  /// This method interacts with the `NSStandardKeyBindingResponding` protocol
  /// from Cocoa, which is available only on macOS systems.
  @override
  void performSelector(String selectorName) {
    if (!isMacOSApp) {
      quillDebugPrint(
        'RawEditorState.performSelector — called on non-macOS platform, ignoring',
      );
      return;
    }
    final intent = intentForMacOSSelector(selectorName);
    if (intent == null) {
      return;
    }
    final primaryContext = primaryFocus?.context;
    if (primaryContext == null) {
      return;
    }
    Actions.invoke(primaryContext, intent);
  }

  @override
  bool get liveTextInputEnabled => false;

  @override
  bool get lookUpEnabled => false;

  @override
  bool get searchWebEnabled => false;

  @override
  bool get shareEnabled => false;
}
