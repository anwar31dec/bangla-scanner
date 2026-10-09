import 'package:banglascanner/features/intents/data/received_files_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ReceivedFilesChannel.channelName);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns the launch files once and streams later ones', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'takeInitialFiles') return ['/tmp/received/1/a.jpg', '/tmp/received/1/b.pdf'];
      return null;
    });
    final received = ReceivedFilesChannel(channel: channel);
    expect(await received.takeInitialFiles(), ['/tmp/received/1/a.jpg', '/tmp/received/1/b.pdf']);

    final later = <List<String>>[];
    received.files.listen(later.add);
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('filesReceived', ['/tmp/received/2/c.png'])),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('filesReceived', <String>[])),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
    expect(later, [
      ['/tmp/received/2/c.png'],
    ]);
    received.dispose();
  });

  test('a platform without the channel yields no files', () async {
    final received = ReceivedFilesChannel(channel: channel);
    expect(await received.takeInitialFiles(), isEmpty);
    received.dispose();
  });
}
