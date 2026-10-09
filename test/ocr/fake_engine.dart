import 'dart:io';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/features/ocr/data/ocr_engine.dart';
import 'package:banglascanner/features/ocr/data/ocr_result.dart';
import 'package:image/image.dart' as img;

/// Returns [textFor] each page, with one word box in the top-left tenth of
/// the image.
class FakeOcrEngine implements OcrEngine {
  FakeOcrEngine({this.textFor = _defaultText});

  final String Function(int call) textFor;
  final calls = <(String, OcrLanguage)>[];

  static String _defaultText(int call) => 'Invoice ${call + 1}\nমোট টাকা ৫০০';

  @override
  Future<RecognizedPage> recognize(String imagePath, OcrLanguage language) async {
    final call = calls.length;
    calls.add((imagePath, language));
    final size = img.decodePng(await File(imagePath).readAsBytes())!;
    final text = textFor(call);
    final first = text.split(RegExp(r'\s+')).first;
    return RecognizedPage(
      text: text,
      words: [OcrWord(first, left: 0, top: 0, right: size.width / 10, bottom: size.height / 20)],
    );
  }
}
