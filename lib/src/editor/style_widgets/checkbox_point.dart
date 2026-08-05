import 'package:flutter/material.dart';

class QuillCheckboxPoint extends StatefulWidget {
  const QuillCheckboxPoint({
    required this.size,
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final double size;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  QuillCheckboxPointState createState() => QuillCheckboxPointState();
}

class QuillCheckboxPointState extends State<QuillCheckboxPoint> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = widget.value
        ? (widget.enabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5))
        : theme.colorScheme.surface;
    final borderColor = widget.value
        ? (widget.enabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0))
        : (widget.enabled ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : theme.colorScheme.onSurface.withValues(alpha: 0.3));
    final child = Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(end: widget.size / 2),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Material(
          color: fillColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor),
            borderRadius: BorderRadius.circular(2),
          ),
          child: InkWell(
            onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
            child: widget.value
                ? Icon(
                    Icons.check,
                    size: widget.size,
                    color: theme.colorScheme.onPrimary,
                  )
                : null,
          ),
        ),
      ),
    );
    return child;
  }
}
