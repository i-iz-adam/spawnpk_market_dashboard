import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


class AppSummaryCard extends StatefulWidget {
  const AppSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.animateOnHover = true,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool animateOnHover;

  @override
  State<AppSummaryCard> createState() => _AppSummaryCardState();
}

class _AppSummaryCardState extends State<AppSummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: widget.animateOnHover ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.animateOnHover ? (_) => setState(() => _hovered = false) : null,
      child: Card(
        elevation: widget.animateOnHover && _hovered ? AppElevation.lg : AppElevation.sm,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl - 2),
          child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: _hovered && widget.animateOnHover ? 0.25 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    widget.icon,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg - 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
