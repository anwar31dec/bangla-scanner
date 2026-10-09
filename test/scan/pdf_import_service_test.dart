import 'dart:io';

import 'package:banglascanner/core/utils/app_exception.dart';
import 'package:banglascanner/features/scan/data/pdf_import_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PdfImportService.channelName);
  late Directory root;
  final calls = <MethodCall>[];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('bs_pdf');
    calls.clear();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });

  void fakePlatform({required int pageCount, String? openError}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final args = (call.arguments as Map).cast<String, Object?>();
      switch (call.method) {
        case 'open':
          if (openError != null) throw PlatformException(code: openError);
          return {'id': 7, 'pageCount': pageCount};
        case 'render':
          final path = args['path'] as String;
          File(path).writeAsBytesSync([0xFF, 0xD8, args['index'] as int]);
          return path;
        case 'close':
          return null;
      }
      return null;
    });
  }

  test('renders every page in order and closes the document', () async {
    fakePlatform(pageCount: 3);
    final progress = <(int, int)>[];
    final pages = await PdfImportService(
      channel: channel,
    ).renderPages('/in/doc.pdf', Directory(p.join(root.path, 'out')), onProgress: (d, t) => progress.add((d, t)));

    expect(pages.map(p.basename), ['page_001.jpg', 'page_002.jpg', 'page_003.jpg']);
    expect(pages.every((f) => File(f).existsSync()), isTrue);
    expect(progress, [(0, 3), (1, 3), (2, 3), (3, 3)]);
    expect(calls.map((c) => c.method), ['open', 'render', 'render', 'render', 'close']);
    expect((calls[1].arguments as Map)['maxEdge'], PdfImportService.renderMaxEdge);
    expect((calls.last.arguments as Map)['id'], 7);
  });

  test('stops at the page limit', () async {
    fakePlatform(pageCount: PdfImportService.maxPages + 40);
    final pages = await PdfImportService(
      channel: channel,
    ).renderPages('/in/big.pdf', Directory(p.join(root.path, 'out')));
    expect(pages.length, PdfImportService.maxPages);
    expect(await PdfImportService(channel: channel).pageCount('/in/big.pdf'), PdfImportService.maxPages + 40);
  });

  test('a password protected PDF is reported as locked', () async {
    fakePlatform(pageCount: 0, openError: 'pdf_locked');
    expect(
      () => PdfImportService(channel: channel).renderPages('/in/locked.pdf', Directory(p.join(root.path, 'out'))),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.pdfLocked)),
    );
  });

  test('an unreadable PDF is reported as damaged', () async {
    fakePlatform(pageCount: 0, openError: 'pdf_invalid');
    expect(
      () => PdfImportService(channel: channel).pageCount('/in/bad.pdf'),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.corruptFile)),
    );
  });

  test('a PDF with no pages is reported as damaged and closed', () async {
    fakePlatform(pageCount: 0);
    await expectLater(
      () => PdfImportService(channel: channel).renderPages('/in/empty.pdf', Directory(p.join(root.path, 'out'))),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.corruptFile)),
    );
    expect(calls.last.method, 'close');
  });
}
