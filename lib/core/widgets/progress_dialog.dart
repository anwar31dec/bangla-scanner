import 'package:flutter/material.dart';

import 'progress_overlay.dart';

/// Reports [done] steps of [total].
typedef ProgressReporter = void Function(int done, int total);

/// Runs [task] behind a blocking progress dialog and returns its result.
/// [task] gets a reporter to move the bar; [progressText] turns the counts
/// into the line shown under the bar (the plain [message] when null or
/// before the first report). Errors propagate to the caller after the
/// dialog is closed.
Future<T> runWithProgressDialog<T>(
  BuildContext context, {
  required String message,
  required Future<T> Function(ProgressReporter report) task,
  String Function(int done, int total)? progressText,
}) async {
  final state = ValueNotifier<(int, int)?>(null);
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;
  // Not awaited: the dialog stays until the task finishes.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: ValueListenableBuilder<(int, int)?>(
        valueListenable: state,
        builder: (context, progress, _) {
          final (done, total) = progress ?? (0, 0);
          final text = progress == null || total == 0 ? message : (progressText?.call(done, total) ?? message);
          return _ProgressDialogBody(message: text, progress: total == 0 ? null : done / total);
        },
      ),
    ),
  ).whenComplete(() => open = false);
  try {
    return await task((done, total) => state.value = (done, total));
  } finally {
    if (open && navigator.mounted) navigator.pop();
    state.dispose();
  }
}

class _ProgressDialogBody extends StatelessWidget {
  const _ProgressDialogBody({required this.message, this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    // Same card as the full-screen overlay, inside the dialog barrier.
    return Center(
      child: ProgressCard(message: message, progress: progress),
    );
  }
}
