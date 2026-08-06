import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_quill/src/common/extensions/view_id_ext.dart';
import 'package:flutter_quill/src/delta/delta_diff.dart';
import 'package:flutter_quill/src/document/document.dart';
import 'package:flutter_quill/src/document/nodes/leaf.dart';
import 'package:flutter_quill/src/editor/editor.dart';
import 'package:flutter_quill/src/editor/raw_editor/raw_editor.dart';

mixin RawEditorStateTextInputClientMixin on EditorState implements TextInputClient {
  TextInputConnection? _textInputConnection;
  TextEditingValue? __lastKnownRemoteTextEditingValue;
  bool _isHandlingUpdateEditingValue = false;

  set _lastKnownRemoteTextEditingValue(TextEditingValue? value) {
    __lastKnownRemoteTextEditingValue = value;
    if (composingRange.value != value?.composing) {
      composingRange.value = value?.composing ?? TextRange.empty;
    }
  }

  TextEditingValue? get _lastKnownRemoteTextEditingValue => __lastKnownRemoteTextEditingValue;

  /// The range of text that is currently being composed.
  final ValueNotifier<TextRange> composingRange = ValueNotifier<TextRange>(
    TextRange.empty,
  );

  /// Whether to create an input connection with the platform for text editing
  /// or not.
  ///
  /// Read-only input fields do not need a connection with the platform since
  /// there's no need for text editing capabilities (e.g. virtual keyboard).
  ///
  /// On the web, we always need a connection because we want some browser
  /// functionalities to continue to work on read-only input fields like:
  ///
  /// - Relevant context menu.
  /// - cmd/ctrl+c shortcut to copy.
  /// - cmd/ctrl+a to select all.
  /// - Changing the selection using a physical keyboard.
  bool get shouldCreateInputConnection => kIsWeb || !widget.config.readOnly;

  /// Returns `true` if there is open input connection.
  bool get hasConnection => _textInputConnection != null && _textInputConnection!.attached;

  /// Opens or closes input connection based on the current state of
  /// [focusNode] and [value].
  void openOrCloseConnection() {
    if (widget.config.focusNode.hasFocus && widget.config.focusNode.consumeKeyboardToken()) {
      openConnectionIfNeeded();
    } else if (!widget.config.focusNode.hasFocus) {
      closeConnectionIfNeeded();
    }
  }

  /// This setting is only honored on iOS devices.
  @visibleForTesting
  @internal
  Brightness createKeyboardAppearance() =>
      widget.config.keyboardAppearance ?? CupertinoTheme.maybeBrightnessOf(context) ?? Theme.of(context).brightness;

  void openConnectionIfNeeded() {
    if (!shouldCreateInputConnection) {
      return;
    }

    if (!hasConnection) {
      _lastKnownRemoteTextEditingValue = textEditingValue;
      debugPrint(
        "[OPEN-1] textEditingValue.text='${_lastKnownRemoteTextEditingValue?.text}' len=${_lastKnownRemoteTextEditingValue?.text.length} sel=${_lastKnownRemoteTextEditingValue?.selection}",
      );
      _textInputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          readOnly: widget.config.readOnly,
          inputAction: widget.config.textInputAction,
          enableSuggestions: !widget.config.readOnly,
          keyboardAppearance: createKeyboardAppearance(),
          textCapitalization: widget.config.textCapitalization,
          allowedMimeTypes: widget.config.contentInsertionConfiguration == null
              ? const <String>[]
              : widget.config.contentInsertionConfiguration!.allowedMimeTypes,
          viewId: context.getViewId(),
        ),
      );

      _updateSizeAndTransform();
      _updateComposingRectIfNeeded();
      _updateCaretRectIfNeeded();

      final last = _lastKnownRemoteTextEditingValue;
      if (last != null && last.selection.end > last.text.length) {
        _lastKnownRemoteTextEditingValue = last.copyWith(
          selection: last.selection.copyWith(
            extentOffset: last.text.length,
          ),
        );
      }
      final remote = _lastKnownRemoteTextEditingValue;
      if (remote != null) {
        debugPrint("[OPEN-2] setEditingState appelé, remote.text='${remote.text}' len=${remote.text.length} sel=${remote.selection}");
        _textInputConnection!.setEditingState(remote);
      }
    }
    _textInputConnection!.show();
  }

  void _updateComposingRectIfNeeded() {
    final composingRange = _lastKnownRemoteTextEditingValue?.composing ?? textEditingValue.composing;
    if (hasConnection) {
      if (!mounted) {
        debugPrint(
          'RawEditorStateTextInputClientMixin — not mounted but has connection, skipping',
        );
        return;
      }
      if (composingRange.isValid) {
        final offset = composingRange.start;
        final composingRect = renderEditor.getLocalRectForCaret(
          TextPosition(offset: offset),
        );
        _textInputConnection!.setComposingRect(composingRect);
      }
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _updateComposingRectIfNeeded(),
      );
    }
  }

  void _updateCaretRectIfNeeded() {
    if (hasConnection) {
      if (!dirty && renderEditor.selection.isValid && renderEditor.selection.isCollapsed) {
        final currentTextPosition = TextPosition(
          offset: renderEditor.selection.baseOffset,
        );
        final caretRect = renderEditor.getLocalRectForCaret(
          currentTextPosition,
        );
        _textInputConnection!.setCaretRect(caretRect);
      }
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _updateCaretRectIfNeeded(),
      );
    }
  }

  /// Closes input connection if it's currently open. Otherwise does nothing.
  void closeConnectionIfNeeded() {
    if (!hasConnection) {
      return;
    }
    _textInputConnection!.close();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
  }

  /// Updates remote value based on current state of [document] and
  /// [selection].
  ///
  /// This method may not actually send an update to native side if it thinks
  /// remote value is up to date or identical.
  void updateRemoteValueIfNeeded() {
    if (!hasConnection) {
      return;
    }
    if (_isHandlingUpdateEditingValue) {
      return;
    }

    final value = textEditingValue;
    final last = _lastKnownRemoteTextEditingValue;

    if (last == null) {
      return;
    }

    final composingRange = last.composing;
    final actualValue = value.copyWith(
      composing: composingRange.end > value.text.length ? null : composingRange,
    );

    if (actualValue == last) {
      return;
    }

    debugPrint("[REMOTE-PUSH] setEditingState actualValue.text='${actualValue.text}' len=${actualValue.text.length} sel=${actualValue.selection}");
    _lastKnownRemoteTextEditingValue = actualValue;
    _textInputConnection!.setEditingState(
      actualValue.copyWith(composing: TextRange.empty),
    );
  }

  // Start TextInputClient implementation
  @override
  TextEditingValue? get currentTextEditingValue => _lastKnownRemoteTextEditingValue;

  // autofill is not needed
  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    debugPrint("[IME-IN] value.text='${value.text}' len=${value.text.length} sel=${value.selection} composing=${value.composing}");
    if (!shouldCreateInputConnection) {
      debugPrint("[IME-IN] shouldCreateInputConnection=false, return");
      return;
    }

    final last = _lastKnownRemoteTextEditingValue;
    final lastStr = last == null ? "NULL" : "text='${last.text}' len=${last.text.length} sel=${last.selection}";
    debugPrint("[IME-LAST] last=$lastStr");
    if (last == value) {
      debugPrint("[IME-IN] last == value, return");
      return;
    }

    if (last != null && last.text == value.text && last.selection == value.selection) {
      debugPrint("[IME-IN] composing-only, return");
      _lastKnownRemoteTextEditingValue = value;
      return;
    }

    if (last != null && last.text == value.text) {
      debugPrint("[IME-IN] selection-only, return");
      _lastKnownRemoteTextEditingValue = value;
      widget.controller.updateSelection(value.selection, ChangeSource.local);
      return;
    }

    final effectiveLastKnownValue = last ?? textEditingValue;
    _lastKnownRemoteTextEditingValue = value;
    final oldText = effectiveLastKnownValue.text;
    final text = value.text;
    final cursorPosition = value.selection.extentOffset;
    final diff = getDiff(oldText, text, cursorPosition);
    debugPrint(
      "[IME-DIFF] oldText='$oldText'(len=${oldText.length}) -> newText='$text'(len=${text.length}) cursor=$cursorPosition => start=${diff.start} del='${diff.deleted}'(${diff.deleted.length}) ins='${diff.inserted}'(${diff.inserted.length})",
    );

    _isHandlingUpdateEditingValue = true;
    try {
      if (diff.deleted.isEmpty && diff.inserted.isEmpty) {
        debugPrint("[IME-IN] diff vide, updateSelection only");
        widget.controller.updateSelection(value.selection, ChangeSource.local);
      } else {
        // When the IME (notably the Android soft keyboard) pastes content that
        // came from an internal copy, the inserted text may contain the embed
        // object replacement character (\uFFFC). The plain `replaceText` path
        // would insert a bare placeholder without the embed data/styles. Route
        // such inserts through `replaceTextWithEmbeds` so the cached
        // `pasteStyleAndEmbed` / `pastePlainText` are reapplied, matching the
        // behavior of the toolbar/context-menu paste path.
        final insertedHasEmbed = diff.inserted.codeUnits.contains(
          Embed.kObjectReplacementInt,
        );
        if (insertedHasEmbed) {
          debugPrint(
            "[IME-REPLACE-EMBED] replaceTextWithEmbeds(index=${diff.start}, len=${diff.deleted.length}, data='${diff.inserted}', sel=${value.selection})",
          );
          widget.controller.replaceTextWithEmbeds(
            diff.start,
            diff.deleted.length,
            diff.inserted,
            value.selection,
          );
        } else {
          debugPrint("[IME-REPLACE] replaceText(index=${diff.start}, len=${diff.deleted.length}, data='${diff.inserted}', sel=${value.selection})");
          widget.controller.replaceText(
            diff.start,
            diff.deleted.length,
            diff.inserted,
            value.selection,
          );
        }
      }
    } finally {
      _isHandlingUpdateEditingValue = false;
    }
  }

  @override
  void performAction(TextInputAction action) {
    widget.config.onPerformAction?.call(action);
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // no-op
  }

  // The time it takes for the floating cursor to snap to the text aligned
  // cursor position after the user has finished placing it.
  static const Duration _floatingCursorResetTime = Duration(milliseconds: 125);

  // The original position of the caret on FloatingCursorDragState.start.
  Rect? _startCaretRect;

  // The most recent text position as determined by the location of the floating
  // cursor.
  TextPosition? _lastTextPosition;

  // The offset of the floating cursor as determined from the start call.
  Offset? _pointOffsetOrigin;

  // The most recent position of the floating cursor.
  Offset? _lastBoundedOffset;

  // Because the center of the cursor is preferredLineHeight / 2 below the touch
  // origin, but the touch origin is used to determine which line the cursor is
  // on, we need this offset to correctly render and move the cursor.
  Offset _floatingCursorOffset(TextPosition textPosition) => Offset(0, renderEditor.preferredLineHeight(textPosition) / 2);

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    switch (point.state) {
      case FloatingCursorDragState.Start:
        if (floatingCursorResetController.isAnimating) {
          floatingCursorResetController.stop();
          onFloatingCursorResetTick();
        }
        // We want to send in points that are centered around a (0,0) origin, so
        // we cache the position.
        _pointOffsetOrigin = point.offset;

        final currentTextPosition = TextPosition(
          offset: renderEditor.selection.baseOffset,
        );
        _startCaretRect = renderEditor.getLocalRectForCaret(
          currentTextPosition,
        );

        _lastBoundedOffset = _startCaretRect!.center - _floatingCursorOffset(currentTextPosition);
        _lastTextPosition = currentTextPosition;
        renderEditor.setFloatingCursor(
          point.state,
          _lastBoundedOffset!,
          _lastTextPosition!,
        );
      case FloatingCursorDragState.Update:
        if (_lastTextPosition == null) {
          debugPrint(
            'RawEditorStateTextInputClientMixin — last text position not set, skipping update',
          );
          return;
        }
        final floatingCursorOffset = _floatingCursorOffset(_lastTextPosition!);
        final centeredPoint = point.offset! - _pointOffsetOrigin!;
        final rawCursorOffset = _startCaretRect!.center + centeredPoint - floatingCursorOffset;

        final preferredLineHeight = renderEditor.preferredLineHeight(
          _lastTextPosition!,
        );
        _lastBoundedOffset = renderEditor.calculateBoundedFloatingCursorOffset(
          rawCursorOffset,
          preferredLineHeight,
        );
        _lastTextPosition = renderEditor.getPositionForOffset(
          renderEditor.localToGlobal(
            _lastBoundedOffset! + floatingCursorOffset,
          ),
        );
        renderEditor.setFloatingCursor(
          point.state,
          _lastBoundedOffset!,
          _lastTextPosition!,
        );
        final newSelection = TextSelection.collapsed(
          offset: _lastTextPosition!.offset,
          affinity: _lastTextPosition!.affinity,
        );
        // Setting selection as floating cursor moves will have scroll view
        // bring background cursor into view
        renderEditor.onSelectionChanged(
          newSelection,
          SelectionChangedCause.forcePress,
        );
      case FloatingCursorDragState.End:
        // We skip animation if no update has happened.
        if (_lastTextPosition != null && _lastBoundedOffset != null) {
          floatingCursorResetController.value = 0.0;
          unawaited(
            floatingCursorResetController.animateTo(
              1,
              duration: _floatingCursorResetTime,
              curve: Curves.decelerate,
            ),
          );
        }
    }
  }

  /// Specifies the floating cursor dimensions and position based
  /// the animation controller value.
  /// The floating cursor is resized
  /// (see [RenderAbstractEditor.setFloatingCursor])
  /// and repositioned (linear interpolation between position of floating cursor
  /// and current position of background cursor)
  void onFloatingCursorResetTick() {
    final finalPosition = renderEditor.getLocalRectForCaret(_lastTextPosition!).centerLeft - _floatingCursorOffset(_lastTextPosition!);
    if (floatingCursorResetController.isCompleted) {
      renderEditor.setFloatingCursor(
        FloatingCursorDragState.End,
        finalPosition,
        _lastTextPosition!,
      );
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final lerpValue = floatingCursorResetController.value;
      final lerpX = lerpDouble(
        _lastBoundedOffset!.dx,
        finalPosition.dx,
        lerpValue,
      )!;
      final lerpY = lerpDouble(
        _lastBoundedOffset!.dy,
        finalPosition.dy,
        lerpValue,
      )!;

      renderEditor.setFloatingCursor(
        FloatingCursorDragState.Update,
        Offset(lerpX, lerpY),
        _lastTextPosition!,
        resetLerpValue: lerpValue,
      );
    }
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // this is called VERY OFTEN when editing a document, no longer throw
    // an exception
  }

  @override
  void connectionClosed() {
    if (!hasConnection) {
      return;
    }
    _textInputConnection!.connectionClosedReceived();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
  }

  @override
  bool onFocusReceived() => false;

  void _updateSizeAndTransform() {
    if (hasConnection) {
      // Asking for renderEditor.size here can cause errors if layout hasn't
      // occurred yet. So we schedule a post frame callback instead.
      final size = renderEditor.size;
      final transform = renderEditor.getTransformTo(null);
      _textInputConnection?.setEditableSizeAndTransform(size, transform);
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _updateSizeAndTransform(),
      );
    }
  }
}
