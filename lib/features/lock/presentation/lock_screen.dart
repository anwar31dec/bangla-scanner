import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/application/settings_controller.dart';
import '../application/lock_controller.dart';

/// Covers the app while it is locked: PIN pad, and fingerprint / face when
/// the user turned that on.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  /// PIN length accepted by the pad and the setup dialog.
  static const minPinLength = 4;
  static const maxPinLength = 8;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _wrong = false;
  int _failures = 0;

  /// Seconds left of the cool-down after too many wrong PINs.
  int _coolDown = 0;
  Timer? _coolDownTimer;
  bool _promptedBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptBiometrics());
  }

  @override
  void dispose() {
    _coolDownTimer?.cancel();
    super.dispose();
  }

  bool get _biometricsOn => ref.read(settingsProvider).biometricUnlock;

  Future<void> _maybePromptBiometrics() async {
    if (_promptedBiometrics || !_biometricsOn || !mounted) return;
    final available = await ref.read(biometricsAvailableProvider.future);
    if (!available || !mounted) return;
    _promptedBiometrics = true;
    await _biometrics();
  }

  Future<void> _biometrics() async {
    final reason = context.l10n.biometricReason;
    await ref.read(lockControllerProvider.notifier).unlockWithBiometrics(reason);
  }

  void _type(String digit) {
    if (_coolDown > 0 || _pin.length >= LockScreen.maxPinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += digit;
      _wrong = false;
    });
    if (_pin.length == LockScreen.maxPinLength) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    if (_pin.length < LockScreen.minPinLength || _coolDown > 0) return;
    final ok = ref.read(lockControllerProvider.notifier).unlockWithPin(_pin);
    if (ok) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _pin = '';
      _wrong = true;
      _failures++;
    });
    // Five wrong tries: wait 30 seconds, doubling each time after that.
    if (_failures >= 5) _startCoolDown(30 * (1 << (_failures - 5).clamp(0, 4)));
  }

  void _startCoolDown(int seconds) {
    _coolDownTimer?.cancel();
    setState(() => _coolDown = seconds);
    _coolDownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _coolDown--);
      if (_coolDown <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final biometrics = _biometricsOn && (ref.watch(biometricsAvailableProvider).value ?? false);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(l10n.lockedTitle, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    _coolDown > 0 ? '${l10n.wrongPin} · $_coolDown s' : (_wrong ? l10n.wrongPin : l10n.enterPin),
                    style: theme.textTheme.bodyMedium?.copyWith(color: _wrong || _coolDown > 0 ? scheme.error : null),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _PinDots(length: _pin.length, error: _wrong),
                  const SizedBox(height: 28),
                  _PinPad(
                    enabled: _coolDown <= 0,
                    onDigit: _type,
                    onBackspace: _backspace,
                    onSubmit: _pin.length >= LockScreen.minPinLength ? _submit : null,
                  ),
                  if (biometrics) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _biometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l10n.unlockWithBiometrics),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length, required this.error});

  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = length < LockScreen.minPinLength ? LockScreen.minPinLength : length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < length ? (error ? scheme.error : scheme.primary) : Colors.transparent,
              border: Border.all(color: error ? scheme.error : scheme.primary, width: 2),
            ),
          ),
      ],
    );
  }
}

/// 3 × 4 numeric keypad: digits, backspace and a confirm key.
class _PinPad extends StatelessWidget {
  const _PinPad({required this.enabled, required this.onDigit, required this.onBackspace, required this.onSubmit});

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget key(Widget child, VoidCallback? onTap, {String? label}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Semantics(
              button: true,
              label: label,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: enabled ? onTap : null,
                  child: SizedBox(height: 64, child: Center(child: child)),
                ),
              ),
            ),
          ),
        );
    Widget digit(String d) => key(Text(d, style: Theme.of(context).textTheme.headlineSmall), () => onDigit(d), label: d);

    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final d in row) digit(d)]),
        Row(
          children: [
            key(const Icon(Icons.backspace_outlined), onBackspace, label: l10n.delete),
            digit('0'),
            key(const Icon(Icons.check), onSubmit, label: l10n.ok),
          ],
        ),
      ],
    );
  }
}

/// Asks for a PIN in a dialog (setting up or changing the lock). Returns
/// the digits, or null when cancelled.
Future<String?> showPinDialog(BuildContext context, {required String title, String? hint}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PinDialog(title: title, hint: hint),
  );
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _show = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length < LockScreen.minPinLength) {
      setState(() => _error = context.l10n.pinTooShort);
      return;
    }
    Navigator.pop(context, pin);
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
          if (widget.hint != null) ...[Text(widget.hint!), const SizedBox(height: 12)],
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: !_show,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(LockScreen.maxPinLength)],
            decoration: InputDecoration(
              labelText: 'PIN',
              errorText: _error,
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
