import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Files other apps hand to us through Android share / "Open with" intents
/// and iOS "Open in" / "Copy to". The platform side copies them into the
/// app's temp folder first (content URIs and iOS inbox files are not
/// stable), then reports their paths here.
class ReceivedFilesChannel {
  ReceivedFilesChannel({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_onCall);
  }

  static const channelName = 'com.codeinherit.banglascanner/received';

  final MethodChannel _channel;
  final _controller = StreamController<List<String>>.broadcast();

  /// Files that arrive while the app is running.
  Stream<List<String>> get files => _controller.stream;

  /// Files the app was launched with (empty when it was opened normally).
  /// Also drains anything that arrived before Dart was listening.
  Future<List<String>> takeInitialFiles() async {
    try {
      final paths = await _channel.invokeListMethod<String>('takeInitialFiles');
      return paths ?? const [];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'filesReceived') {
      final paths = (call.arguments as List?)?.whereType<String>().toList() ?? const <String>[];
      if (paths.isNotEmpty) _controller.add(paths);
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _controller.close();
  }
}

final receivedFilesChannelProvider = Provider<ReceivedFilesChannel>((ref) {
  final channel = ReceivedFilesChannel();
  ref.onDispose(channel.dispose);
  return channel;
});
