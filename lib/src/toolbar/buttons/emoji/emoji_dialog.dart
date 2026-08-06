import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

/// Emoji picker widget used inside the toolbar dropdown menu.
///
/// Ported from axomind's `EmojiForm`, with theme colors sourced from [Theme]
/// instead of a project-specific color palette. The [Config.height] is left
/// null so the picker adapts to the parent [SizedBox] provided by the
/// [MenuAnchor].
class QuillToolbarEmojiDialog extends StatelessWidget {
  const QuillToolbarEmojiDialog({
    required this.onEmojiSelected,
    super.key,
  });

  final void Function(Category? category, Emoji emoji) onEmojiSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = theme.canvasColor;
    final surface = colorScheme.surface;
    final primary = colorScheme.primary;
    final onSurface = colorScheme.onSurface.withValues(alpha: 0.6);

    return EmojiPicker(
      onEmojiSelected: onEmojiSelected,
      config: Config(
        emojiTextStyle: const TextStyle(fontSize: 24),
        emojiViewConfig: EmojiViewConfig(
          columns: 8,
          backgroundColor: background,
          verticalSpacing: 4,
          horizontalSpacing: 4,
          gridPadding: const EdgeInsets.all(8),
          emojiSizeMax: 28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
        ),
        categoryViewConfig: CategoryViewConfig(
          backgroundColor: surface,
          backspaceColor: primary,
          iconColorSelected: primary,
          indicatorColor: primary,
          iconColor: onSurface,
        ),
        bottomActionBarConfig: BottomActionBarConfig(
          backgroundColor: surface,
          buttonIconColor: onSurface,
          buttonColor: surface,
          showBackspaceButton: false,
        ),
        skinToneConfig: SkinToneConfig(
          indicatorColor: primary,
          dialogBackgroundColor: surface,
        ),
        searchViewConfig: SearchViewConfig(
          backgroundColor: surface,
          buttonIconColor: primary,
        ),
      ),
    );
  }
}
