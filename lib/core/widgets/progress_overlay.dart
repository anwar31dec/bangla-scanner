import 'package:flutter/material.dart';

/// Full-screen blocking progress indicator with a message, used while
/// saving or importing. [progress] null = indeterminate.
class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({super.key, required this.message, this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.scrim.withValues(alpha: 0.45),
        child: Center(
          child: Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progress == null)
                      const CircularProgressIndicator()
                    else
                      LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 20),
                    Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
