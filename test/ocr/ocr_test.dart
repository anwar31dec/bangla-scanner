import 'dart:io';
import 'dart:typed_data';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/core/storage/storage_providers.dart';
import 'package:banglascanner/core/utils/app_exception.dart';
import 'package:banglascanner/features/ocr/application/ocr_controller.dart';
import 'package:banglascanner/features/ocr/data/ocr_engine.dart';
import 'package:banglascanner/features/ocr/data/ocr_preprocessor.dart';
import 'package:banglascanner/features/ocr/data/ocr_result.dart';
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
  Future<RecognizedPage> recognize(String imagePath, OcrLanguage language) async {
    calls.add((imagePath, language));
    if (fail) throw Exception('native failure');
    expect(File(imagePath).existsSync(), isTrue, reason: 'pre-processed image must exist');
    final size = img.decodePng(File(imagePath).readAsBytesSync())!;
    return RecognizedPage(
      text: 'আমার সোনার বাংলা   \r\n\n\n\npage ${calls.length}',
      words: [
        OcrWord('আমার', left: 0, top: 0, right: size.width / 2, bottom: size.height / 10),
        // Out of the image: dropped.
        const OcrWord('junk', left: -5, top: 0, right: 0, bottom: 10),
      ],
    );
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

  group('HocrParser', () {
    const hocr = '''
<?xml version="1.0" encoding="UTF-8"?>
<html><body>
<div class='ocr_page' id='page_1' title='image "x.png"; bbox 0 0 1000 500; ppageno 0'>
 <div class='ocr_carea' id='block_1_1' title="bbox 10 10 900 400">
  <p class='ocr_par' id='par_1_1' lang='ben' title="bbox 10 10 900 200">
   <span class='ocr_line' id='line_1_1' title="bbox 10 10 900 60; baseline 0 -5; x_size 40">
    <span class='ocrx_word' id='word_1_1' title='bbox 10 10 200 60; x_wconf 93'>আমার</span>
    <span class='ocrx_word' id='word_1_2' title='bbox 220 10 400 60; x_wconf 91'><strong>সোনার</strong></span>
    <span class='ocrx_word' id='word_1_3' title='bbox 420 12 600 58; x_wconf 90'>A&amp;B</span>
   </span>
   <span class='ocr_line' id='line_1_2' title="bbox 10 80 900 130">
    <span class='ocrx_word' id='word_1_4' title='bbox 10 80 100 130; x_wconf 80'>বাংলা</span>
    <span class='ocrx_word' id='word_1_5' title='bbox 120 80 130 130; x_wconf 10'> </span>
   </span>
  </p>
  <p class='ocr_par' id='par_1_2' lang='eng' title="bbox 10 300 900 400">
   <span class='ocr_line' id='line_1_3' title="bbox 10 300 900 350">
    <span class='ocrx_word' id='word_1_6' title='bbox 10 300 100 350; x_wconf 95'>Total</span>
   </span>
  </p>
 </div>
</div>
</body></html>
''';

    test('reads words, boxes, lines and paragraphs', () {
      final page = HocrParser.parse(hocr);
      expect(page.text.trim(), 'আমার সোনার A&B\nবাংলা\n\nTotal');
      expect(page.words.map((w) => w.text), ['আমার', 'সোনার', 'A&B', 'বাংলা', 'Total']);
      expect(page.words[1], const OcrWord('সোনার', left: 220, top: 10, right: 400, bottom: 60));
      final normalized = page.normalized(1000, 500);
      expect(normalized.words.first, const OcrWord('আমার', left: 0.01, top: 0.02, right: 0.2, bottom: 0.12));
      expect(normalized.words.length, 5);
    });

    test('word boxes survive a JSON round trip', () {
      final page = HocrParser.parse(hocr).normalized(1000, 500);
      final back = PageText.wordsFromJson(page.wordsJson);
      expect(back, page.words);
      expect(PageText.wordsFromJson('not json'), isEmpty);
      expect(PageText.wordsFromJson('[[1,2,3,4,5],["ok",0,0,0.5,0.5]]'), [const OcrWord('ok', left: 0, top: 0, right: 0.5, bottom: 0.5)]);
    });

    test('tolerates empty or odd input', () {
      expect(HocrParser.parse('').words, isEmpty);
      expect(HocrParser.parse('<p>no hocr here</p>').text, '');
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
      expect(state.language, OcrLanguage.both);
      expect(state.pages.length, 2);
      expect(state.pages.first.text, 'আমার সোনার বাংলা\n\npage 1');
      // Word boxes come back as fractions of the page, clamped to it.
      expect(state.pages.first.words, [const OcrWord('আমার', left: 0, top: 0, right: 0.5, bottom: 0.1)]);
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
