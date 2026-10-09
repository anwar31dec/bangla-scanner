import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../utils/app_exception.dart';

/// Shows a yes/no confirmation. Returns true when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Asks for a text value (used for rename). Returns null when cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  required String label,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(title: title, initialValue: initialValue, label: label),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({required this.title, required this.initialValue, required this.label});

  final String title;
  final String initialValue;
  final String label;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initialValue.length);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = context.l10n.fileNameEmpty);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(labelText: widget.label, errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

/// Asks for a password (PDF protection). Returns null when cancelled.
Future<String?> showPasswordDialog(BuildContext context, {required String title, String? body, int minLength = 1}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(title: title, body: body, minLength: minLength),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title, this.body, required this.minLength});

  final String title;
  final String? body;
  final int minLength;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    if (value.length < widget.minLength) {
      setState(() => _error = context.l10n.passwordTooShort);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.body != null) ...[Text(widget.body!), const SizedBox(height: 12)],
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: !_show,
            decoration: InputDecoration(
              labelText: l10n.pdfPassword,
              errorText: _error,
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}

/// Shows a short message at the bottom of the screen.
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows a localized message for any error.
void showError(BuildContext context, Object error) {
  showSnack(context, AppException.from(error).message(context.l10n));
}
