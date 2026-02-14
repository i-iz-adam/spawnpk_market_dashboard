import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';


class LoadingErrorWidget<T> extends StatelessWidget {
  const LoadingErrorWidget({
    super.key,
    required this.asyncValue,
    required this.dataBuilder,
    this.loadingMessage = 'Loading...',
    this.errorBuilder,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(T data) dataBuilder;
  final String loadingMessage;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return asyncValue.when(
      data: (data) => dataBuilder(data),
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              loadingMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      error: (e, st) => errorBuilder != null
          ? errorBuilder!(e, st)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error: ${e.toString()}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
