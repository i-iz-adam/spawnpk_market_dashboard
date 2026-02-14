import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevateOnHover = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevateOnHover;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final padding = widget.padding ?? const EdgeInsets.all(AppSpacing.xl);
    return MouseRegion(
      onEnter: widget.elevateOnHover ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.elevateOnHover ? (_) => setState(() => _hovered = false) : null,
      cursor: widget.elevateOnHover ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Card(
          elevation: widget.elevateOnHover && _hovered ? AppElevation.lg : AppElevation.sm,
          child: Padding(
            padding: padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
