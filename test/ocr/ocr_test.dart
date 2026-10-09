import 'dart:io';
import 'dart:typed_data';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/core/storage/storage_providers.dart';
import 'package:banglascanner/core/utils/app_exception.dart';
import 'package:banglascanner/features/ocr/application/ocr_controller.dart';
import 'package:banglascanner/features/ocr/data/ocr_engine.dart';
import 'package:banglascanner/features/ocr/data/ocr_preprocessor.dart';
import 'package:banglascanner/features/ocr/data/tessdata_installer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../helpers.dart';

class _FakeEngine implements OcrEngine {
  final calls = <(String, OcrLanguage)>[];
  bool fail = false;

  @override
  Future<String> recognize(String imagePath, OcrLanguage language) async {
    calls.add((imagePath, language));
    if (fail) throw Exception('native failure');
    expect(File(imagePath).existsSync(), isTrue, reason: 'pre-processed image must exist');
    return 'আমার সোনার বাংলা   \r\n\n\n\npage ${calls.length}';
  }
}

void main() {
  group('OcrPreprocessor', () {
    test('upscales small images, outputs grayscale PNG', () {
      final out = OcrPreprocessor.process(fakeDocumentJpeg(width: 300, height: 400));
      final decoded = img.decodePng(out)!;
      expect(decoded.height, OcrPreprocessor.minEdge);
      final px = decoded.getPixel(150, 150);
      expect(px.r, px.g);
      expect(px.g, px.b);
    });

    test('downscales huge images', () {
      final big = img.encodeJpg(img.Image(width: 4000, height: 3000));
      expect(img.decodePng(OcrPreprocessor.process(big))!.width, OcrPreprocessor.maxEdge);
    });
  });

  group('TessdataInstaller', () {
    test('decompresses bundled models once', () async {
      final dir = await Directory.systemTemp.createTemp('tess');
      addTearDown(() => dir.delete(recursive: true));
      var loads = 0;
      Future<ByteData> loader(String key) async {
        loads++;
        final bytes = await File(key).readAsBytes(); // assets/tessdata/*.gz in the repo
        return ByteData.sublistView(bytes);
      }

      final installer = TessdataInstaller(loader, dir);
      await installer.ensure('ben+eng');
      await installer.ensure('ben');
      expect(loads, 2);
      final ben = File(p.join(dir.path, 'ben.traineddata'));
      expect(ben.lengthSync(), greaterThan(800000));
      expect(File(p.join(dir.path, 'ben.traineddata.part')).existsSync(), isFalse);
    });
  });

  group('OcrController', () {
    late Directory root;
    late ProviderContainer container;
    late _FakeEngine engine;
    late List<String> pages;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('bs_ocr');
      final paths = AppPaths(Directory(p.join(root.path, 'docs')), Directory(p.join(root.path, 'tmp')));
      engine = _FakeEngine();
      container = ProviderContainer(overrides: [
        appPathsProvider.overrideWith((ref) async => paths),
        ocrEngineProvider.overrideWith((ref) async => engine),
      ]);
      pages = [
        for (var i = 0; i < 2; i++)
          (File(p.join(root.path, 'p$i.jpg'))..writeAsBytesSync(fakeDocumentJpeg(width: 200, height: 260))).path,
      ];
    });

    tearDown(() async {
      container.dispose();
      await root.delete(recursive: true);
    });

    test('processes every page, reports progress and cleans text', () async {
      final sub = container.listen(ocrControllerProvider, (_, _) {}, fireImmediately: true);
      final stages = <OcrStage>[];
      container.listen(ocrControllerProvider, (_, next) => stages.add(next.stage));

      await container.read(ocrControllerProvider.notifier).run(pages, OcrLanguage.both);
      final state = sub.read();

      expect(state.stage, OcrStage.done);
      expect(engine.calls.map((c) => c.$2), [OcrLanguage.both, OcrLanguage.both]);
      expect(stages, containsAllInOrder([OcrStage.preparing, OcrStage.preprocessing, OcrStage.recognizing, OcrStage.done]));
      expect(state.text, 'আমার সোনার বাংলা\n\npage 1\n\nআমার সোনার বাংলা\n\npage 2');
    });

    test('engine failures become an OCR error', () async {
      final sub = container.listen(ocrControllerProvider, (_, _) {});
      engine.fail = true;
      await container.read(ocrControllerProvider.notifier).run(pages, OcrLanguage.bangla);
      expect(sub.read().stage, OcrStage.failed);
      expect(sub.read().error?.kind, AppErrorKind.ocrFailed);
    });

    test('corrupt images are reported as corrupt', () async {
      final sub = container.listen(ocrControllerProvider, (_, _) {});
      File(pages.first).writeAsBytesSync([1, 2, 3]);
      await container.read(ocrControllerProvider.notifier).run(pages, OcrLanguage.english);
      expect(sub.read().error?.kind, AppErrorKind.corruptFile);
    });
  });
}
