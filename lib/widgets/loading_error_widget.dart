import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows loading spinner or error message.
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
    return asyncValue.when(
      data: (data) => dataBuilder(data),
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              loadingMessage,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
      error: (e, st) => errorBuilder != null
          ? errorBuilder!(e, st)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${e.toString()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
